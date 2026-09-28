import SwiftUI

struct TruckConfigSheet: View {
    @Binding var truckConfig: TruckConfig
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("THÔNG SỐ PHƯƠNG TIỆN THƯƠNG MẠI").font(.caption).foregroundColor(.gray),
                        footer: Text("Hệ thống sẽ tự động tránh cầu vượt giới hạn chiều cao, cầu yếu, đường cấm tải trọng và tuyến phố cấm xe tải theo giờ.")) {
                    
                    HStack {
                        Text("Tổng tải trọng")
                        Spacer()
                        Text(String(format: "%.1f tấn", truckConfig.weightTons))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    Slider(value: $truckConfig.weightTons, in: 2.5...45.0, step: 0.5)
                    
                    HStack {
                        Text("Chiều cao xe")
                        Spacer()
                        Text(String(format: "%.2f mét", truckConfig.heightMeters))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    Slider(value: $truckConfig.heightMeters, in: 2.0...4.8, step: 0.1)
                    
                    Stepper("Số trục xe: \(truckConfig.axles) trục", value: $truckConfig.axles, in: 2...6)
                    
                    Toggle(isOn: $truckConfig.hasHazardousMaterial) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Chở hàng nguy hiểm / Cháy nổ (Hazmat)")
                            Text("Tránh hầm chui và khu dân cư đông đúc")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Cấu Hình Xe Tải")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }
}
