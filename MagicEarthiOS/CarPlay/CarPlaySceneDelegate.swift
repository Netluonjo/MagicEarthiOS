import UIKit
import CarPlay
import CoreLocation

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate {
    var interfaceController: CPInterfaceController?
    var mapTemplate: CPMapTemplate?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController,
                                  to window: CPWindow) {
        self.interfaceController = interfaceController
        
        // Setup Map Template for CarPlay Display
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        self.mapTemplate = mapTemplate
        
        // Add Bar Buttons
        let searchButton = CPBarButton(type: .image) { [weak self] _ in
            self?.presentCarPlaySearch()
        }
        searchButton.image = UIImage(systemName: "magnifyingglass")
        
        let recentButton = CPBarButton(type: .text) { [weak self] _ in
            self?.presentRecentDestinations()
        }
        recentButton.title = "Gần đây"
        
        mapTemplate.trailingNavigationBarButtons = [searchButton, recentButton]
        
        // Observe Navigation Session
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onNavigationUpdated),
            name: NSNotification.Name("CarPlayNavUpdate"),
            object: nil
        )
        
        interfaceController.setRootTemplate(mapTemplate, animated: true, completion: nil)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        self.mapTemplate = nil
    }
    
    // MARK: - CPMapTemplateDelegate
    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {}
    func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {}
    
    private func presentCarPlaySearch() {
        let items = [
            CPListItem(text: "Hồ Hoàn Kiếm", detailText: "Quận Hoàn Kiếm, Hà Nội"),
            CPListItem(text: "Sân bay Quốc tế Nội Bài", detailText: "Sóc Sơn, Hà Nội"),
            CPListItem(text: "Trung tâm Hội nghị Quốc gia", detailText: "Đại lộ Thăng Long, Mễ Trì"),
            CPListItem(text: "Hồ Tây - Phủ Tây Hồ", detailText: "Quận Tây Hồ, Hà Nội")
        ]
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Tìm kiếm điểm đến", sections: [section])
        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    private func presentRecentDestinations() {
        let items = [
            CPListItem(text: "Nhà riêng", detailText: "Lưu trong danh bạ cá nhân"),
            CPListItem(text: "Nơi làm việc", detailText: "Khu Công Nghệ Cao Duy Tân"),
            CPListItem(text: "Cây xăng Petrolimex gần nhất", detailText: "Cách 850m")
        ]
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: "Địa điểm đã lưu", sections: [section])
        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    @objc private func onNavigationUpdated() {
        // CarPlay trip banner updates
    }
}
