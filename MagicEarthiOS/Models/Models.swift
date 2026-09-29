import Foundation
import CoreLocation

// MARK: - Transport Modes
enum TransportMode: String, CaseIterable, Identifiable {
    case car = "CAR"
    case truck = "TRUCK"
    case bicycle = "BICYCLE"
    case pedestrian = "PEDESTRIAN"
    case transit = "TRANSIT"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .car: return "Ô tô"
        case .truck: return "Xe tải"
        case .bicycle: return "Xe đạp"
        case .pedestrian: return "Đi bộ"
        case .transit: return "Xe buýt"
        }
    }
    
    var iconName: String {
        switch self {
        case .car: return "car.fill"
        case .truck: return "box.truck.fill"
        case .bicycle: return "bicycle"
        case .pedestrian: return "figure.walk"
        case .transit: return "bus.fill"
        }
    }
}

// MARK: - Route Metrics
struct RouteMetrics: Equatable {
    var distanceKm: Double
    var durationMinutes: Int
    var etaString: String
    var trafficCondition: String
    var surfacePavedPct: Int = 95
    var surfaceUnpavedPct: Int = 5
    var hasWaypoints: Bool = false
    
    var formattedDistance: String {
        return String(format: "%.2f km", distanceKm)
    }
    
    var formattedDuration: String {
        if durationMinutes >= 60 {
            let h = durationMinutes / 60
            let m = durationMinutes % 60
            return "\(h) giờ \(m) phút"
        } else {
            return "\(durationMinutes) phút"
        }
    }
}

// MARK: - Turn-by-Turn Route Step
struct RouteStep: Identifiable, Equatable {
    let id = UUID()
    var instruction: String
    var streetName: String
    var distanceMeters: Double
    var durationSeconds: Double
    var turnType: String
    var modifier: String
    var icon: String
    var coordinate: CLLocationCoordinate2D
    
    static func == (lhs: RouteStep, rhs: RouteStep) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Route Result
struct RouteResult: Equatable {
    var metrics: RouteMetrics
    var coordinates: [CLLocationCoordinate2D]
    var steps: [RouteStep]
    var isSnappedToRoads: Bool = true
    
    static func == (lhs: RouteResult, rhs: RouteResult) -> Bool {
        return lhs.metrics == rhs.metrics && lhs.coordinates.count == rhs.coordinates.count
    }
}

// MARK: - Waypoint
struct Waypoint: Identifiable, Equatable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    var name: String
    
    static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Commercial Truck Config
struct TruckConfig: Equatable {
    var weightTons: Double = 18.0
    var heightMeters: Double = 3.9
    var axles: Int = 3
    var hasHazardousMaterial: Bool = false
}

// MARK: - Community Incident
enum IncidentType: String, CaseIterable, Identifiable {
    case accident = "ACCIDENT"
    case speedCamera = "CAMERA"
    case roadWork = "ROADWORK"
    case hazard = "HAZARD"
    case police = "POLICE"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .accident: return "Tai nạn giao thông"
        case .speedCamera: return "Camera bắn tốc độ"
        case .roadWork: return "Công trường sửa đường"
        case .hazard: return "Chướng ngại nguy hiểm"
        case .police: return "Chốt kiểm tra"
        }
    }
    
    var iconName: String {
        switch self {
        case .accident: return "car.2.fill"
        case .speedCamera: return "camera.fill"
        case .roadWork: return "cone.fill"
        case .hazard: return "exclamationmark.triangle.fill"
        case .police: return "shield.fill"
        }
    }
}

struct CommunityIncident: Identifiable, Equatable {
    let id = UUID()
    var type: IncidentType
    var title: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D
    var timestamp: Date = Date()
    var confirmations: Int = 1
    
    static func == (lhs: CommunityIncident, rhs: CommunityIncident) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - POI Item
struct POIItem: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var category: String
    var subtitle: String
    var coordinate: CLLocationCoordinate2D
    var distanceMeters: Double = 0
    
    static func == (lhs: POIItem, rhs: POIItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - CoreLocation Equatable Extension
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Map Style Types
enum MapStyleType: String, CaseIterable, Identifiable {
    case vector2D = "2D"
    case vector3D = "3D"
    case satellite = "Satellite"
    case terrain = "Terrain"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .vector2D: return "🗺️ Bản đồ 2D (Tiêu chuẩn)"
        case .vector3D: return "🏙️ Bản đồ 3D (Khối nhà OSM)"
        case .satellite: return "🛰️ Ảnh Vệ Tinh (Satellite)"
        case .terrain: return "⛰️ Địa Hình & Cao Độ (Terrain)"
        case .dark: return "🌙 Chế Độ Đêm OLED Tối Ưu Pin"
        }
    }
    
    var styleURL: URL {
        switch self {
        case .vector2D, .vector3D:
            return URL(string: "https://tiles.openfreemap.org/styles/liberty")!
        case .dark:
            return URL(string: "https://tiles.openfreemap.org/styles/dark")!
        case .satellite:
            return URL(string: "https://api.maptiler.com/maps/hybrid/style.json?key=get_your_own_OpIi9ZULNHzrESv6T2vL") ?? URL(string: "https://tiles.openfreemap.org/styles/liberty")!
        case .terrain:
            return URL(string: "https://tiles.openfreemap.org/styles/bright")!
        }
    }
}
