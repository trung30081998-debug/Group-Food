# Step-by-Step Development & Play Store Release Plan

Tài liệu này được tối ưu hóa cho AI Coding Agent (Code X, Cursor, Copilot) thực thi trực tiếp trong Visual Studio Code.

---

## Phase 1: Environment & Project Setup (Tuần 1 - Ngày 1-2)

### Tasks cho AI Agent:
1. Tạo dự án Flutter Cross-Platform:
   ```bash
   flutter create --org com.yourdomain.groupfood --template=app group_food_app

```

2. Thêm các thư viện chính vào `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  get_it: ^7.6.0
  injectable: ^2.3.2
  supabase_flutter: ^2.3.0
  dio: ^5.4.0
  qr_flutter: ^4.1.0
  url_launcher: ^6.2.5
  google_fonts: ^6.1.0
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.8
  injectable_generator: ^2.4.1

```


3. Khởi tạo cấu trúc thư mục Clean Architecture chuẩn cho Flutter:
```text
lib/
├── core/                  # Core utilities, network clients, errors, design system
├── features/
│   ├── auth/
│   ├── order_session/     # Data, Domain, Presentation (Bloc/Cubit)
│   └── payment/
└── main.dart

```



---

## Phase 2: Core Feature Implementation (Tuần 1 - Tuần 3)

### Milestone 1: Domain & Data Layer (Clean Architecture)

* [ ] Định nghĩa pure Dart Entities (`OrderSession`, `SessionMember`, `MemberItem`).
* [ ] Định nghĩa abstract Repositories interfaces trong Domain Layer.
* [ ] Dựng Data Models (`SessionModel`, `MemberModel`) kế thừa từ Entities kèm hàm `fromJson` / `toJson`.
* [ ] Viết Repositories implementation kết nối với Supabase & Go Backend API via Dio/Supabase Client.

### Milestone 2: Go Backend Service & Webhook Handler

* [ ] Dựng RESTful API Endpoints bằng Go (Gin/Fiber) để tiếp nhận yêu cầu từ Flutter Client.
* [ ] Viết Webhook Controller xử lý payload từ SePay/Casso: phân tích regex mã chuyển khoản, gạch nợ `payment_status = 'PAID'` trong PostgreSQL.
* [ ] Bắn tín hiệu Realtime qua Supabase Realtime / WebSocket channel.

### Milestone 3: Presentation Layer - Host UI (Flutter App + Bloc/Cubit)

* [ ] Cấu hình Dependency Injection (`get_it` & `injectable`).
* [ ] Màn hình Home: `SessionListBloc` hiển thị danh sách các phiên gom đơn.
* [ ] Màn hình Create Session: Form tạo phiên, đặt thời gian đếm ngược, cấu hình tài khoản ngân hàng nhận VietQR.
* [ ] Màn hình Session Dashboard: Hiển thị danh sách món ăn realtime và trạng thái thanh toán.

### Milestone 4: Presentation Layer - Member UI (Flutter Web)

* [ ] Đảm bảo ứng dụng hỗ trợ build Web responsive: `flutter build web`.
* [ ] Route `/session/:id` thiết kế tối giản, tối ưu riêng cho trình duyệt di động (Mobile Browser).
* [ ] Component sinh mã **VietQR** tự động dạng URL Image Generator kèm nội dung `GOM_[SESSION_ID]_[MEMBER_ID]`.

### Milestone 5: Realtime State Synchronization

* [ ] Cấu hình Listener lắng nghe sự kiện thay đổi dữ liệu trên Flutter Client qua `flutter_bloc`:
```dart
supabase.from('session_members')
  .stream(primaryKey: ['id'])
  .eq('session_id', currentSessionId)
  .listen((data) {
      // Emit event/state mới tới SessionBloc/SessionCubit để update UI live status
      context.read<SessionCubit>().onPaymentUpdated(data);
  });

```



---

## Phase 3: Android Build & Play Store Compliance Setup (Tuần 4)

### Tasks kỹ thuật Android:

1. **Tạo Keystore để Sign App:**
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

```


2. **Cấu hình `android/key.properties` và `android/app/build.gradle`:**
* Cập nhật `applicationId`: `com.yourdomain.groupfood`
* Bật `minifyEnabled true` và `shrinkResources true` để tối ưu dung lượng app.


3. **Thêm cấp quyền Android Manifest (`android/app/src/main/AndroidManifest.xml`):**
* Internet permission (Bắt buộc): `<uses-permission android:name="android.permission.INTERNET"/>`



---

## Phase 4: CH Play Release Workflow (Google Play Console)

### Step 1: Chuẩn bị tài sản truyền thông (Media Assets)

* **App Icon:** 512x512 px (PNG 32-bit).
* **Feature Graphic:** 1024x500 px (JPEG/PNG).
* **Phone Screenshots:** Tối thiểu 4 ảnh chụp màn hình kích thước 1080x1920 px (Hiển thị các luồng: Tạo đơn, Chọn món, Mã VietQR, Trạng thái gạch nợ tích xanh).

### Step 2: Cấu hình bắt buộc trên Play Console

1. **Privacy Policy Page:** Đưa file Privacy Policy đơn giản lên GitHub Pages / Notion / Supabase Storage và dán URL vào Google Play Console.
2. **App Content Questionnaire:**
* Khai báo độ tuổi phù hợp (Target Age): 13+ hoặc 18+.
* Khai báo Data Safety: Ứng dụng thu thập Tên/Số điện thoại để phục vụ tính năng đơn hàng (Không chia sẻ cho bên thứ 3).



### Step 3: Quy trình Closed Testing 14 ngày (Bắt buộc cho tài khoản cá nhân mới)

1. Export file Android App Bundle:
```bash
flutter build aab --release

```


2. Upload file `.aab` lên luồng **Closed Testing (Thử nghiệm đóng)**.
3. Thêm danh sách Email của 20 Testers.
4. Duy trì trạng thái dùng thử liên tục trong **14 ngày**.
5. Gửi đơn đăng ký phát hành lên **Production Store**.

---

## Direct Prompts cho AI Code Agent trong VS Code (Code X / Cursor)

Bạn có thể copy trực tiếp các câu lệnh sau cho Code X để triển khai từng bước:

### Prompt 1: Khởi tạo Clean Architecture Boilerplate

> *"Hãy đọc file PRD_PRODUCT_REQUIREMENTS.md và DATABASE_SCHEMA_DESIGN.md. Tiến hành khởi tạo cấu trúc thư mục Clean Architecture chuẩn cho Flutter (Sử dụng flutter_bloc và get_it). Tạo các Pure Dart Entities (`OrderSession`, `SessionMember`, `MemberItem`) trong tầng Domain Layer."*

### Prompt 2: Xây dựng Data Models & Supabase Repositories

> *"Dựa trên file DATABASE_SCHEMA_DESIGN.md, hãy viết các Data Models (`SessionModel`, `MemberModel`) có hàm `fromJson`, `toJson` và `toEntity`. Sau đó viết `SessionRepositoryImpl` kế thừa từ `SessionRepository` interface để kết nối CRUD dữ liệu với Supabase."*

### Prompt 3: Lập trình Bloc/Cubit & Presentation Layer

> *"Hãy viết `SessionCubit` và `SessionState` quản lý trạng thái của phiên gom đơn. Tạo màn hình `HostSessionPage` hiển thị danh sách món ăn realtime và tích xanh 'Đã thanh toán' khi nhận được signal từ Supabase Realtime Stream."*

### Prompt 4: Viết Go Backend Webhook Handler

> *"Hãy đọc phần Webhook Specification trong file DATABASE_SCHEMA_DESIGN.md và viết một HTTP Webhook Handler bằng Go (Gin framework) để bắt POST request từ SePay. Trích xuất regex nội dung chuyển khoản pattern `GOM_[SESSION_ID]_[MEMBER_ID]`, cập nhật database PostgreSQL và trả về HTTP 200 OK."*

```