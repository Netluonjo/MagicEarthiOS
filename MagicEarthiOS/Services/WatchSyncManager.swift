import Foundation
import WatchConnectivity

class WatchSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncManager()
    
    @Published var isWatchPaired: Bool = false
    @Published var isWatchAppInstalled: Bool = false
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func syncNavigationState(isNavigating: Bool, step: RouteStep?, remainingKm: Double) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        
        var message: [String: Any] = [
            "isNavigating": isNavigating,
            "remainingKm": remainingKm,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let step = step {
            message["instruction"] = step.instruction
            message["streetName"] = step.streetName
            message["distanceMeters"] = step.distanceMeters
            message["icon"] = step.icon
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            // Fallback to updateApplicationContext if unreachable
            try? WCSession.default.updateApplicationContext(message)
        }
    }
    
    func syncRunningWorkout(distanceKm: Double, calories: Int, paceStr: String) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        
        let message: [String: Any] = [
            "workoutType": "running",
            "distanceKm": distanceKm,
            "calories": calories,
            "pace": paceStr
        ]
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            try? WCSession.default.updateApplicationContext(message)
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
