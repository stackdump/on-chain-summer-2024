package service

import (
	"context"
	"fmt"
	"time"
)

func Loop(ctx context.Context) {
	fmt.Println("Starting goroutine")
	ticker := time.NewTicker(30 * time.Second)

	go func() {
		for {
			select {
			case <-ticker.C:
				stats, err := GetBlockStats()
				if err != nil {
					fmt.Println("Error getting block stats:", err)
					continue
				}
				Metric("block_latest", float64(stats.Latest))
				Metric("block_highest_index", float64(stats.HighestIndex))
				Metric("block_behind", float64(stats.Behind))
				// REVIEW: consider loading un-synced blocks into a queue & preserve last seen block
			case <-ctx.Done():
				ticker.Stop()
				fmt.Println("Stopping goroutine")
				return
			}
		}
	}()
}
