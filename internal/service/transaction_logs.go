package service

import (
	"encoding/json"
	"net/http"
)

type TransactionLog struct {
	TransactionHash string `json:"transaction_hash"`
	BlockNumber     int    `json:"block_number"`
	LogIndex        int    `json:"log_index"`
	FromAddress     string `json:"from_address"`
	Data            string `json:"data"`
	Removed         bool   `json:"removed"`
	TopicHash       string `json:"topic_hash"`
	Role            string `json:"role"`
	Action          string `json:"action"`
	Scalar          string `json:"scalar"`
}

func LogsHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := Psql.Query(`
  SELECT
   transaction_hash,
   block_number,
   log_index,
   from_address,
   data,
   removed,
   topic_hash,
   role,
   action,
   scalar
  FROM
   transaction_logs_view
  ORDER BY
   block_number, log_index DESC
 `)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var logs []TransactionLog
	for rows.Next() {
		var log TransactionLog
		err := rows.Scan(
			&log.TransactionHash,
			&log.BlockNumber,
			&log.LogIndex,
			&log.FromAddress,
			&log.Data,
			&log.Removed,
			&log.TopicHash,
			&log.Role,
			&log.Action,
			&log.Scalar)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		logs = append(logs, log)
	}

	if err = rows.Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	err = json.NewEncoder(w).Encode(logs)
	if err != nil {
		return
	}
}
