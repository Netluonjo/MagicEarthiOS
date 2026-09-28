import SwiftUI
import CoreLocation

struct IncidentReportSheet: View {
    @ObservedObject var repository = CommunityIncidentRepository.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: IncidentType = .police
    @State private var titleText: String = ""
    @State private var subtitleText: String = ""
    
    var userCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("LOẠI SỰ CỐ GIAO THÔNG").font(.caption).foregroundColor(.gray)) {
                    ForEach(IncidentType.allCases) { type in
                        Button(action: {
                            selectedType = type
                            if titleText.isEmpty {
                                titleText = type.title
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: type.iconName)
                                    .font(.title3)
                                    .foregroundColor(colorForType(type))
                                    .frame(width: 28)
                                
                                Text(type.title)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("CHI TIẾT VỊ TRÍ & MÔ TẢ").font(.caption).foregroundColor(.gray)) {
                    TextField("Tiêu đề (VD: Chốt kiểm tra nồng độ cồn)", text: $titleText)
                    TextField("Ghi chú thêm (VD: Chiều từ Cầu Giấy về Kim Mã)", text: $subtitleText)
                }
                
                Section {
                    Button(action: submitReport) {
                        HStack {
                            Spacer()
                            Image(systemName: "paperplane.fill")
                            Text("GỬI BÁO CÁO CỘNG ĐỒNG")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Báo Cáo Sự Cố")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func colorForType(_ type: IncidentType) -> Color {
        switch type {
        case .accident: return .red
        case .speedCamera: return .orange
        case .roadWork: return .yellow
        case .hazard: return .purple
        case .police: return .blue
        }
    }
    
    private func submitReport() {
        let coord = userCoordinate ?? CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
        repository.reportIncident(type: selectedType, title: titleText, subtitle: subtitleText, coordinate: coord)
        dismiss()
    }
}
