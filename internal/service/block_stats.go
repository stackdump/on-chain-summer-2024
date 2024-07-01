package service

type BlockStats struct {
	HighestIndex int `json:"highest_index"`
	Latest       int `json:"latest"`
	Behind       int `json:"behind"`
}

func GetBlockStats() (*BlockStats, error) {
	row := Psql.QueryRow("SELECT * FROM get_block_stats();")

	var stats BlockStats
	err := row.Scan(&stats.HighestIndex, &stats.Latest, &stats.Behind)
	if err != nil {
		return nil, err
	}

	return &stats, nil
}
