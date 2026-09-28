import SwiftUI

struct NavigationDashboardOverlay: View {
    @ObservedObject var session = NavigationSession.shared
    @ObservedObject var locationManager = LocationManager.shared
    
    var onOpenHUD: () -> Void
    var onStopNavigation: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Top Maneuver Card
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 14) {
                    // Turn Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                            .frame(width: 58, height: 58)
                        
                        Image(systemName: session.currentStep?.icon ?? "arrow.up")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Distance to turn
                        Text(formatDistance(session.distanceToNextStepMeters))
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                        
                        // Street / Instruction
                        Text(session.currentStep?.instruction ?? "Tiếp tục đi thẳng")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Next Maneuver Preview
                    if let next = session.nextStep {
                        VStack(spacing: 2) {
                            Text("Sau đó")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                            Image(systemName: next.icon)
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                // Off-route alert banner if applicable
                if session.isOffRoute {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("Đã lệch đường - Đang tự động tìm lộ trình mới...")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.96))
                    .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 6)
            )
            .padding(.horizontal, 12)
            .padding(.top, 48)
            
            Spacer()
            
            // MARK: - Speedometer & Speed Limit Sign (Floating on Right)
            HStack {
                Spacer()
                
                VStack(spacing: 6) {
                    // Speed Limit Circle (European / Vietnam Standard)
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Circle()
                                    .stroke(Color.red, lineWidth: 6)
                            )
                        
                        Text("\(session.speedLimitKmh)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                    }
                    .shadow(radius: 4)
                    
                    // Current Speed Gauge
                    VStack(spacing: 1) {
                        Text("\(Int(session.currentSpeedKmh))")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(session.currentSpeedKmh > Double(session.speedLimitKmh) ? .red : .white)
                        Text("km/h")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 52, height: 46)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 12)
            }
            
            // MARK: - Bottom Route Summary & Controls
            HStack(spacing: 14) {
                // Trip ETA & Remaining
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(calculateETA())
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.green)
                        
                        Text("ETA")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 8) {
                        Text(String(format: "%.1f km", session.remainingDistanceKm))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text("\(session.remainingDurationMinutes) phút")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Mute Voice Button
                Button(action: {
                    session.toggleMute()
                }) {
                    Image(systemName: session.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(session.isMuted ? .red : .white)
                        .padding(12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                
                // HUD Windshield Mode Button
                Button(action: onOpenHUD) {
                    Image(systemName: "car.window.right")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                        .padding(12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                
                // Stop Navigation Button
                Button(action: onStopNavigation) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("DỪNG")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.95))
                    .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -4)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000.0)
        } else {
            return "\(Int(meters)) m"
        }
    }
    
    private func calculateETA() -> String {
        let etaDate = Date().addingTimeInterval(Double(session.remainingDurationMinutes * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: etaDate)
    }
}
