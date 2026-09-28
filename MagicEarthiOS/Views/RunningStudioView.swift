import SwiftUI

struct RunningStudioView: View {
    @Binding var isDrawingMode: Bool
    @Binding var distanceKm: Double
    @Binding var estimatedMinutes: Int
    @Binding var calories: Int
    @Binding var isSnapped: Bool
    @Binding var isSnappingLoading: Bool
    
    var onToggleDrawingMode: () -> Void
    var onSnapToRoads: () -> Void
    var onCloseLoop: () -> Void
    var onUndo: () -> Void
    var onClear: () -> Void
    var onOpenWeightSettings: () -> Void
    var onStartRunning: () -> Void
    var onCloseStudio: () -> Void
    
    @AppStorage("user_body_weight") private var userWeight: Double = 65.0
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STUDIO CHẠY BỘ")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Vẽ tay & Tự động nắn tim đường")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Status Pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(isSnapped ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(isSnapped ? "Đã nắn khớp" : "Nét vẽ tự do")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isSnapped ? .green : .orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                
                Button(action: onCloseStudio) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Metrics Grid
            HStack(spacing: 10) {
                MetricCard(
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    title: "Quãng đường",
                    value: String(format: "%.2f", distanceKm),
                    unit: "km",
                    color: .green
                )
                
                MetricCard(
                    icon: "timer",
                    title: "Thời gian",
                    value: "\(estimatedMinutes)",
                    unit: "phút",
                    color: .cyan
                )
                
                MetricCard(
                    icon: "flame.fill",
                    title: "Calo tiêu hao",
                    value: "\(calories)",
                    unit: "kcal",
                    color: .orange
                )
                
                MetricCard(
                    icon: "speedometer",
                    title: "Pace ước tính",
                    value: "5'30\"",
                    unit: "/km",
                    color: .yellow
                )
            }
            
            // Tool Controls Bar
            HStack(spacing: 8) {
                // Drawing / Pan Toggle
                Button(action: onToggleDrawingMode) {
                    HStack(spacing: 4) {
                        Image(systemName: isDrawingMode ? "pencil.tip.crop.circle.fill" : "hand.draw.fill")
                        Text(isDrawingMode ? "Chế độ vẽ" : "Vuốt xem map")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isDrawingMode ? Color.green.opacity(0.85) : Color.white.opacity(0.15))
                    .foregroundColor(isDrawingMode ? .black : .white)
                    .cornerRadius(10)
                }
                
                // Snap to roads button
                Button(action: onSnapToRoads) {
                    HStack(spacing: 4) {
                        if isSnappingLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "point.filled.topleft.down.curvedto.point.bottomright.up")
                        }
                        Text("Nắn tim đường")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSnappingLoading || distanceKm == 0)
                
                // Close loop button
                Button(action: onCloseLoop) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Khép vòng")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(distanceKm == 0)
                
                // Undo
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Clear
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            
            // Bottom Action Row
            HStack(spacing: 12) {
                // Weight setting button
                Button(action: onOpenWeightSettings) {
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                        Text("\(Int(userWeight)) kg")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // Start Run Button
                Button(action: onStartRunning) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.run")
                            .font(.headline)
                        Text("BẮT ĐẦU CHẠY NGAY")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(distanceKm > 0 ? Color.green : Color.gray.opacity(0.4))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(color: distanceKm > 0 ? Color.green.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 4)
                }
                .disabled(distanceKm == 0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.1, green: 0.12, blue: 0.16).opacity(0.95))
                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

private struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
    }
}
