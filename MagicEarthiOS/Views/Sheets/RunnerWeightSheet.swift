import SwiftUI

struct RunnerWeightSheet: View {
    @AppStorage("user_body_weight") private var userWeight: Double = 65.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CÂN NẶNG NGƯỜI CHẠY").font(.caption).foregroundColor(.gray),
                        footer: Text("Công thức chuẩn ACSM: Calo = METs (9.8 cho Pace 5'30\") × 3.5 × Cân nặng (kg) / 200 × Số phút. Cân nặng chính xác giúp tính toán calo tiêu thụ chuẩn xác nhất.")) {
                    
                    VStack(spacing: 16) {
                        Text("\(Int(userWeight)) kg")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Slider(value: $userWeight, in: 40...140, step: 1.0)
                            .accentColor(.green)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Tùy Chỉnh Cân Nặng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        dismiss()
                    }
                }
            }
        }
    }
}
