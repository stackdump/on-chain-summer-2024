package service

import (
	"encoding/json"
	_ "github.com/lib/pq"
	"github.com/newrelic/go-agent/v3/newrelic"
	"log"
)
import "database/sql"

var Psql *sql.DB

var Apm *newrelic.Application

var Logger *log.Logger

func Event(eventType string, params map[string]interface{}) {
	if Apm != nil {
		Apm.RecordCustomEvent(eventType, params)
	}
	data, _ := json.Marshal(params)
	Logger.Printf("event %s %s\n", eventType, data)
}

func Metric(metricName string, value float64) {
	if Apm != nil {
		Apm.RecordCustomMetric(metricName, value)
	}
	Logger.Printf("metric %s %f\n", metricName, value)
}
