# 🗺️ Magic Earth iOS - Native Navigation & Running Route Studio

Bản dựng Native iOS của ứng dụng **Magic Earth Navigation** với đầy đủ 100% tính năng tương đương bản Android (`MagicEarthAndroid`), được xây dựng hoàn toàn bằng **SwiftUI** và **MapLibre Native**, sẵn sàng mở và chạy ngay trên Xcode.

---

## 🚀 Các Tính Năng Chính (Đồng Bộ Hoàn Toàn Với Bản Android)

### 1. 🏃 Studio Chạy Bộ & Vẽ Cung Đường Bằng Tay
- **Vẽ tay mượt mà**: Chạm và vuốt trực tiếp trên bản đồ để phác thảo cung đường chạy bộ mong muốn với đường nét Neon Lime (#39FF14) phát sáng.
- **Nắn đường vào tim đường (OSRM Snapping)**: Tự động nhận diện nét vẽ và nắn chính xác vào tim đường giao thông / đường chạy bộ lân cận (thuật toán Douglas-Peucker & OSRM Foot Profile với bán kính snapping 100m).
- **Khép kín vòng chạy**: Tự động nối điểm cuối về điểm xuất phát để tạo thành một vòng chạy hoàn hảo.
- **Chỉ số thời gian thực**: Quãng đường (km), Thời gian ước tính (phút), Pace (min/km), và Calo tiêu thụ tính toán theo công thức chuẩn chuyển hóa sinh học **ACSM**.
- **Tùy chỉnh cân nặng**: Cài đặt cân nặng cơ thể (kg) để đo lường lượng calo chính xác nhất.

### 2. 🧭 Dẫn Đường Từng Bước (Turn-by-Turn Navigation)
- **Giọng nói tiếng Việt**: Tích hợp `AVSpeechSynthesizer` phát âm tự nhiên bằng tiếng Việt (`vi-VN`), tự động hạ âm lượng nhạc nền (Audio Ducking) khi có khẩu lệnh.
- **Tự động tìm lại đường (Auto Rerouting)**: Phát hiện người dùng đi chệch cung đường (>45m) và tự động tính toán lại lộ trình tối ưu ngay lập tức.
- **Biển báo giới hạn tốc độ**: Hiển thị tốc độ hiện tại và biển báo giới hạn tốc độ chuẩn Việt Nam, cảnh báo âm thanh khi chạy quá tốc độ.
- **Đa phương thức di chuyển**:
  - 🚗 Ô tô (Car)
  - 🚚 Xe tải thương mại (Truck - tùy chỉnh tải trọng, chiều cao, số trục, vật liệu nguy hiểm Hazmat)
  - 🚲 Xe đạp (Bicycle)
  - 🚶 Đi bộ (Pedestrian)
  - 🚌 Xe buýt (Transit)

### 3. 🌙 Chế Độ HUD Phản Chiếu Kính Lái Ban Đêm (Windshield HUD)
- Giao diện đen tuyền OLED tương phản cao hiển thị mũi tên rẽ cỡ lớn, khoảng cách, tốc độ và tên đường.
- **Chế độ Lật gương (Mirror Mode)**: Đặt điện thoại nằm phẳng trên taplo ô tô vào ban đêm, hình ảnh phản chiếu lên kính chắn gió sẽ hiển thị xuôi chiều rõ ràng, không gây chói mắt.

### 4. 🛰️ Bản Đồ Vector, 3D & Vệ Tinh (OpenFreeMap / MapLibre)
- **Bản đồ 2D & 3D**: Hiển thị khối nhà 3D nổi khối (pitch 55°) không giới hạn tốc độ khung hình.
- **Đa dạng phong cách**: Vector Liberty, Dark OLED tiết kiệm pin, Ảnh Vệ tinh Hybrid, Địa hình Cao độ (Terrain).
- **Bản đồ Ngoại tuyến (Offline Maps)**: Tải trước dữ liệu các khu vực tại Việt Nam (Hà Nội, TP.HCM, Đà Nẵng, Toàn quốc).

### 5. 📸 Cảnh Báo Camera & Sự Cố Giao Thông Cộng Đồng
- Tự động quét và phát âm thanh cảnh báo khi cách camera phạt nguội / bắn tốc độ 500m.
- Đóng góp và theo dõi báo cáo thời gian thực từ cộng đồng: Tai nạn, Chốt CSGT, Thi công sửa đường, Ngập úng, Chướng ngại vật.

### 6. 🚗 Tích Hợp Apple CarPlay & Apple Watch
- **CarPlay Scene**: Kết nối màn hình trung tâm ô tô (`CPTemplateApplicationSceneDelegate`, `CPMapTemplate`), hiển thị bản đồ và tìm kiếm điểm đến trên xe.
- **Apple Watch Sync (`WatchConnectivity`)**: Đồng bộ chỉ dẫn rẽ tiếp theo, tốc độ và nhịp độ bài chạy bộ lên đồng hồ Apple Watch.

---

## 🛠️ Hướng Dẫn Mở & Chạy Trên Xcode

### Yêu Cầu Hệ Thống:
- macOS 13.5 (Ventura) hoặc macOS 14/15 (Sonoma / Sequoia).
- Xcode 15.0 trở lên.
- Thiết bị chạy iOS 16.0+ hoặc iPhone Simulator (iOS 16+).

### Cách Thực Hiện:
1. Mở thư mục dự án `d:\MagicEarthiOS` trên máy Mac của bạn.
2. Nhấp đúp vào file:
   ```
   MagicEarthiOS.xcodeproj
   ```
   *(hoặc mở thư mục `MagicEarthiOS` trực tiếp trong Xcode bằng lệnh `File -> Open`)*.
3. Xcode sẽ tự động tải thư viện **MapLibre Native** (`maplibre-gl-native-distribution`) thông qua Swift Package Manager (SPM).
4. Chọn thiết bị mục tiêu (ví dụ: `iPhone 15 Pro` hoặc thiết bị iPhone thật của bạn).
5. Nhấn phím tắt `Cmd + R` (hoặc bấm nút **Play ▶**) để Build & Run!

---

## 📁 Cấu Trúc Mã Nguồn

```
d:\MagicEarthiOS\
├── MagicEarthiOS.xcodeproj/    # File dự án Xcode chuẩn
├── Package.swift               # Cấu hình Swift Package Manager độc lập
└── MagicEarthiOS/
    ├── MagicEarthiOSApp.swift  # Điểm khởi chạy ứng dụng (AVAudioSession, Permissions)
    ├── Info.plist              # Cấu hình quyền Vị trí nền, Audio & CarPlay
    ├── Assets.xcassets/        # AppIcon & tài nguyên đồ họa
    ├── Models/
    │   ├── Models.swift                 # Structs & Enums (TransportMode, RouteResult, Step, v.v.)
    │   ├── RunningCalorieCalculator.swift# Công thức tính calo chạy bộ ACSM
    │   └── TrafficCamera.swift           # Dữ liệu camera phạt nguội Việt Nam
    ├── Services/
    │   ├── LocationManager.swift        # Quản lý GPS CoreLocation độ chính xác cao
    │   ├── RoutingEngine.swift          # OSRM đa máy chủ, Douglas-Peucker & Nắn tim đường
    │   ├── NavigationSession.swift      # Quản lý phiên dẫn đường, off-route & tự động reroute
    │   ├── VoiceGuidanceManager.swift   # Chỉ dẫn giọng nói tiếng Việt AVSpeechSynthesizer
    │   ├── LiveTrafficEngine.swift      # Quét camera gần và cảnh báo quá tốc độ
    │   ├── CommunityIncidentRepository.swift # Báo cáo sự cố cộng đồng
    │   ├── OfflineMapManager.swift      # Quản lý gói bản đồ offline
    │   └── WatchSyncManager.swift       # Đồng bộ dữ liệu sang Apple Watch
    ├── CarPlay/
    │   └── CarPlaySceneDelegate.swift   # Tích hợp Apple CarPlay cho xe ô tô
    └── Views/
        ├── MainContentView.swift            # Màn hình chính điều phối toàn bộ ứng dụng
        ├── MapLibreContainerView.swift      # UIViewRepresentable bao bọc MLNMapView & 3D buildings
        ├── RouteDrawingCanvasView.swift     # Canvas vẽ ngón tay đường chạy bộ
        ├── RunningStudioView.swift          # Khung điều khiển Studio chạy bộ
        ├── NavigationDashboardOverlay.swift # Banner rẽ, tốc độ giới hạn, ETA thời gian thực
        ├── HUDMirroredView.swift            # Giao diện HUD phản chiếu kính lái ban đêm
        └── Sheets/
            ├── MapLayersSheet.swift         # Chọn kiểu bản đồ (2D, 3D, Vệ tinh, OLED Đêm)
            ├── IncidentReportSheet.swift    # Gửi báo cáo giao thông cộng đồng
            ├── TruckConfigSheet.swift       # Thiết lập tải trọng, chiều cao xe tải
            ├── RunnerWeightSheet.swift      # Cài đặt cân nặng người chạy
            └── OfflineMapsSheet.swift       # Tải và quản lý bản đồ offline
```
