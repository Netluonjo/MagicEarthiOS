import SwiftUI

struct OfflineMapsSheet: View {
    @ObservedObject var manager = OfflineMapManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("GÓI BẢN ĐỒ NGOẠI TUYẾN VIỆT NAM").font(.caption).foregroundColor(.gray),
                        footer: Text("Tải dữ liệu bản đồ về bộ nhớ máy để sử dụng tìm kiếm và dẫn đường mà không cần kết nối mạng 4G/5G.")) {
                    
                    ForEach(manager.regions) { region in
                        HStack(spacing: 12) {
                            Image(systemName: region.isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                                .font(.title2)
                                .foregroundColor(region.isDownloaded ? .green : .blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(region.name)
                                    .font(.system(size: 15, weight: .semibold))
                                
                                HStack(spacing: 8) {
                                    Text(String(format: "%.0f MB", region.sizeMb))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    if region.isDownloaded {
                                        Text("• Đã sẵn sàng ngoại tuyến")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else if region.downloadProgress > 0 && region.downloadProgress < 1.0 {
                                        Text("• Đang tải \(Int(region.downloadProgress * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                if region.downloadProgress > 0 && region.downloadProgress < 1.0 {
                                    ProgressView(value: region.downloadProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                }
                            }
                            
                            Spacer()
                            
                            if region.isDownloaded {
                                Button(action: {
                                    manager.deleteRegion(id: region.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            } else {
                                Button(action: {
                                    manager.downloadRegion(id: region.id)
                                }) {
                                    Text("Tải về")
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .disabled(manager.isDownloading)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Bản Đồ Ngoại Tuyến")
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
