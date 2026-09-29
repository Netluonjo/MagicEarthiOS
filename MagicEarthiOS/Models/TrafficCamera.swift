import Foundation
import CoreLocation

struct TrafficCamera: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let speedLimitKmh: Int
    let type: CameraType
    
    var speedLimit: Int { speedLimitKmh }
    
    static var vietnamCameras: [TrafficCamera] {
        return TrafficCameraRepository.shared.cameras
    }
    
    enum CameraType: String {
        case speed = "Tốc độ"
        case redLight = "Đèn đỏ"
        case busLane = "Làn xe buýt BRT"
    }
    
    static func == (lhs: TrafficCamera, rhs: TrafficCamera) -> Bool {
        return lhs.id == rhs.id
    }
}

class TrafficCameraRepository {
    static let shared = TrafficCameraRepository()
    
    let cameras: [TrafficCamera] = [
        TrafficCamera(id: "cam_hn_01", name: "Camera Vành Đai 3 Trên Cao (Trần Duy Hưng)", coordinate: CLLocationCoordinate2D(latitude: 21.0065, longitude: 105.7930), speedLimitKmh: 80, type: .speed),
        TrafficCamera(id: "cam_hn_02", name: "Camera Phạt Nguội Tố Hữu - Lê Văn Lương", coordinate: CLLocationCoordinate2D(latitude: 20.9850, longitude: 105.7750), speedLimitKmh: 60, type: .busLane),
        TrafficCamera(id: "cam_hn_03", name: "Camera Cầu Nhật Tân (Hướng Nội Bài)", coordinate: CLLocationCoordinate2D(latitude: 21.0920, longitude: 105.8200), speedLimitKmh: 90, type: .speed),
        TrafficCamera(id: "cam_hn_04", name: "Camera Đại Lộ Thăng Long (Km 8)", coordinate: CLLocationCoordinate2D(latitude: 20.9990, longitude: 105.7500), speedLimitKmh: 100, type: .speed),
        TrafficCamera(id: "cam_hcm_01", name: "Camera Hầm Thủ Thiêm (Bờ Q.1)", coordinate: CLLocationCoordinate2D(latitude: 10.7675, longitude: 106.7045), speedLimitKmh: 60, type: .speed),
        TrafficCamera(id: "cam_hcm_02", name: "Camera Đại lộ Mai Chí Thọ (Nút An Phú)", coordinate: CLLocationCoordinate2D(latitude: 10.7850, longitude: 106.7400), speedLimitKmh: 80, type: .speed),
        TrafficCamera(id: "cam_hcm_03", name: "Camera Võ Văn Kiệt - Cầu Nguyễn Tri Phương", coordinate: CLLocationCoordinate2D(latitude: 10.7510, longitude: 106.6690), speedLimitKmh: 60, type: .speed)
    ]
    
    func findNearbyCamera(currentLocation: CLLocationCoordinate2D, withinMeters: Double = 600) -> TrafficCamera? {
        let currentLoc = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        for cam in cameras {
            let camLoc = CLLocation(latitude: cam.coordinate.latitude, longitude: cam.coordinate.longitude)
            if currentLoc.distance(from: camLoc) <= withinMeters {
                return cam
            }
        }
        return nil
    }
}
