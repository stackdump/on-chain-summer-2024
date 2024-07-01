package contract

import (
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"log"
)

var (
	client   *ethclient.Client
	err      error
	Address  common.Address
	Endpoint string
)

func Backend() bind.ContractBackend {
	return client
}

func Connect() {
	client, err = ethclient.Dial(Endpoint)
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}
}
