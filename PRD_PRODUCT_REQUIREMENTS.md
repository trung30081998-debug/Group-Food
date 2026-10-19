# Product Requirements Document (PRD) & Software Requirements Specification (SRS)

## 1. Product Overview
- **Product Name:** GroupFood / OrderGom (Tên tạm thời)
- **Target Audience:** Dân văn phòng, sinh viên, nhóm bạn, cư dân chung cư có nhu cầu gom đơn đặt đồ ăn/thức uống chung để giảm phí vận chuyển và nhận ưu đãi.
- **Core Value Proposition:** Giúp "Host" (người chủ trì) dễ dàng tạo phiên gom đơn, tổng hợp danh sách order từ "Member" (thành viên) qua link/Web mà không bắt buộc Member phải cài app. Tự động hóa khâu tính tiền, chia tiền ship/voucher và gạch nợ qua VietQR Webhook.

---

## 2. User Roles & Key User Flows

### 2.1 Role: Host (Người tạo phiên)
- **App Context:** Mobile App (Flutter)
- **Flow:**
  1. Đăng nhập / Đăng ký (Phone Number / Google / Guest Session).
  2. Tạo phiên gom đơn (`Create Session`):
     * Nhập tên quán/thương hiệu (hoặc dán link menu/ảnh menu).
     * Đặt hạn giờ chốt đơn (Count-down Timer, ví dụ: 10:30 AM).
     * Nhập thông tin tài khoản ngân hàng nhận tiền (Tên ngân hàng, Số tài khoản, Tên chủ tài khoản) để hệ thống gen VietQR.
  3. Chia sẻ link / QR code phiên gom lên Zalo/Slack/Messenger.
  4. Theo dõi danh sách order theo thời gian thực (Realtime List qua Supabase/WebSocket).
  5. Chốt đơn & Nhập chi phí phát sinh (Tiền ship, Voucher giảm giá):
     * Hệ thống tự động tính lại tổng tiền từng Member theo công thức: 
       $$\text{Tiền Member} = \text{Tiền món} + \frac{\text{Tổng Ship} - \text{Voucher}}{\text{Số lượng Member}}$$
  6. Phát mã VietQR chuyển khoản cho từng Member.
  7. Theo dõi trạng thái thanh toán (Nhận thông báo push khi Member chuyển khoản thành công nhờ Webhook gạch nợ tự động).

### 2.2 Role: Member (Thành viên tham gia)
- **App Context:** Web App nhẹ (**Flutter Web**) - **Không cần tải App**.
- **Flow:**
  1. Nhấn vào link chia sẻ từ Host -> Mở trang gom đơn trên trình duyệt web.
  2. Nhập Tên/Biệt danh.
  3. Chọn món từ danh sách/menu do Host tạo + ghi chú (ví dụ: "50% đường, không đá").
  4. Bấm "Xác nhận Order".
  5. Màn hình hiển thị trạng thái order + Mã VietQR cá nhân hóa (kèm số tiền chính xác + nội dung chuyển khoản mã hóa).
  6. Quét mã VietQR trên App ngân hàng để thanh toán.
  7. Màn hình tự động chuyển trạng thái sang **"Đã thanh toán"** (Tích xanh realtime) mà không cần chụp ảnh màn hình chuyển khoản.

---

## 3. System Architecture & Tech Stack


```

[ Mobile App (Flutter / Clean Arch / Bloc) ] <--- REST API / WebSocket ---> [ Backend (Go / Golang) ]
|                                        ^
[ Web View Member (Flutter Web) ] ---------+                                        | Webhook
|
[ SePay / Casso / VietQR ]
|
[ Supabase (PostgreSQL / Realtime) ]

```

### 3.1 Mobile & Web Client Architecture (Flutter + Bloc/Cubit)
- **Pattern:** Clean Architecture (Tách biệt rõ ràng Data, Domain, Presentation layers).
- **State Management:** `flutter_bloc` / Cubit.
- **Folder Structure:**
  ```text
  lib/
  ├── core/                     # Common utilities, constants, network (Dio/Supabase Client), errors
  │   ├── network/
  │   ├── theme/
  │   └── utils/
  ├── features/                 # Feature-based modular structure
  │   ├── auth/                 # Domain, Data, Presentation for Auth
  │   ├── order_session/        # Create, Manage & View Order Sessions
  │   │   ├── data/
  │   │   │   ├── datasources/  # Remote (Go API / Supabase) & Local datasources
  │   │   │   ├── models/       # OrderSessionModel, OrderItemModel, MemberModel
  │   │   │   └── repositories/ # SessionRepositoryImpl
  │   │   ├── domain/
  │   │   │   ├── entities/     # Pure Dart Entities
  │   │   │   ├── repositories/ # Abstract Repository Interfaces
  │   │   │   └── usecases/     # CreateSessionUseCase, SubmitOrderUseCase
  │   │   └── presentation/
  │   │       ├── bloc/         # SessionBloc / SessionCubit, SessionState, SessionEvent
  │   │       ├── pages/        # HostSessionPage, MemberOrderPage (Flutter Web)
  │   │       └── widgets/
  │   └── payment/              # VietQR generation & payment tracking
  └── main.dart

```

### 3.2 Backend Service & Database Architecture

* **Back-end Engine (Go / Golang):**
* **Framework:** `Gin` hoặc `Fiber` cho RESTful APIs.
* **Realtime Server:** `Gorilla WebSocket` / Supabase Realtime Listener cho sự kiện gạch nợ.
* **Core Responsibilities:** Tiếp nhận Webhook thanh toán từ cổng thanh toán, verify chữ ký/xác thực giao dịch, xử lý logic phân tích cú pháp chuyển khoản, cập nhật trạng thái thanh toán và kích hoạt tín hiệu Realtime.


* **Database & Realtime (Supabase PostgreSQL):**
* Lưu trữ dữ liệu hệ thống (`users`, `order_sessions`, `session_members`, `order_items`).
* Tận dụng **Supabase Realtime Subscription** để đồng bộ tự động dữ liệu danh sách order và trạng thái tích xanh "Đã thanh toán" giữa Host App và Web Member.



---

## 4. VietQR Integration & Webhook Flow

1. **Sinh Mã QR:**
Sử dụng định dạng VietQR chuẩn Napas247 hoặc API:
`https://img.vietqr.io/image/{BANK_ID}-{ACCOUNT_NO}-{TEMPLATE}.png?amount={AMOUNT}&addInfo={TRANSFER_CONTENT}`
* `TRANSFER_CONTENT`: Định dạng bắt buộc `GOM [SESSION_ID] [MEMBER_ID]` (Ví dụ: `GOM S102 M5`).


2. **Luồng Webhook Gạch Nợ Tự Động:**
* Ngân hàng của Host nhận được tiền gửi kèm nội dung chuyển khoản.
* Dịch vụ trung gian (SePay / Casso) bắt biến động số dư và gửi HTTP POST Webhook về Server Go.
* Server Go phân tích nội dung chuyển khoản -> Trích xuất `SESSION_ID` và `MEMBER_ID`.
* Cập nhật cơ sở dữ liệu trên Supabase: `session_members.is_paid = true`.
* Phát sự kiện Realtime (Supabase Realtime / WebSocket) xuống Mobile App của Host và Flutter Web Client của Member để tự động đổi giao diện thành **Tích xanh "Đã thanh toán"**.
```