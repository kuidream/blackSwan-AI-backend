package dto

import (
	"time"

	"github.com/google/uuid"
)

// SuccessResponse represents a successful API response
type SuccessResponse struct {
	RequestID  string      `json:"request_id"`
	ServerTime int64       `json:"server_time"`
	Data       interface{} `json:"data"`
}

// ErrorResponse represents an error API response
type ErrorResponse struct {
	RequestID  string      `json:"request_id"`
	ServerTime int64       `json:"server_time"`
	Error      ErrorDetail `json:"error"`
}

// ErrorDetail contains error information
type ErrorDetail struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// NewSuccessResponse creates a new success response
func NewSuccessResponse(data interface{}) SuccessResponse {
	return SuccessResponse{
		RequestID:  uuid.New().String(),
		ServerTime: time.Now().Unix(),
		Data:       data,
	}
}

// NewErrorResponse creates a new error response
func NewErrorResponse(code, message string, details interface{}) ErrorResponse {
	return ErrorResponse{
		RequestID:  uuid.New().String(),
		ServerTime: time.Now().Unix(),
		Error: ErrorDetail{
			Code:    code,
			Message: message,
			Details: details,
		},
	}
}
