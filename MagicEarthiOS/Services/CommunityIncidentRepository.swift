import Foundation
import CoreLocation
import Combine

class CommunityIncidentRepository: ObservableObject {
    static let shared = CommunityIncidentRepository()
    
    @Published var incidents: [CommunityIncident] = []
    
    init() {
        loadDefaultIncidents()
    }
    
    private func loadDefaultIncidents() {
        // Pre-populate with typical real-time community reports in Vietnam
        self.incidents = [
            CommunityIncident(
                type: .speedCamera,
                title: "Camera giám sát tốc độ",
                subtitle: "Đường Vành Đai 3 trên cao, hướng Mai Dịch",
                coordinate: CLLocationCoordinate2D(latitude: 21.0360, longitude: 105.7820),
                confirmations: 12
            ),
            CommunityIncident(
                type: .roadWork,
                title: "Thi công trải thảm nhựa",
                subtitle: "Đoạn qua ngã tư Liễu Giai - Kim Mã",
                coordinate: CLLocationCoordinate2D(latitude: 21.0322, longitude: 105.8155),
                confirmations: 8
            ),
            CommunityIncident(
                type: .police,
                title: "Tổ công tác 141 kiểm tra",
                subtitle: "Ngã tư Trần Phú - Điện Biên Phủ",
                coordinate: CLLocationCoordinate2D(latitude: 21.0315, longitude: 105.8420),
                confirmations: 19
            ),
            CommunityIncident(
                type: .hazard,
                title: "Mặt đường trơn trượt có cát",
                subtitle: "Cầu Nhật Tân chiều đi Sân bay Nội Bài",
                coordinate: CLLocationCoordinate2D(latitude: 21.0850, longitude: 105.8180),
                confirmations: 5
            )
        ]
    }
    
    func reportIncident(type: IncidentType, title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        let incident = CommunityIncident(
            type: type,
            title: title.isEmpty ? type.title : title,
            subtitle: subtitle.isEmpty ? "Vừa được người dùng báo cáo" : subtitle,
            coordinate: coordinate,
            timestamp: Date(),
            confirmations: 1
        )
        incidents.insert(incident, at: 0)
        VoiceGuidanceManager.shared.speak("Cảm ơn bạn đã đóng góp thông tin giao thông cho cộng đồng")
    }
    
    func confirmIncident(id: UUID) {
        if let idx = incidents.firstIndex(where: { $0.id == id }) {
            incidents[idx].confirmations += 1
        }
    }
}
