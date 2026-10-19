package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv" // Thêm thư viện load .env
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"groupfood-backend/internal/handlers"
)

func main() {
	// Cố gắng load file .env (nếu chạy local). Dùng dấu gạch dưới để bỏ qua lỗi nếu không tìm thấy file trên Production server
	_ = godotenv.Load()

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("connect database: %v", err)
	}

	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())
	webhooks := handlers.PaymentWebhookHandler{DB: db}
	router.POST("/api/v1/webhooks/payment", webhooks.HandlePayment)

	address := os.Getenv("SERVER_ADDR")
	if address == "" {
		address = ":8080"
	}
	log.Printf("Server is starting on %s...", address)
	if err := router.Run(address); err != nil {
		log.Fatalf("run server: %v", err)
	}
}
