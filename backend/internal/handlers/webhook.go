package handlers

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"groupfood-backend/internal/models"
)

var transferCodePattern = regexp.MustCompile(`(?i)\bGOM[_\s-]+([A-Z0-9]+)[_\s-]+([A-Z0-9]+)\b`)

type PaymentWebhookHandler struct{ DB *gorm.DB }

type paymentWebhookPayload struct {
	ID             json.RawMessage `json:"id"`
	Content        string          `json:"content"`
	TransferType   string          `json:"transferType"`
	TransferAmount float64         `json:"transferAmount"`
}

func (h PaymentWebhookHandler) HandlePayment(c *gin.Context) {
	var rawPayload json.RawMessage
	if err := c.ShouldBindJSON(&rawPayload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid webhook payload"})
		return
	}
	var payload paymentWebhookPayload
	if err := json.Unmarshal(rawPayload, &payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid webhook payload"})
		return
	}

	// Acknowledge outgoing and other non-credit notifications without mutation.
	if !strings.EqualFold(payload.TransferType, "in") {
		c.JSON(http.StatusOK, gin.H{"status": "ignored"})
		return
	}

	matches := transferCodePattern.FindStringSubmatch(strings.ToUpper(payload.Content))
	if len(matches) != 3 {
		c.JSON(http.StatusOK, gin.H{"status": "ignored", "reason": "transfer code not found"})
		return
	}
	transferCode := fmt.Sprintf("GOM_%s_%s", matches[1], matches[2])
	var member models.SessionMember
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).Where("transfer_code = ?", transferCode).First(&member).Error; err != nil {
			return err
		}

		gatewayID := rawMessageString(payload.ID)
		transaction := models.Transaction{
			SessionMemberID:      &member.ID,
			GatewayTransactionID: gatewayID,
			AmountTransferred:    payload.TransferAmount,
			TransferContent:      payload.Content,
			RawPayload:           datatypes.JSON(rawPayload),
		}
		if err := tx.Create(&transaction).Error; err != nil {
			return err
		}
		if payload.TransferAmount >= member.TotalAmount && member.PaymentStatus != "PAID" {
			return tx.Model(&member).Update("payment_status", "PAID").Error
		}
		return nil
	})
	if errors.Is(err, gorm.ErrRecordNotFound) {
		c.JSON(http.StatusOK, gin.H{"status": "ignored", "reason": "session member not found"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not process payment"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "processed", "transfer_code": transferCode})
}

func rawMessageString(value json.RawMessage) *string {
	if len(value) == 0 || string(value) == "null" {
		return nil
	}
	var result string
	if json.Unmarshal(value, &result) != nil {
		result = string(value)
	}
	return &result
}
