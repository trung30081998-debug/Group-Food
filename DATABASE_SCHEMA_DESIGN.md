# Database Schema & Architecture Design

Tài liệu thiết kế cơ sở dữ liệu chuẩn PostgreSQL (tương thích Supabase & Go GORM).

## 1. Entity Relationship Diagram (ERD) Text Representation

```text
[USERS] 1 --- * [SESSIONS] 1 --- * [SESSION_MEMBERS] 1 --- * [MEMBER_ITEMS]
    |                                   |
    | 1                                 | 1
    *                                   *
[TRANSACTIONS] <------------------ [SESSION_MEMBERS] (Linked via Foreign Key)

```

---

## 2. SQL DDL Schema (PostgreSQL / Supabase)

```sql
-- Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: USERS (Host Info)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    bank_code VARCHAR(20),          -- VD: 'VCB', 'MB', 'TCB'
    bank_account_no VARCHAR(50),    -- Số tài khoản
    bank_account_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: SESSIONS (Phiên gom đơn)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,    -- VD: "Trà sữa GongCha công ty"
    merchant_name VARCHAR(255),
    menu_image_url TEXT,
    deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'OPEN', -- 'OPEN', 'LOCKED', 'COMPLETED', 'CANCELLED'
    shipping_fee DECIMAL(12, 2) DEFAULT 0,
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: SESSION_MEMBERS (Thành viên tham gia phiên)
CREATE TABLE session_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    member_name VARCHAR(100) NOT NULL,
    member_phone VARCHAR(20),
    total_amount DECIMAL(12, 2) DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'PAID', 'FAILED'
    transfer_code VARCHAR(50) UNIQUE NOT NULL,    -- VD: 'GOM_S102_M05'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: MEMBER_ITEMS (Chi tiết món được chọn bởi thành viên)
CREATE TABLE member_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_member_id UUID NOT NULL REFERENCES session_members(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12, 2) NOT NULL,
    note VARCHAR(255), -- "50% đường, 100% đá"
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table: TRANSACTIONS (Nhật ký Webhook thanh toán từ Bank Gateway)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_member_id UUID REFERENCES session_members(id) ON DELETE SET NULL,
    gateway_transaction_id VARCHAR(100), -- ID giao dịch từ SePay/Casso/Bank
    amount_transferred DECIMAL(12, 2) NOT NULL,
    transfer_content TEXT NOT NULL,
    raw_payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance optimization
CREATE INDEX idx_sessions_host ON sessions(host_id);
CREATE INDEX idx_members_session ON session_members(session_id);
CREATE INDEX idx_members_transfer_code ON session_members(transfer_code);
CREATE INDEX idx_transactions_member ON transactions(session_member_id);

```

---

## 3. Webhook Payload Processing Specification (Go Backend & Supabase Realtime)

### 3.1 Webhook Request Sample (Dạng JSON nhận từ SePay / Casso):

```json
{
  "id": 123456,
  "gateway": "MBBank",
  "transactionDate": "2026-10-19 10:15:00",
  "accountNumber": "0123456789",
  "code": null,
  "content": "GOM S102 M05 chuyen tien tra sua",
  "transferType": "in",
  "transferAmount": 45000,
  "accumulated": 5045000
}

```

### 3.2 Logic xử lý Backend (Go Service Algorithm):

1. **Nhận HTTP POST Request** tại Endpoint `/api/v1/webhooks/payment`.
2. **Xác thực Gateway** (Kiểm tra token bảo mật / API Key từ SePay/Casso).
3. **Lọc điều kiện:** Kiểm tra `transferType == "in"`.
4. **Trích xuất mã chuyển khoản:** Dùng Regex quét trong trường `content` để tìm pattern `GOM_[SESSION_ID]_[MEMBER_ID]` hoặc `transfer_code` tương ứng.
5. **Truy vấn Database:** Tìm bản ghi trong bảng `session_members` qua `transfer_code`.
6. **Đối soát & Cập nhật:**
* Nếu `transferAmount >= session_members.total_amount`:
* Cập nhật `session_members.payment_status = 'PAID'`.
* Lưu bản ghi vào bảng `transactions` (ghi nhận `raw_payload`).
* Kích hoạt **Supabase Realtime Channel** (`session_channel_{session_id}`) đẩy payload `{ member_id: "...", status: "PAID" }` xuống Mobile App (Host) và Flutter Web Client (Member) để tự động đổi giao diện sang tích xanh.




7. **Phản hồi:** Trả về HTTP `200 OK` cho Gateway để xác nhận đã xử lý thành công.
```