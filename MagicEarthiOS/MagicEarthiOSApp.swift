import SwiftUI
import AVFoundation

@main
struct MagicEarthiOSApp: App {
    init() {
        // Configure AVAudioSession for background spoken navigation & ducking
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
        
        // Request Location Permissions
        LocationManager.shared.requestPermissions()
    }
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .preferredColorScheme(.dark)
        }
    }
}
