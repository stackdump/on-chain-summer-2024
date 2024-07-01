package service

import (
	"github.com/pflow-dev/pflow-xyz/protocol/image"
	"github.com/pflow-dev/pflow-xyz/protocol/metamodel"
	"github.com/stackdump/on-chain-summer-2024/internal/contract"
	"strconv"

	"net/http"
)

func GetModel() (contract.ModelPetriNet, error) {
	contract.Connect()
	call, _ := contract.NewMetamodelCaller(contract.Address, contract.Backend())
	return call.Model(nil)
}

func ToMetaModel(net contract.DeclarationPetriNet) metamodel.MetaModel {
	const ScaleX = 80
	const ScaleY = 80
	const Margin = 22

	mm := metamodel.New()
	pnet := mm.Net()

	for offset, p := range net.Places {
		pnet.Places[p.Label] = &metamodel.Place{
			Label:    p.Label,
			Offset:   int64(offset),
			Initial:  p.Initial.Int64(),
			Capacity: p.Initial.Int64(),
			Position: metamodel.Position{
				X: int64(p.X) * ScaleX,
				Y: int64(p.Y)*ScaleY + Margin,
			},
		}
	}
	for _, t := range net.Transitions {
		tt := &metamodel.Transition{
			Label: t.Label,
			Position: metamodel.Position{
				X: int64(t.X) * ScaleX,
				Y: int64(t.Y)*ScaleY + Margin,
			},
			Delta: make(metamodel.Vector, len(pnet.Places)),
			// FIXME support Role

		}
		pnet.Transitions[t.Label] = tt
	}
	for _, a := range net.Arcs {
		aa := metamodel.Arc{
			Source:    mm.Node(a.Source),
			Target:    mm.Node(a.Target),
			Weight:    a.Weight.Int64(),
			Inhibitor: a.Inhibit,
			Read:      a.Read,
		}
		pnet.Arcs = append(pnet.Arcs, aa)
	}

	mm.Edit().Index()
	return mm
}

func ToModelJson(mm metamodel.MetaModel) ([]byte, error) {
	model := mm.Net()
	toStr := func(int642 int64) string {
		return strconv.Itoa(int(int642))
	}
	var out string
	out += "{\n"
	out += `  "modelType": "` + model.ModelType + `",` + "\n"
	out += `  "version": "v0",` + "\n"
	// -- places --
	out += `  "places": {` + "\n"
	for label, p := range model.Places {
		placeJson := `{"initial": ` + toStr(p.Initial) + `, "capacity": ` + toStr(p.Capacity) + `, "x": ` + toStr(p.Position.X) + `, "y": ` + toStr(p.Position.Y) + `}`
		out += `    "` + label + `": ` + string(placeJson) + ",\n"
	}
	out = out[:len(out)-2] + "\n  },\n"
	// -- transitions --
	out += `  "transitions": {` + "\n"
	for label, t := range model.Transitions {
		transitionJson := `{ "x": ` + toStr(t.Position.X) + `, "y": ` + toStr(t.Position.Y) + `}`
		out += `    "` + label + `": ` + string(transitionJson) + ",\n"
	}
	out = out[:len(out)-2] + "\n  },\n"

	// -- arcs --
	out += `  "arcs": [` + "\n"
	for _, arc := range model.Arcs {
		arcJson := ""
		if arc.Source.IsPlace() {
			arcJson = `{"source": "` + arc.Source.GetPlace().Label + `", "target": "` + arc.Target.GetTransition().Label + `", "weight": ` + toStr(arc.Weight) + `}`
		} else {
			arcJson = `{"source": "` + arc.Source.GetTransition().Label + `", "target": "` + arc.Target.GetPlace().Label + `", "weight": ` + toStr(arc.Weight) + `}`
		}
		out += `    ` + string(arcJson) + ",\n"
	}
	out = out[:len(out)-2] + "\n  ]\n"
	out += "}"

	return []byte(out), nil
}

func GetDeclaration() contract.DeclarationPetriNet {
	contract.Connect()
	call, _ := contract.NewMetamodelCaller(contract.Address, contract.Backend())
	net, err := call.Declaration(nil)
	if err != nil {
		panic(err)
	}
	return net
}

func DeclarationHandler(w http.ResponseWriter, _ *http.Request) {
	mm := ToMetaModel(GetDeclaration())
	jsonData, err := ToModelJson(mm)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	} else {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(jsonData)
	}
}

func SvgHandler(w http.ResponseWriter, _ *http.Request) {
	contract.Connect()
	call, _ := contract.NewMetamodelCaller(contract.Address, contract.Backend())
	net, _ := call.Declaration(nil)
	m := ToMetaModel(net)

	w.Header().Set("Content-Type", "image/svg+xml")
	i := image.NewSvg(w)
	i.Render(m)
}
