package main

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ethereum/go-ethereum/common"
	"github.com/newrelic/go-agent/v3/integrations/logcontext-v2/logWriter"
	"github.com/newrelic/go-agent/v3/newrelic"
	_ "github.com/pflow-dev/pflow-xyz/protocol/server"
	"github.com/stackdump/on-chain-summer-2024/internal/contract"
	"github.com/stackdump/on-chain-summer-2024/internal/page"
	"github.com/stackdump/on-chain-summer-2024/internal/service"
	"log"
	"net/http"
	"os"
)

func init() {
	contract.Address = common.HexToAddress("0x7f1ed3d3aac8903f869eeb32182265dc34106353")
	contract.Endpoint = os.Getenv("ENDPOINT")
	if contract.Endpoint == "" {
		contract.Endpoint = "https://base-sepolia.blastapi.io/0d1514f4-bfc2-4a18-87a1-323809684d73"
	}
}

func main() {

	username := os.Getenv("DB_USERNAME")
	password := os.Getenv("DB_PASSWORD")
	hostname := os.Getenv("DB_HOSTNAME")
	appName := os.Getenv("APP_NAME")
	configLicense, useNewRelic := os.LookupEnv("NEW_RELIC_LICENSE_KEY")

	if useNewRelic {
		service.Apm, _ = newrelic.NewApplication(
			newrelic.ConfigAppName(appName),
			newrelic.ConfigLicense(configLicense),
			newrelic.ConfigAppLogForwardingEnabled(true),
		)
		writer := logWriter.New(os.Stdout, service.Apm)
		service.Logger = log.New(writer, "", log.Default().Flags())
		service.Logger.Printf("NewRelic license set, APM enabled %s\n", appName)
	} else {
		service.Apm = nil
		service.Logger = log.Default()
		service.Logger.Print("NewRelic license not set, skipping APM, disable browser tracking\n")
	}

	if username == "" {
		log.Fatal("DB_USERNAME environment variable is not set")
	}

	if password == "" {
		log.Fatal("DB_PASSWORD environment variable is not set")
	}

	// Database connection string
	connStr := fmt.Sprintf("user=%s dbname=postgres sslmode=require password=%s host=%s", username, password, hostname)

	// Open the connection
	var err error
	service.Psql, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	run()
}

func run() {
	log.Printf("Server start on port 8080")
	ctx, cancel := context.WithCancel(context.Background())
	service.Loop(ctx)

	defer func(DB *sql.DB) {
		cancel()
		err := DB.Close()
		if err != nil {
			panic(err)
		}
	}(service.Psql)

	http.HandleFunc("/", page.IndexHandler)
	http.HandleFunc("/v0/snapshot", service.SnapshotHandler)
	http.HandleFunc("/v0/state", service.StateHandler)
	http.HandleFunc("/v0/svg", service.SvgHandler)
	http.HandleFunc("/v0/declaration", service.DeclarationHandler)
	http.HandleFunc("/v0/logs", service.LogsHandler)
	http.HandleFunc("/v0/highest_index", service.HighestIndexHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
