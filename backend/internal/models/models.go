package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

// User is a host account and maps to the users table.
type User struct {
	ID              uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	PhoneNumber     *string   `gorm:"size:20;uniqueIndex" json:"phone_number,omitempty"`
	FullName        string    `gorm:"size:100;not null" json:"full_name"`
	BankCode        *string   `gorm:"size:20" json:"bank_code,omitempty"`
	BankAccountNo   *string   `gorm:"size:50" json:"bank_account_no,omitempty"`
	BankAccountName *string   `gorm:"size:100" json:"bank_account_name,omitempty"`
	CreatedAt       time.Time `gorm:"not null;default:current_timestamp" json:"created_at"`
	Sessions        []Session `gorm:"foreignKey:HostID" json:"-"`
}

type Session struct {
	ID             uuid.UUID       `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	HostID         uuid.UUID       `gorm:"type:uuid;not null;index:idx_sessions_host" json:"host_id"`
	Host           User            `gorm:"constraint:OnDelete:CASCADE" json:"-"`
	Title          string          `gorm:"size:255;not null" json:"title"`
	MerchantName   *string         `gorm:"size:255" json:"merchant_name,omitempty"`
	MenuImageURL   *string         `gorm:"type:text" json:"menu_image_url,omitempty"`
	Deadline       time.Time       `gorm:"not null" json:"deadline"`
	Status         string          `gorm:"size:20;not null;default:OPEN" json:"status"`
	ShippingFee    float64         `gorm:"type:numeric(12,2);not null;default:0" json:"shipping_fee"`
	DiscountAmount float64         `gorm:"type:numeric(12,2);not null;default:0" json:"discount_amount"`
	CreatedAt      time.Time       `gorm:"not null;default:current_timestamp" json:"created_at"`
	Members        []SessionMember `gorm:"foreignKey:SessionID" json:"-"`
}

type SessionMember struct {
	ID            uuid.UUID     `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	SessionID     uuid.UUID     `gorm:"type:uuid;not null;index:idx_members_session" json:"session_id"`
	Session       Session       `gorm:"constraint:OnDelete:CASCADE" json:"-"`
	MemberName    string        `gorm:"size:100;not null" json:"member_name"`
	MemberPhone   *string       `gorm:"size:20" json:"member_phone,omitempty"`
	TotalAmount   float64       `gorm:"type:numeric(12,2);not null;default:0" json:"total_amount"`
	PaymentStatus string        `gorm:"size:20;not null;default:PENDING" json:"payment_status"`
	TransferCode  string        `gorm:"size:50;not null;uniqueIndex:idx_members_transfer_code" json:"transfer_code"`
	CreatedAt     time.Time     `gorm:"not null;default:current_timestamp" json:"created_at"`
	Items         []MemberItem  `gorm:"foreignKey:SessionMemberID" json:"-"`
	Transactions  []Transaction `gorm:"foreignKey:SessionMemberID" json:"-"`
}

type MemberItem struct {
	ID              uuid.UUID     `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	SessionMemberID uuid.UUID     `gorm:"type:uuid;not null" json:"session_member_id"`
	SessionMember   SessionMember `gorm:"constraint:OnDelete:CASCADE" json:"-"`
	ItemName        string        `gorm:"size:255;not null" json:"item_name"`
	Quantity        int           `gorm:"not null;default:1" json:"quantity"`
	UnitPrice       float64       `gorm:"type:numeric(12,2);not null" json:"unit_price"`
	Note            *string       `gorm:"size:255" json:"note,omitempty"`
	CreatedAt       time.Time     `gorm:"not null;default:current_timestamp" json:"created_at"`
}

type Transaction struct {
	ID                   uuid.UUID      `gorm:"type:uuid;default:uuid_generate_v4();primaryKey" json:"id"`
	SessionMemberID      *uuid.UUID     `gorm:"type:uuid;index:idx_transactions_member" json:"session_member_id,omitempty"`
	SessionMember        *SessionMember `gorm:"constraint:OnDelete:SET NULL" json:"-"`
	GatewayTransactionID *string        `gorm:"size:100" json:"gateway_transaction_id,omitempty"`
	AmountTransferred    float64        `gorm:"type:numeric(12,2);not null" json:"amount_transferred"`
	TransferContent      string         `gorm:"type:text;not null" json:"transfer_content"`
	RawPayload           datatypes.JSON `gorm:"type:jsonb" json:"raw_payload"`
	CreatedAt            time.Time      `gorm:"not null;default:current_timestamp" json:"created_at"`
}
