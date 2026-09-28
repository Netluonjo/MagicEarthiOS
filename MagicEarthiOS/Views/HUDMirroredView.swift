import SwiftUI

struct HUDMirroredView: View {
    @ObservedObject var session = NavigationSession.shared
    @State private var isMirrored: Bool = true
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Pure Black OLED background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Top control bar
                HStack {
                    Button(action: {
                        isMirrored.toggle()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            Text(isMirrored ? "Đang Lật Kính (HUD)" : "Hiển thị Thường")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.cyan)
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Massive Turn Arrow
                Image(systemName: session.currentStep?.icon ?? "arrow.up")
                    .font(.system(size: 140, weight: .heavy))
                    .foregroundColor(.cyan)
                    .shadow(color: Color.cyan.opacity(0.8), radius: 25)
                
                // Distance to turn
                Text(formatDistance(session.distanceToNextStepMeters))
                    .font(.system(size: 72, weight: .black))
                    .foregroundColor(.white)
                
                // Street Name
                Text(session.currentStep?.streetName.isEmpty == false ? (session.currentStep?.streetName ?? "") : (session.currentStep?.instruction ?? "Đi thẳng"))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Speed & Speed Limit Row
                HStack(spacing: 40) {
                    // Speed Limit Circle
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color.red, lineWidth: 8)
                            )
                        
                        Text("\(session.speedLimitKmh)")
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(.black)
                    }
                    
                    // Current Speed
                    VStack(spacing: 2) {
                        Text("\(Int(session.currentSpeedKmh))")
                            .font(.system(size: 64, weight: .black))
                            .foregroundColor(session.currentSpeedKmh > Double(session.speedLimitKmh) ? .red : .green)
                        Text("KM/H")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 48)
            }
            .scaleEffect(x: isMirrored ? -1 : 1, y: 1) // Mirrored for windshield reflection
        }
        .statusBar(hidden: true)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000.0)
        } else {
            return "\(Int(meters)) m"
        }
    }
}
