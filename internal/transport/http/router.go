package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// NewRouter initializes and returns a new Gin router
func NewRouter() *gin.Engine {
	router := gin.New()

	// TODO: Add middleware (logger, recovery, CORS, etc.)
	// router.Use(middleware.Logger())
	// router.Use(middleware.Recovery())
	// router.Use(middleware.CORS())

	// Health check endpoint
	router.GET("/health", healthCheck)

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
