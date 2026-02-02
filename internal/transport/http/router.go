package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// NewRouter initializes and returns a new Gin router
func NewRouter() *gin.Engine {
	router := gin.New()

	// Middleware
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(corsMiddleware())

	// Health check endpoint
	router.GET("/health", healthCheck)
	
	// Serve test page
	router.StaticFile("/test", "./web/api-test.html")

	// API v1 routes
	v1 := router.Group("/v1")
	{
		// TODO: Add route groups
		// auth := v1.Group("/auth")
		// {
		//     auth.POST("/login", handler.Login)
		// }
		
		v1.GET("/ping", ping)
	}

	return router
}

// healthCheck returns service health status
func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"service": "blackSwan-backend",
	})
}

// ping is a simple test endpoint
func ping(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "pong",
	})
}

// corsMiddleware adds CORS headers for local development
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, Idempotency-Key")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		
		c.Next()
	}
}
