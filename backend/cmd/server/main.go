package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	"groupfood-backend/internal/handlers"
)

func main() {
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
	if err := router.Run(address); err != nil {
		log.Fatalf("run server: %v", err)
	}
}
