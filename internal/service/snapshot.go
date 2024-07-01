package service

import (
	"github.com/pflow-dev/pflow-xyz/protocol/metamodel"
	"github.com/stackdump/on-chain-summer-2024/internal/contract"
	"net/http"
	"strconv"
	"strings"
)

func NewSnapshot() *Snapshot {
	s := new(Snapshot)
	var err error
	s.Declaration = GetDeclaration()
	s.Model, err = GetModel()
	if err != nil {
		panic(err)
	}

	s.State, err = GetContractState(s.Model)
	if err != nil {
		panic(err)
	}

	s.Actions = make([]string, len(s.Model.Transitions))
	for _, mt := range s.Model.Transitions {
		s.Actions[mt.Offset] = mt.Label
	}

	s.BlockStats, err = GetBlockStats()

	return s
}

type Snapshot struct {
	Declaration contract.DeclarationPetriNet `json:"declaration"`
	Model       contract.ModelPetriNet       `json:"model"`
	State       []int64                      `json:"state"`
	Actions     []string                     `json:"actions"`
	BlockStats  *BlockStats                  `json:"block_stats"`
}

func (s *Snapshot) ToMetaModel() metamodel.MetaModel {
	return ToMetaModel(s.Declaration)
}

func (s *Snapshot) ToJson() []byte {
	// -- model --
	modelJson, _ := ToModelJson(s.ToMetaModel())
	out := strings.TrimSuffix(string(modelJson), "\n}") + ",\n"

	// -- state --
	out += "  \"state\": {\n"
	for offset, state := range s.State {
		out += "    \"" + s.Model.Places[offset].Label + "\": " + strconv.Itoa(int(state)) + ",\n"
	}
	out = strings.TrimSuffix(out, ",\n") + "\n  },\n"

	// -- actions --
	out += "  \"actions\": {\n"
	for offset, action := range s.Actions {
		out += "    \"" + action + "\": " + strconv.Itoa(offset) + ",\n"
	}
	out = strings.TrimSuffix(out, ",\n") + "\n  },\n"

	// -- contract --
	out += "  \"address\": \"" + contract.Address.String() + "\",\n"

	// -- block_stats --
	block_stats, _ := GetBlockStats()
	out += "  \"block_stats\": {\"highest_index\": " + strconv.Itoa(block_stats.HighestIndex) + ", \"latest\": " + strconv.Itoa(block_stats.Latest) + ", \"behind\": " + strconv.Itoa(block_stats.Behind) + "}\n"

	out += "}\n"
	return []byte(out)
}

func SnapshotHandler(w http.ResponseWriter, _ *http.Request) {
	s := NewSnapshot()
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(s.ToJson())
}
