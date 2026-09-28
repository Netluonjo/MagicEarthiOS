import SwiftUI

struct MapLayersSheet: View {
    @Binding var selectedStyle: MapStyleType
    @Binding var is3DBuildingsEnabled: Bool
    @Binding var showTrafficCameras: Bool
    @Binding var showCommunityIncidents: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("KIỂU BẢN ĐỒ").font(.caption).foregroundColor(.gray)) {
                    ForEach(MapStyleType.allCases) { style in
                        Button(action: {
                            selectedStyle = style
                        }) {
                            HStack {
                                Text(style.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("TÙY CHỌN 3D & LỚP DỮ LIỆU").font(.caption).foregroundColor(.gray)) {
                    Toggle(isOn: $is3DBuildingsEnabled) {
                        HStack {
                            Image(systemName: "building.2.crop.circle.fill")
                                .foregroundColor(.indigo)
                            Text("Khối nhà 3D (Độ nghiêng 55°)")
                        }
                    }
                    
                    Toggle(isOn: $showTrafficCameras) {
                        HStack {
                            Image(systemName: "camera.badge.ellipsis")
                                .foregroundColor(.orange)
                            Text("Cảnh báo Camera phạt nguội & Tốc độ")
                        }
                    }
                    
                    Toggle(isOn: $showCommunityIncidents) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Báo cáo sự cố cộng đồng (Tai nạn, CSGT)")
                        }
                    }
                }
            }
            .navigationTitle("Lớp Bản Đồ")
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
