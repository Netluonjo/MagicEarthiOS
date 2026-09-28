import SwiftUI
import CoreLocation

struct MainContentView: View {
    // Services & State
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var session = NavigationSession.shared
    @StateObject private var trafficEngine = LiveTrafficEngine.shared
    
    // Map State
    @State private var selectedStyle: MapStyleType = .vector2D
    @State private var is3DEnabled: Bool = false
    @State private var centerCoordinate: CLLocationCoordinate2D?
    @State private var destinationCoordinate: CLLocationCoordinate2D?
    @State private var destinationName: String = "Điểm đến đã chọn"
    
    // Mode & Route State
    @State private var selectedMode: TransportMode = .car
    @State private var activeRoute: RouteResult?
    @State private var isCalculatingRoute: Bool = false
    
    // Running Studio State
    @State private var isRunningStudioActive: Bool = false
    @State private var isDrawingMode: Bool = true
    @State private var drawnTouchPoints: [CGPoint] = []
    @State private var drawnCoordinates: [CLLocationCoordinate2D] = []
    @State private var runningDistanceKm: Double = 0
    @State private var runningDurationMinutes: Int = 0
    @State private var runningCalories: Int = 0
    @State private var isRunningRouteSnapped: Bool = false
    @State private var isSnappingLoading: Bool = false
    
    // Truck Config State
    @State private var truckConfig = TruckConfig()
    
    // Sheets & Overlays
    @State private var showingLayersSheet: Bool = false
    @State private var showingIncidentSheet: Bool = false
    @State private var showingTruckSheet: Bool = false
    @State private var showingWeightSheet: Bool = false
    @State private var showingOfflineSheet: Bool = false
    @State private var showingHUDView: Bool = false
    @State private var showTrafficCameras: Bool = true
    @State private var showCommunityIncidents: Bool = true
    
    // Search Text
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            // MARK: - 1. MapLibre Base Map
            MapLibreContainerView(
                styleType: $selectedStyle,
                is3DEnabled: $is3DEnabled,
                routeCoordinates: Binding(
                    get: { activeRoute?.coordinates ?? [] },
                    set: { _ in }
                ),
                drawnCoordinates: $drawnCoordinates,
                centerCoordinate: $centerCoordinate,
                onCoordinateTapped: { coord in
                    if !session.isNavigating && !isRunningStudioActive {
                        handleMapTapped(at: coord)
                    }
                }
            )
            .edgesIgnoringSafeArea(.all)
            
            // MARK: - 2. Running Route Drawing Canvas Overlay
            if isRunningStudioActive {
                RouteDrawingCanvasView(
                    isDrawingMode: $isDrawingMode,
                    touchPoints: $drawnTouchPoints,
                    onPointAdded: { pt in
                        handlePointDrawn(pt)
                    },
                    onDrawingFinished: { points in
                        finalizeDrawnPath(points)
                    }
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            // MARK: - 3. Speed Camera Proximity Alert Toast
            if let alertCam = trafficEngine.activeCameraAlert {
                VStack {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CẢNH BÁO CAMERA PHẠT NGUỘI")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(alertCam.name) • Giới hạn \(alertCam.speedLimit) km/h")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                        }
                        
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.88))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: trafficEngine.activeCameraAlert != nil)
            }
            
            // MARK: - 4. Top Header & Mode Bar (Hidden during Active Nav)
            if !session.isNavigating && !showingHUDView {
                VStack(spacing: 10) {
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Tìm kiếm điểm đến, địa chỉ, nhà ga...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.95))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 3)
                    
                    // Modes Selector Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(TransportMode.allCases) { mode in
                                Button(action: {
                                    selectedMode = mode
                                    if mode == .truck {
                                        showingTruckSheet = true
                                    }
                                    if isRunningStudioActive {
                                        isRunningStudioActive = false
                                    }
                                    recalculateCurrentRoute()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: mode.iconName)
                                        Text(mode.title)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedMode == mode && !isRunningStudioActive ? Color.blue : Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.9))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }
                            }
                            
                            // Dedicated Running Studio Button
                            Button(action: {
                                toggleRunningStudio()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.run")
                                    Text("🏃 Chạy Bộ & Vẽ Cung")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isRunningStudioActive ? Color.green : Color(red: 0.12, green: 0.14, blue: 0.18).opacity(0.9))
                                .foregroundColor(isRunningStudioActive ? .black : .white)
                                .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 46)
            }
            
            // MARK: - 5. Floating Action Buttons (Right Side)
            if !session.isNavigating && !showingHUDView {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Map Layers
                            FABButton(icon: "square.3.layers.3d", color: .white) {
                                showingLayersSheet = true
                            }
                            
                            // 3D Tilt Toggle
                            FABButton(icon: is3DEnabled ? "view.2d" : "view.3d", color: is3DEnabled ? .cyan : .white) {
                                is3DEnabled.toggle()
                            }
                            
                            // Offline Maps
                            FABButton(icon: "arrow.down.circle", color: .white) {
                                showingOfflineSheet = true
                            }
                            
                            // Community Incident Report
                            FABButton(icon: "exclamationmark.bubble.fill", color: .yellow) {
                                showingIncidentSheet = true
                            }
                            
                            // Re-center Location
                            FABButton(icon: "location.fill", color: .blue) {
                                if let userLoc = locationManager.userLocation {
                                    centerCoordinate = userLoc.coordinate
                                }
                            }
                        }
                        .padding(.trailing, 14)
                        .padding(.bottom, isRunningStudioActive || activeRoute != nil ? 230 : 30)
                    }
                }
            }
            
            // MARK: - 6. Route Preview Bottom Card
            if let route = activeRoute, !session.isNavigating && !isRunningStudioActive {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(destinationName)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 8) {
                                    Text(route.metrics.formattedDistance)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.green)
                                    Text("•")
                                        .foregroundColor(.gray)
                                    Text(route.metrics.formattedDuration)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("•")
                                        .foregroundColor(.gray)
                                    Text("ETA: \(route.metrics.etaString)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.cyan)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                activeRoute = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                showingHUDView = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "car.window.right")
                                    Text("HUD Kính")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.12))
                                .foregroundColor(.cyan)
                                .cornerRadius(14)
                            }
                            
                            Button(action: {
                                session.startNavigation(with: route)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "location.north.fill")
                                    Text("BẮT ĐẦU DẪN ĐƯỜNG")
                                        .font(.system(size: 15, weight: .heavy))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.96))
                            .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -4)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            
            // MARK: - 7. Running Studio Card
            if isRunningStudioActive {
                VStack {
                    Spacer()
                    
                    RunningStudioView(
                        isDrawingMode: $isDrawingMode,
                        distanceKm: $runningDistanceKm,
                        estimatedMinutes: $runningDurationMinutes,
                        calories: $runningCalories,
                        isSnapped: $isRunningRouteSnapped,
                        isSnappingLoading: $isSnappingLoading,
                        onToggleDrawingMode: {
                            isDrawingMode.toggle()
                        },
                        onSnapToRoads: {
                            snapRunningRouteToRoads()
                        },
                        onCloseLoop: {
                            closeRunningLoop()
                        },
                        onUndo: {
                            undoLastDrawnPoint()
                        },
                        onClear: {
                            clearRunningRoute()
                        },
                        onOpenWeightSettings: {
                            showingWeightSheet = true
                        },
                        onStartRunning: {
                            startRunningGuidance()
                        },
                        onCloseStudio: {
                            isRunningStudioActive = false
                            drawnCoordinates = []
                            drawnTouchPoints = []
                        }
                    )
                }
            }
            
            // MARK: - 8. Active Turn-by-Turn Guidance Overlay
            if session.isNavigating {
                NavigationDashboardOverlay(
                    onOpenHUD: {
                        showingHUDView = true
                    },
                    onStopNavigation: {
                        session.stopNavigation()
                    }
                )
            }
        }
        // MARK: - Fullscreen Sheets & Modals
        .sheet(isPresented: $showingLayersSheet) {
            MapLayersSheet(
                selectedStyle: $selectedStyle,
                is3DBuildingsEnabled: $is3DEnabled,
                showTrafficCameras: $showTrafficCameras,
                showCommunityIncidents: $showCommunityIncidents
            )
        }
        .sheet(isPresented: $showingIncidentSheet) {
            IncidentReportSheet(userCoordinate: locationManager.userLocation?.coordinate)
        }
        .sheet(isPresented: $showingTruckSheet) {
            TruckConfigSheet(truckConfig: $truckConfig)
        }
        .sheet(isPresented: $showingWeightSheet) {
            RunnerWeightSheet()
        }
        .sheet(isPresented: $showingOfflineSheet) {
            OfflineMapsSheet()
        }
        .fullScreenCover(isPresented: $showingHUDView) {
            HUDMirroredView {
                showingHUDView = false
            }
        }
    }
    
    // MARK: - Actions & Logic
    private func handleMapTapped(at coordinate: CLLocationCoordinate2D) {
        self.destinationCoordinate = coordinate
        self.destinationName = String(format: "Tọa độ: %.4f, %.4f", coordinate.latitude, coordinate.longitude)
        recalculateCurrentRoute()
    }
    
    private func recalculateCurrentRoute() {
        guard let dest = destinationCoordinate else { return }
        let start = locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
        
        isCalculatingRoute = true
        RoutingEngine.shared.route(from: start, to: dest, mode: selectedMode, truckConfig: selectedMode == .truck ? truckConfig : nil) { result in
            DispatchQueue.main.async {
                self.isCalculatingRoute = false
                self.activeRoute = result
            }
        }
    }
    
    private func toggleRunningStudio() {
        isRunningStudioActive.toggle()
        if isRunningStudioActive {
            selectedMode = .pedestrian
            isDrawingMode = true
            VoiceGuidanceManager.shared.speak("Đã vào Studio chạy bộ. Dùng ngón tay vẽ cung đường trực tiếp lên bản đồ.")
        }
    }
    
    private func handlePointDrawn(_ point: CGPoint) {
        // Approximate coordinate projection relative to current map center
        let center = locationManager.userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
        let latDelta = -Double(point.y - 400) * 0.00004
        let lonDelta = Double(point.x - 200) * 0.00004
        let newCoord = CLLocationCoordinate2D(latitude: center.latitude + latDelta, longitude: center.longitude + lonDelta)
        drawnCoordinates.append(newCoord)
        
        updateRunningMetrics()
    }
    
    private func finalizeDrawnPath(_ points: [CGPoint]) {
        updateRunningMetrics()
    }
    
    private func updateRunningMetrics() {
        guard drawnCoordinates.count > 1 else {
            runningDistanceKm = 0
            runningDurationMinutes = 0
            runningCalories = 0
            return
        }
        
        var totalDistMeters: Double = 0
        for i in 1..<drawnCoordinates.count {
            let p1 = CLLocation(latitude: drawnCoordinates[i-1].latitude, longitude: drawnCoordinates[i-1].longitude)
            let p2 = CLLocation(latitude: drawnCoordinates[i].latitude, longitude: drawnCoordinates[i].longitude)
            totalDistMeters += p1.distance(from: p2)
        }
        
        self.runningDistanceKm = totalDistMeters / 1000.0
        let paceMinutesPerKm: Double = 5.5 // 5'30"
        let minutes = Int(runningDistanceKm * paceMinutesPerKm)
        self.runningDurationMinutes = max(1, minutes)
        
        let weight = UserDefaults.standard.double(forKey: "user_body_weight")
        let effectiveWeight = weight > 0 ? weight : 65.0
        self.runningCalories = RunningCalorieCalculator.calculateCalories(distanceKm: runningDistanceKm, durationMinutes: self.runningDurationMinutes, bodyWeightKg: effectiveWeight)
    }
    
    private func snapRunningRouteToRoads() {
        guard drawnCoordinates.count >= 2 else { return }
        isSnappingLoading = true
        
        RoutingEngine.shared.snapCoordinatesToRoads(coordinates: drawnCoordinates, mode: .pedestrian) { result in
            DispatchQueue.main.async {
                self.isSnappingLoading = false
                guard let snapped = result else {
                    VoiceGuidanceManager.shared.speak("Không thể nắn đường. Vui lòng kiểm tra kết nối mạng.")
                    return
                }
                
                self.drawnCoordinates = snapped.coordinates
                self.runningDistanceKm = snapped.metrics.distanceKm
                self.runningDurationMinutes = snapped.metrics.durationMinutes
                self.isRunningRouteSnapped = true
                
                let weight = UserDefaults.standard.double(forKey: "user_body_weight")
                self.runningCalories = RunningCalorieCalculator.calculateCalories(
                    distanceKm: self.runningDistanceKm,
                    durationMinutes: self.runningDurationMinutes,
                    bodyWeightKg: weight > 0 ? weight : 65.0
                )
                
                VoiceGuidanceManager.shared.speak("Đã nắn cung đường khớp hoàn toàn vào tim đường. Cung đường dài \(String(format: "%.2f", self.runningDistanceKm)) ki-lô-mét.")
            }
        }
    }
    
    private func closeRunningLoop() {
        guard let first = drawnCoordinates.first, let last = drawnCoordinates.last else { return }
        let p1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let p2 = CLLocation(latitude: last.latitude, longitude: last.longitude)
        if p1.distance(from: p2) > 10 {
            drawnCoordinates.append(first)
            updateRunningMetrics()
            VoiceGuidanceManager.shared.speak("Đã khép kín vòng chạy quay về điểm xuất phát")
        }
    }
    
    private func undoLastDrawnPoint() {
        if !drawnCoordinates.isEmpty {
            let removeCount = min(15, drawnCoordinates.count)
            drawnCoordinates.removeLast(removeCount)
            if !drawnTouchPoints.isEmpty {
                let removeTouch = min(15, drawnTouchPoints.count)
                drawnTouchPoints.removeLast(removeTouch)
            }
            updateRunningMetrics()
        }
    }
    
    private func clearRunningRoute() {
        drawnCoordinates.removeAll()
        drawnTouchPoints.removeAll()
        runningDistanceKm = 0
        runningDurationMinutes = 0
        runningCalories = 0
        isRunningRouteSnapped = false
    }
    
    private func startRunningGuidance() {
        guard drawnCoordinates.count > 1 else { return }
        
        let metrics = RouteMetrics(
            distanceKm: runningDistanceKm,
            durationMinutes: runningDurationMinutes,
            etaString: "Chạy bộ",
            trafficCondition: "Tự do"
        )
        
        let steps = [
            RouteStep(
                instruction: "Bắt đầu bài chạy theo lộ trình đã vẽ",
                streetName: "Cung đường chạy bộ",
                distanceMeters: runningDistanceKm * 1000,
                durationSeconds: Double(runningDurationMinutes * 60),
                turnType: "depart",
                modifier: "straight",
                icon: "figure.run",
                coordinate: drawnCoordinates.first!
            )
        ]
        
        let route = RouteResult(
            metrics: metrics,
            coordinates: drawnCoordinates,
            steps: steps,
            isSnappedToRoads: isRunningRouteSnapped
        )
        
        isRunningStudioActive = false
        session.startNavigation(with: route)
    }
}

// MARK: - FAB Button Helper
private struct FABButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .frame(width: 46, height: 46)
                .background(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.92))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
    }
}
