package shared

import "errors"

// Common domain errors
var (
	ErrNotFound            = errors.New("resource not found")
	ErrInvalidInput        = errors.New("invalid input")
	ErrUnauthorized        = errors.New("unauthorized")
	ErrInsufficientBalance = errors.New("insufficient balance")
	ErrInvalidPrice        = errors.New("invalid price")
	ErrSanityLow           = errors.New("sanity too low")
	ErrMarketClosed        = errors.New("market closed")
	ErrNoTimeSlot          = errors.New("no time slot available")
)
