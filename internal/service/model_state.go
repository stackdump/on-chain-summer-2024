package service

import (
	"encoding/json"
	"github.com/stackdump/on-chain-summer-2024/internal/contract"
	"math/big"
	"net/http"
)

func GetContractState(net contract.ModelPetriNet) ([]int64, error) {
	contract.Connect()
	call, _ := contract.NewMetamodelCaller(contract.Address, contract.Backend())
	state := make([]int64, len(net.Places))
	for _, p := range net.Places {
		bigOffset := new(big.Int).SetInt64(int64(p.Offset))
		scalar, err := call.State(nil, bigOffset)
		if err != nil {
			return state, err
		}
		state[p.Offset] = scalar.Int64()
	}
	return state, nil
}

func StateHandler(w http.ResponseWriter, r *http.Request) {
	contract.Connect()
	call, _ := contract.NewMetamodelCaller(contract.Address, contract.Backend())
	net, _ := call.Model(nil)
	state, err := GetContractState(net)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(state)
}
