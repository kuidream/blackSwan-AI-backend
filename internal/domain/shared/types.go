package shared

import (
	"time"

	"github.com/google/uuid"
)

// ID represents a UUID identifier
type ID = uuid.UUID

// Timestamp represents a Unix timestamp
type Timestamp int64

// NewID generates a new UUID
func NewID() ID {
	return uuid.New()
}

// Now returns current Unix timestamp
func Now() Timestamp {
	return Timestamp(time.Now().Unix())
}
