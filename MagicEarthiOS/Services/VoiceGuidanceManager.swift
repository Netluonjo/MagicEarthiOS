import Foundation
import AVFoundation

class VoiceGuidanceManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceGuidanceManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isMuted: Bool = false
    private var lastSpokenText: String = ""
    private var lastSpokenTime: Date = Date.distantPast
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("VoiceGuidanceManager AudioSession error: \(error)")
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    func speak(_ instruction: String, forced: Bool = false) {
        guard !isMuted else { return }
        
        // Prevent repeating exact same instruction within 10 seconds unless forced
        let now = Date()
        if !forced && instruction == lastSpokenText && now.timeIntervalSince(lastSpokenTime) < 10 {
            return
        }
        
        lastSpokenText = instruction
        lastSpokenTime = now
        
        let utterance = AVSpeechUtterance(string: instruction)
        utterance.voice = AVSpeechSynthesisVoice(language: "vi-VN") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52 // Natural cadence
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
