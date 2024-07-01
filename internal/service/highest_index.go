package service

import (
	"encoding/json"
	"net/http"
)

func HighestIndex() (int, error) {
	row := Psql.QueryRow(`SELECT max(block_number) AS highest_index FROM block_numbers`)

	var highestIndex int
	err := row.Scan(&highestIndex)
	if err != nil {
		return 0, err
	}

	return highestIndex, nil
}

func HighestIndexHandler(w http.ResponseWriter, r *http.Request) {
	highestIndex, err := HighestIndex()
	w.Header().Set("Content-Type", "application/json")
	err = json.NewEncoder(w).Encode(map[string]int{
		"highest_index": highestIndex,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
