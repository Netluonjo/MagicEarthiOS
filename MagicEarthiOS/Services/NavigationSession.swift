import Foundation
import CoreLocation
import Combine

class NavigationSession: ObservableObject {
    static let shared = NavigationSession()
    
    @Published var isNavigating: Bool = false
    @Published var currentRoute: RouteResult?
    @Published var currentStepIndex: Int = 0
    @Published var distanceToNextStepMeters: Double = 0
    @Published var remainingDistanceKm: Double = 0
    @Published var remainingDurationMinutes: Int = 0
    @Published var currentSpeedKmh: Double = 0
    @Published var speedLimitKmh: Int = 50
    @Published var isOffRoute: Bool = false
    @Published var isMuted: Bool = false
    @Published var hasArrived: Bool = false
    
    private var lastVoiceStepIndex: Int = -1
    private var lastVoiceDistanceTier: Int = 0 // 300, 100, 0
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        LocationManager.shared.$userLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                self?.onLocationUpdate(location)
            }
            .store(in: &cancellables)
            
        LocationManager.shared.$currentSpeedKmh
            .sink { [weak self] speed in
                self?.currentSpeedKmh = speed
            }
            .store(in: &cancellables)
    }
    
    var currentStep: RouteStep? {
        guard let route = currentRoute, currentStepIndex < route.steps.count else { return nil }
        return route.steps[currentStepIndex]
    }
    
    var nextStep: RouteStep? {
        guard let route = currentRoute, currentStepIndex + 1 < route.steps.count else { return nil }
        return route.steps[currentStepIndex + 1]
    }
    
    func startNavigation(with route: RouteResult) {
        self.currentRoute = route
        self.currentStepIndex = 0
        self.isNavigating = true
        self.hasArrived = false
        self.isOffRoute = false
        self.lastVoiceStepIndex = -1
        self.lastVoiceDistanceTier = 0
        self.remainingDistanceKm = route.metrics.distanceKm
        self.remainingDurationMinutes = route.metrics.durationMinutes
        
        if let firstStep = route.steps.first {
            VoiceGuidanceManager.shared.speak("Bắt đầu dẫn đường. Đi theo \(firstStep.streetName.isEmpty ? "lộ trình" : firstStep.streetName)")
        }
        
        WatchSyncManager.shared.syncNavigationState(isNavigating: true, step: currentStep, remainingKm: remainingDistanceKm)
    }
    
    func stopNavigation() {
        self.isNavigating = false
        self.currentRoute = nil
        self.currentStepIndex = 0
        self.hasArrived = false
        self.isOffRoute = false
        VoiceGuidanceManager.shared.speak("Đã dừng dẫn đường")
        WatchSyncManager.shared.syncNavigationState(isNavigating: false, step: nil, remainingKm: 0)
    }
    
    func toggleMute() {
        isMuted.toggle()
        VoiceGuidanceManager.shared.isMuted = isMuted
    }
    
    private func onLocationUpdate(_ location: CLLocation) {
        guard isNavigating, let route = currentRoute, !route.steps.isEmpty else { return }
        
        // 1. Off-route detection
        checkOffRoute(userLocation: location, routeCoordinates: route.coordinates)
        
        // 2. Check arrival
        if let lastCoord = route.coordinates.last {
            let destLoc = CLLocation(latitude: lastCoord.latitude, longitude: lastCoord.longitude)
            let distToDest = location.distance(from: destLoc)
            if distToDest < 25 {
                hasArrived = true
                VoiceGuidanceManager.shared.speak("Bạn đã đến nơi. Chuyến đi hoàn tất.")
                stopNavigation()
                return
            }
        }
        
        // 3. Step progression
        guard currentStepIndex < route.steps.count else { return }
        let currentStepObj = route.steps[currentStepIndex]
        let stepLoc = CLLocation(latitude: currentStepObj.coordinate.latitude, longitude: currentStepObj.coordinate.longitude)
        let distToStep = location.distance(from: stepLoc)
        self.distanceToNextStepMeters = distToStep
        
        // Advance step if within 20m of turn waypoint
        if distToStep < 20 && currentStepIndex < route.steps.count - 1 {
            currentStepIndex += 1
            lastVoiceDistanceTier = 0
            if let step = currentStep {
                VoiceGuidanceManager.shared.speak(step.instruction)
            }
        } else {
            // Voice triggers at distance intervals (300m, 100m, 30m)
            handleVoicePrompts(distToStep: distToStep, step: currentStepObj)
        }
        
        // Dynamic speed limit based on step street name
        if currentStepObj.streetName.lowercased().contains("cao tốc") || currentStepObj.streetName.lowercased().contains("đại lộ") {
            speedLimitKmh = 100
        } else {
            speedLimitKmh = 60
        }
        
        WatchSyncManager.shared.syncNavigationState(isNavigating: true, step: currentStep, remainingKm: remainingDistanceKm)
    }
    
    private func handleVoicePrompts(distToStep: Double, step: RouteStep) {
        guard !isMuted else { return }
        
        if distToStep <= 350 && distToStep > 250 && lastVoiceDistanceTier != 300 {
            lastVoiceDistanceTier = 300
            VoiceGuidanceManager.shared.speak("Sau 300 mét nữa, \(step.instruction)")
        } else if distToStep <= 150 && distToStep > 70 && lastVoiceDistanceTier != 100 {
            lastVoiceDistanceTier = 100
            VoiceGuidanceManager.shared.speak("Sau 100 mét nữa, chuẩn bị \(step.instruction)")
        } else if distToStep <= 35 && lastVoiceDistanceTier != 30 {
            lastVoiceDistanceTier = 30
            VoiceGuidanceManager.shared.speak("Rẽ ngay bây giờ vào \(step.streetName)")
        }
    }
    
    private func checkOffRoute(userLocation: CLLocation, routeCoordinates: [CLLocationCoordinate2D]) {
        var minDistance: Double = .greatestFiniteMagnitude
        for coord in routeCoordinates {
            let ptLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let dist = userLocation.distance(from: ptLoc)
            if dist < minDistance {
                minDistance = dist
            }
        }
        
        if minDistance > 45.0 {
            if !isOffRoute {
                isOffRoute = true
                VoiceGuidanceManager.shared.speak("Bạn đã đi chệch cung đường. Đang tự động tính toán lại lộ trình...")
                // Trigger auto reroute
                autoReroute(from: userLocation.coordinate)
            }
        } else {
            isOffRoute = false
        }
    }
    
    private func autoReroute(from startCoord: CLLocationCoordinate2D) {
        guard let destCoord = currentRoute?.coordinates.last else { return }
        RoutingEngine.shared.route(from: startCoord, to: destCoord, mode: .car) { [weak self] result in
            guard let self = self, let newRoute = result else { return }
            self.currentRoute = newRoute
            self.currentStepIndex = 0
            self.isOffRoute = false
            VoiceGuidanceManager.shared.speak("Đã cập nhật lộ trình mới tối ưu.")
        }
    }
}
