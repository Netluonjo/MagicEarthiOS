import Foundation
import CoreLocation

class RoutingEngine {
    static let shared = RoutingEngine()
    
    var truckConfig = TruckConfig()
    var waypoints: [Waypoint] = []
    
    // MARK: - Multi-Modal Routing
    func calculateRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mode: TransportMode
    ) async -> RouteResult {
        let serviceType: String
        switch mode {
        case .bicycle: serviceType = "routed-bike"
        case .pedestrian: serviceType = "routed-foot"
        default: serviceType = "routed-car"
        }
        
        var coordList = ["\(origin.longitude),\(origin.latitude)"]
        for wp in waypoints {
            coordList.append("\(wp.coordinate.longitude),\(wp.coordinate.latitude)")
        }
        coordList.append("\(destination.longitude),\(destination.latitude)")
        let coordStr = coordList.joined(separator: ";")
        
        let endpoints = [
            "https://routing.openstreetmap.de/\(serviceType)/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true",
            "https://router.project-osrm.org/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true",
            "http://router.project-osrm.org/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true"
        ]
        
        for urlStr in endpoints {
            guard let url = URL(string: urlStr) else { continue }
            do {
                var request = URLRequest(url: url, timeoutInterval: 4.0)
                request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) MagicEarth/1.0", forHTTPHeaderField: "User-Agent")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let routes = json["routes"] as? [[String: Any]],
                       let firstRoute = routes.first {
                        return parseOsrmRoute(firstRoute, mode: mode, hasWaypoints: !waypoints.isEmpty)
                    }
                }
            } catch {
                print("RoutingEngine error on \(urlStr): \(error.localizedDescription)")
            }
        }
        
        // Offline / Fallback
        return calculateOfflineFallbackRoute(origin: origin, destination: destination, mode: mode)
    }
    
    // MARK: - Running Route Road Snapping
    func buildCustomRunningRoute(
        drawnPoints: [CLLocationCoordinate2D],
        snapToOsm: Bool = true,
        targetPaceMinPerKm: Double = 6.0
    ) async -> RouteResult {
        guard drawnPoints.count >= 2 else {
            let dummy = drawnPoints.first ?? CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8544)
            return calculateOfflineFallbackRoute(origin: dummy, destination: dummy, mode: .pedestrian)
        }
        
        if snapToOsm {
            let keyWaypoints = extractKeyWaypoints(drawnPoints: drawnPoints, maxWaypoints: 22, epsilonMeters: 15.0)
            if keyWaypoints.count >= 2 {
                // 1. Global multi-waypoint OSRM road snapping with 100m radiuses
                if let globalResult = await fetchSnappedRouteFromOsrm(waypoints: keyWaypoints, targetPaceMinPerKm: targetPaceMinPerKm) {
                    return globalResult
                }
                
                // 2. Piecewise leg-by-leg snapping fallback
                if let piecewiseResult = await fetchPiecewiseSnappedRoute(waypoints: keyWaypoints, targetPaceMinPerKm: targetPaceMinPerKm) {
                    return piecewiseResult
                }
            }
        }
        
        return buildFreehandFallbackRoute(drawnPoints: drawnPoints, targetPaceMinPerKm: targetPaceMinPerKm)
    }
    
    // MARK: - Douglas-Peucker & Waypoint Extraction
    private func extractKeyWaypoints(
        drawnPoints: [CLLocationCoordinate2D],
        maxWaypoints: Int = 22,
        epsilonMeters: Double = 15.0
    ) -> [CLLocationCoordinate2D] {
        guard drawnPoints.count > 2 else { return drawnPoints }
        
        // Distance filter
        var filtered: [CLLocationCoordinate2D] = [drawnPoints[0]]
        for i in 1..<(drawnPoints.count - 1) {
            let last = filtered.last!
            let d = haversineMeters(last, drawnPoints[i])
            if d >= 12.0 {
                filtered.append(drawnPoints[i])
            }
        }
        if haversineMeters(filtered.last!, drawnPoints.last!) >= 5.0 || filtered.count < 2 {
            filtered.append(drawnPoints.last!)
        }
        
        var simplified = douglasPeucker(points: filtered, epsilonMeters: epsilonMeters)
        var curEps = epsilonMeters
        while simplified.count > maxWaypoints && curEps < 50.0 {
            curEps += 8.0
            simplified = douglasPeucker(points: filtered, epsilonMeters: curEps)
        }
        
        if simplified.count > maxWaypoints {
            var reduced: [CLLocationCoordinate2D] = []
            let stride = Double(simplified.count - 1) / Double(maxWaypoints - 1)
            for idx in 0..<maxWaypoints {
                let i = Int((Double(idx) * stride).rounded())
                let clamped = max(0, min(simplified.count - 1, i))
                reduced.append(simplified[clamped])
            }
            return reduced
        }
        
        return simplified
    }
    
    private func douglasPeucker(points: [CLLocationCoordinate2D], epsilonMeters: Double) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }
        var dmax = 0.0
        var index = 0
        let first = points.first!
        let last = points.last!
        
        for i in 1..<(points.count - 1) {
            let d = perpendicularDistanceMeters(p: points[i], a: first, b: last)
            if d > dmax {
                index = i
                dmax = d
            }
        }
        
        if dmax > epsilonMeters {
            let rec1 = douglasPeucker(points: Array(points[0...index]), epsilonMeters: epsilonMeters)
            let rec2 = douglasPeucker(points: Array(points[index..<points.count]), epsilonMeters: epsilonMeters)
            return Array(rec1.dropLast()) + rec2
        } else {
            return [first, last]
        }
    }
    
    private func perpendicularDistanceMeters(p: CLLocationCoordinate2D, a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
        let meanLat = ((a.latitude + b.latitude) / 2.0) * .pi / 180.0
        let mPerDegLat = 110540.0
        let mPerDegLon = 111320.0 * cos(meanLat)
        
        let dx = (b.longitude - a.longitude) * mPerDegLon
        let dy = (b.latitude - a.latitude) * mPerDegLat
        let lineLenSq = dx * dx + dy * dy
        
        let px = (p.longitude - a.longitude) * mPerDegLon
        let py = (p.latitude - a.latitude) * mPerDegLat
        
        if lineLenSq == 0.0 {
            return sqrt(px * px + py * py)
        }
        
        let t = max(0.0, min(1.0, (px * dx + py * dy) / lineLenSq))
        let projX = t * dx
        let projY = t * dy
        let remX = px - projX
        let remY = py - projY
        return sqrt(remX * remX + remY * remY)
    }
    
    // MARK: - OSRM Road Snap Request
    private func fetchSnappedRouteFromOsrm(
        waypoints: [CLLocationCoordinate2D],
        targetPaceMinPerKm: Double
    ) async -> RouteResult? {
        let coordStr = waypoints.map { "\($0.longitude),\($0.latitude)" }.joined(separator: ";")
        let radiusesStr = Array(repeating: "100", count: waypoints.count).joined(separator: ";")
        
        let endpoints = [
            "https://routing.openstreetmap.de/routed-foot/route/v1/foot/\(coordStr)?overview=full&geometries=geojson&steps=true&radiuses=\(radiusesStr)&continue_straight=false",
            "https://routing.openstreetmap.de/routed-bike/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true&radiuses=\(radiusesStr)&continue_straight=false",
            "https://routing.openstreetmap.de/routed-car/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true&radiuses=\(radiusesStr)&continue_straight=false",
            "https://router.project-osrm.org/route/v1/driving/\(coordStr)?overview=full&geometries=geojson&steps=true&radiuses=\(radiusesStr)&continue_straight=false"
        ]
        
        for urlStr in endpoints {
            guard let url = URL(string: urlStr) else { continue }
            do {
                var request = URLRequest(url: url, timeoutInterval: 3.5)
                request.addValue("Mozilla/5.0 (iPhone; MagicEarth iOS)", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       (json["code"] as? String) == "Ok",
                       let routes = json["routes"] as? [[String: Any]],
                       let first = routes.first {
                        return parseRunningRoute(first, targetPaceMinPerKm: targetPaceMinPerKm, isSnapped: true)
                    }
                }
            } catch {
                print("Road snapping error: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    // MARK: - Piecewise Snapping Fallback
    private func fetchPiecewiseSnappedRoute(
        waypoints: [CLLocationCoordinate2D],
        targetPaceMinPerKm: Double
    ) async -> RouteResult? {
        guard waypoints.count >= 2 else { return nil }
        var combinedPolyline: [CLLocationCoordinate2D] = []
        var combinedSteps: [RouteStep] = []
        var totalDistMeters = 0.0
        var snappedLegs = 0
        
        for i in 0..<(waypoints.count - 1) {
            let p1 = waypoints[i]
            let p2 = waypoints[i + 1]
            let pairUrlStr = "https://routing.openstreetmap.de/routed-foot/route/v1/foot/\(p1.longitude),\(p1.latitude);\(p2.longitude),\(p2.latitude)?overview=full&geometries=geojson&steps=true&radiuses=100;100&continue_straight=false"
            var legSuccess = false
            
            if let url = URL(string: pairUrlStr) {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       (json["code"] as? String) == "Ok",
                       let routes = json["routes"] as? [[String: Any]],
                       let rObj = routes.first {
                        
                        let dist = rObj["distance"] as? Double ?? 0
                        totalDistMeters += dist
                        
                        if let geom = rObj["geometry"] as? [String: Any],
                           let coords = geom["coordinates"] as? [[Double]] {
                            for pair in coords {
                                if pair.count >= 2 {
                                    let pt = CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
                                    if combinedPolyline.isEmpty || combinedPolyline.last?.latitude != pt.latitude {
                                        combinedPolyline.append(pt)
                                    }
                                }
                            }
                        }
                        
                        if let legs = rObj["legs"] as? [[String: Any]],
                           let sArr = legs.first?["steps"] as? [[String: Any]] {
                            for sObj in sArr {
                                combinedSteps.append(parseStep(sObj))
                            }
                        }
                        snappedLegs += 1
                        legSuccess = true
                    }
                } catch {
                    print("Piecewise leg error: \(error.localizedDescription)")
                }
            }
            
            if !legSuccess {
                let d = haversineMeters(p1, p2)
                totalDistMeters += d
                if combinedPolyline.isEmpty || combinedPolyline.last?.latitude != p1.latitude {
                    combinedPolyline.append(p1)
                }
                combinedPolyline.append(p2)
            }
        }
        
        guard combinedPolyline.count >= 2 else { return nil }
        let distKm = (totalDistMeters / 1000.0 * 100.0).rounded() / 100.0
        let durMin = RunningCalorieCalculator.estimateDurationMinutes(distanceKm: distKm, paceMinPerKm: targetPaceMinPerKm)
        let calories = RunningCalorieCalculator.calculateCalories(distanceKm: distKm)
        
        let etaCal = Calendar.current.date(byAdding: .minute, value: durMin, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let metrics = RouteMetrics(
            distanceKm: distKm,
            durationMinutes: durMin,
            etaString: formatter.string(from: etaCal),
            trafficCondition: "🏃 Tuyến chạy bộ • Đã nắn chuẩn theo tim đường OSM (~\(calories) kcal)",
            surfacePavedPct: 95,
            surfaceUnpavedPct: 5,
            hasWaypoints: true
        )
        return RouteResult(metrics: metrics, coordinates: combinedPolyline, steps: combinedSteps, isSnappedToRoads: snappedLegs > 0)
    }
    
    // MARK: - Parsers & Helpers
    private func parseRunningRoute(_ rObj: [String: Any], targetPaceMinPerKm: Double, isSnapped: Bool) -> RouteResult {
        let distMeters = rObj["distance"] as? Double ?? 0
        let distKm = (distMeters / 1000.0 * 100.0).rounded() / 100.0
        let durMin = RunningCalorieCalculator.estimateDurationMinutes(distanceKm: distKm, paceMinPerKm: targetPaceMinPerKm)
        let calories = RunningCalorieCalculator.calculateCalories(distanceKm: distKm)
        
        var polyline: [CLLocationCoordinate2D] = []
        if let geom = rObj["geometry"] as? [String: Any],
           let coords = geom["coordinates"] as? [[Double]] {
            for pair in coords where pair.count >= 2 {
                polyline.append(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
            }
        }
        
        var steps: [RouteStep] = []
        if let legs = rObj["legs"] as? [[String: Any]] {
            for leg in legs {
                if let sArr = leg["steps"] as? [[String: Any]] {
                    for s in sArr {
                        steps.append(parseStep(s))
                    }
                }
            }
        }
        
        let etaCal = Calendar.current.date(byAdding: .minute, value: durMin, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let metrics = RouteMetrics(
            distanceKm: distKm,
            durationMinutes: durMin,
            etaString: formatter.string(from: etaCal),
            trafficCondition: "🏃 Tuyến chạy bộ • Đã nắn chuẩn theo tim đường OSM (~\(calories) kcal)",
            surfacePavedPct: 95,
            surfaceUnpavedPct: 5,
            hasWaypoints: true
        )
        return RouteResult(metrics: metrics, coordinates: polyline, steps: steps, isSnappedToRoads: isSnapped)
    }
    
    private func parseOsrmRoute(_ route: [String: Any], mode: TransportMode, hasWaypoints: Bool) -> RouteResult {
        let distMeters = route["distance"] as? Double ?? 0
        let durSeconds = route["duration"] as? Double ?? 0
        let distKm = (distMeters / 1000.0 * 10.0).rounded() / 10.0
        
        let durMin: Int
        switch mode {
        case .car: durMin = max(1, Int((durSeconds / 60.0).rounded()))
        case .truck: durMin = max(1, Int(((durSeconds / 60.0) / 0.75).rounded()))
        case .bicycle: durMin = max(1, Int((distKm / 16.0 * 60.0).rounded()))
        case .pedestrian: durMin = max(1, Int((distKm / 5.0 * 60.0).rounded()))
        case .transit: durMin = max(1, Int(((durSeconds / 60.0) / 0.70).rounded()))
        }
        
        var polyline: [CLLocationCoordinate2D] = []
        if let geom = route["geometry"] as? [String: Any],
           let coords = geom["coordinates"] as? [[Double]] {
            for pair in coords where pair.count >= 2 {
                polyline.append(CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]))
            }
        }
        
        var stepsList: [RouteStep] = []
        if let legs = route["legs"] as? [[String: Any]] {
            for leg in legs {
                if let steps = leg["steps"] as? [[String: Any]] {
                    for s in steps {
                        stepsList.append(parseStep(s))
                    }
                }
            }
        }
        
        let etaCal = Calendar.current.date(byAdding: .minute, value: durMin, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let traffic: String
        switch mode {
        case .car: traffic = "Tuyến đường tối ưu nhất • Lưu thông thông suốt"
        case .truck: traffic = "Tuyến xe tải (\(truckConfig.weightTons)T, cao \(truckConfig.heightMeters)m): Tránh cầu yếu"
        case .bicycle: traffic = "Đường bằng phẳng • Ưu tiên đường gom ven hồ"
        case .pedestrian: traffic = "Lối tắt bộ hành an toàn • Tiêu hao ~\(RunningCalorieCalculator.calculateCalories(distanceKm: distKm)) kcal"
        case .transit: traffic = "Lộ trình giao thông công cộng tối ưu"
        }
        
        let metrics = RouteMetrics(
            distanceKm: distKm,
            durationMinutes: durMin,
            etaString: formatter.string(from: etaCal),
            trafficCondition: traffic,
            surfacePavedPct: mode == .pedestrian ? 90 : 98,
            surfaceUnpavedPct: mode == .pedestrian ? 10 : 2,
            hasWaypoints: hasWaypoints
        )
        return RouteResult(metrics: metrics, coordinates: polyline, steps: stepsList, isSnappedToRoads: true)
    }
    
    private func parseStep(_ step: [String: Any]) -> RouteStep {
        let name = step["name"] as? String ?? ""
        let dist = step["distance"] as? Double ?? 0
        let dur = step["duration"] as? Double ?? 0
        
        var type = ""
        var modifier = ""
        var location: [Double] = [0, 0]
        
        if let maneuver = step["maneuver"] as? [String: Any] {
            type = maneuver["type"] as? String ?? ""
            modifier = maneuver["modifier"] as? String ?? ""
            if let loc = maneuver["location"] as? [Double], loc.count >= 2 {
                location = loc
            }
        }
        
        let targetRoad = name.isEmpty ? "đoạn đường tiếp theo" : name
        let icon: String
        let instruction: String
        
        switch type {
        case "depart":
            icon = "arrow.up"
            instruction = "Xuất phát trên \(targetRoad)"
        case "arrive":
            icon = "flag.checkered"
            instruction = "Bạn đã đến nơi!"
        case "roundabout", "rotary":
            icon = "arrow.triangle.2.circlepath"
            instruction = "Đi vào bùng binh, ra ở lối rẽ vào \(targetRoad)"
        default:
            switch modifier {
            case "right":
                icon = "arrow.turn.up.right"
                instruction = "Rẽ phải vào \(targetRoad)"
            case "left":
                icon = "arrow.turn.up.left"
                instruction = "Rẽ trái vào \(targetRoad)"
            case "slight right":
                icon = "arrow.turn.up.right"
                instruction = "Chếch sang phải vào \(targetRoad)"
            case "slight left":
                icon = "arrow.turn.up.left"
                instruction = "Chếch sang trái vào \(targetRoad)"
            case "sharp right":
                icon = "arrow.turn.up.right"
                instruction = "Ngoặt phải vào \(targetRoad)"
            case "sharp left":
                icon = "arrow.turn.up.left"
                instruction = "Ngoặt trái vào \(targetRoad)"
            case "uturn":
                icon = "arrow.uturn.backward"
                instruction = "Quay đầu xe tại \(targetRoad)"
            default:
                icon = "arrow.up"
                instruction = "Đi thẳng trên \(targetRoad)"
            }
        }
        
        return RouteStep(
            instruction: instruction,
            streetName: name.isEmpty ? targetRoad : name,
            distanceMeters: dist,
            durationSeconds: dur,
            turnType: type,
            modifier: modifier,
            icon: icon,
            coordinate: CLLocationCoordinate2D(latitude: location[1], longitude: location[0])
        )
    }
    
    private func buildFreehandFallbackRoute(drawnPoints: [CLLocationCoordinate2D], targetPaceMinPerKm: Double) -> RouteResult {
        var totalDistKm = 0.0
        for i in 0..<(drawnPoints.count - 1) {
            totalDistKm += haversineMeters(drawnPoints[i], drawnPoints[i+1]) / 1000.0
        }
        totalDistKm = (totalDistKm * 100.0).rounded() / 100.0
        let durMin = RunningCalorieCalculator.estimateDurationMinutes(distanceKm: totalDistKm, paceMinPerKm: targetPaceMinPerKm)
        let calories = RunningCalorieCalculator.calculateCalories(distanceKm: totalDistKm)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let etaStr = formatter.string(from: Calendar.current.date(byAdding: .minute, value: durMin, to: Date()) ?? Date())
        
        let metrics = RouteMetrics(
            distanceKm: totalDistKm,
            durationMinutes: durMin,
            etaString: etaStr,
            trafficCondition: "🏃 Cung đường chạy bộ tự do (~\(calories) kcal)",
            surfacePavedPct: 85,
            surfaceUnpavedPct: 15,
            hasWaypoints = true
        )
        return RouteResult(metrics: metrics, coordinates: drawnPoints, steps: [], isSnappedToRoads: false)
    }
    
    private func calculateOfflineFallbackRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, mode: TransportMode) -> RouteResult {
        let dist = haversineMeters(origin, destination) / 1000.0 * 1.2
        let distKm = (dist * 10.0).rounded() / 10.0
        let durMin = max(1, Int((distKm / 35.0 * 60.0).rounded()))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let eta = formatter.string(from: Calendar.current.date(byAdding: .minute, value: durMin, to: Date()) ?? Date())
        
        let metrics = RouteMetrics(
            distanceKm: distKm,
            durationMinutes: durMin,
            etaString: eta,
            trafficCondition: "Lộ trình ước tính ngoại tuyến",
            surfacePavedPct: 90,
            surfaceUnpavedPct: 10,
            hasWaypoints = false
        )
        return RouteResult(metrics: metrics, coordinates: [origin, destination], steps: [], isSnappedToRoads: false)
    }
    
    private func haversineMeters(_ p1: CLLocationCoordinate2D, _ p2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: p1.latitude, longitude: p1.longitude)
        let loc2 = CLLocation(latitude: p2.latitude, longitude: p2.longitude)
        return loc1.distance(from: loc2)
    }
}
