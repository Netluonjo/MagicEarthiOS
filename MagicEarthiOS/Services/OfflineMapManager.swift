import Foundation
import Combine

struct OfflineRegion: Identifiable, Equatable {
    let id: String
    let name: String
    let sizeMb: Double
    var isDownloaded: Bool
    var downloadProgress: Double = 0.0 // 0.0 to 1.0
}

class OfflineMapManager: ObservableObject {
    static let shared = OfflineMapManager()
    
    @Published var regions: [OfflineRegion] = [
        OfflineRegion(id: "hanoi", name: "Khu vực Hà Nội & Vùng lân cận", sizeMb: 145.0, isDownloaded: true, downloadProgress: 1.0),
        OfflineRegion(id: "hcm", name: "Khu vực TP. Hồ Chí Minh & Đông Nam Bộ", sizeMb: 210.0, isDownloaded: false),
        OfflineRegion(id: "danang", name: "Đà Nẵng & Miền Trung", sizeMb: 95.0, isDownloaded: false),
        OfflineRegion(id: "highlands", name: "Tây Nguyên & Duyên Hải", sizeMb: 120.0, isDownloaded: false),
        OfflineRegion(id: "mekong", name: "Đồng Bằng Sông Cửu Long", sizeMb: 110.0, isDownloaded: false),
        OfflineRegion(id: "vietnam_full", name: "Toàn bộ Lãnh thổ Việt Nam (Vector HD)", sizeMb: 850.0, isDownloaded: false)
    ]
    
    @Published var isDownloading: Bool = false
    
    func downloadRegion(id: String) {
        guard let index = regions.firstIndex(where: { $0.id == id }) else { return }
        isDownloading = true
        regions[index].downloadProgress = 0.05
        
        // Simulating progressive tile pack download
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if self.regions[index].downloadProgress >= 1.0 {
                self.regions[index].isDownloaded = true
                self.regions[index].downloadProgress = 1.0
                self.isDownloading = false
                timer.invalidate()
                VoiceGuidanceManager.shared.speak("Đã tải xong bản đồ ngoại tuyến khu vực \(self.regions[index].name)")
            } else {
                self.regions[index].downloadProgress += 0.15
            }
        }
    }
    
    func deleteRegion(id: String) {
        guard let index = regions.firstIndex(where: { $0.id == id }) else { return }
        regions[index].isDownloaded = false
        regions[index].downloadProgress = 0.0
    }
}
