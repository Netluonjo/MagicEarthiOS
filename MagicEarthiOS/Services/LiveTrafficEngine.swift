import Foundation
import CoreLocation
import Combine

class LiveTrafficEngine: ObservableObject {
    static let shared = LiveTrafficEngine()
    
    @Published var nearbyCameras: [TrafficCamera] = []
    @Published var activeCameraAlert: TrafficCamera?
    @Published var trafficCongestionLevel: String = "Lưu thông thông suốt"
    @Published var isSpeeding: Bool = false
    
    private var alertedCameraIds = Set<String>()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        LocationManager.shared.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.evaluateProximity(to: location)
            }
            .store(in: &cancellables)
    }
    
    func evaluateProximity(to location: CLLocation) {
        let allCameras = TrafficCamera.vietnamCameras
        var nearby: [TrafficCamera] = []
        var alertTriggered: TrafficCamera?
        
        for cam in allCameras {
            let camLoc = CLLocation(latitude: cam.coordinate.latitude, longitude: cam.coordinate.longitude)
            let dist = location.distance(from: camLoc)
            
            if dist <= 1500 {
                nearby.append(cam)
            }
            
            // Trigger voice alert when within 500m and not alerted recently
            if dist <= 500 && !alertedCameraIds.contains(cam.id) {
                alertedCameraIds.insert(cam.id)
                alertTriggered = cam
                let speech = "Chú ý: Có \(cam.name) cách \(Int(dist)) mét. Tốc độ giới hạn \(cam.speedLimit) ki-lô-mét một giờ."
                VoiceGuidanceManager.shared.speak(speech)
            }
        }
        
        self.nearbyCameras = nearby
        self.activeCameraAlert = alertTriggered
        
        // Check speeding
        let speed = LocationManager.shared.currentSpeedKmh
        let limit = NavigationSession.shared.speedLimitKmh
        if speed > Double(limit) + 5 {
            if !isSpeeding {
                isSpeeding = true
                VoiceGuidanceManager.shared.speak("Cảnh báo: Bạn đang chạy quá tốc độ quy định!")
            }
        } else {
            isSpeeding = false
        }
    }
    
    func resetAlerts() {
        alertedCameraIds.removeAll()
        activeCameraAlert = nil
    }
}
