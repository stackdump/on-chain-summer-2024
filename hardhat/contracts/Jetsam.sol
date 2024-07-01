// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPflowDSL {
    function vectorSize() external view returns (uint8);
    function place(uint8 index) external view returns (Model.Place memory);
    function transition(uint8 index) external view returns (Model.Transition memory);
    function arc(uint8 index) external view returns (Model.Arc memory);
    function getPlaces() external view returns (Model.Place[] memory);
    function getTransitions() external view returns (Model.Transition[] memory);
    function getArcs() external view returns (Model.Arc[] memory);
    function cell(string memory label, uint8 initial, uint8 capacity, Model.Position memory position) external returns (Model.Place memory);
    function func(string memory label, uint8 vectorLen, uint8 action, uint8 role, Model.Position memory position) external returns (Model.Transition memory);
    function arrow(int8 weight, Model.Place memory p, Model.Transition memory t) external;
    function arrow(int8 weight, Model.Transition memory t, Model.Place memory p) external;
    function guard(int8 weight, Model.Place memory p, Model.Transition memory t) external;
    function guard(int8 weight, Model.Transition memory t, Model.Place memory p) external;
}

library Declaration {

   struct place {
       string label;
       uint8 x;
       uint8 y;
       uint8 initial;
       uint8 capacity;
   }

   struct transition {
       string label;
       uint8 x;
       uint8 y;
       uint8 role;
   }

   struct arc {
       string source;
       string target;
       uint8 weight;
       bool consume;
       bool produce;
       bool inhibit;
       bool read;
   }

   struct PetriNet {
       place[] places;
       transition[] transitions;
       arc[] arcs;
   }

}

library Model {

    event SignaledEvent(
        uint8 indexed role,
        uint8 indexed actionId,
        uint8 indexed scalar
    );

    struct PetriNet {
        Place[] places;
        Transition[] transitions;
        Arc[] arcs;
    }

    struct Position {
        uint8 x;
        uint8 y;
    }

    struct Transition {
        string label;
        uint8 offset;
        Position position;
        uint8 role;
        int8[] delta;
        int8[] guard;
    }

    struct Place {
        string label;
        uint8 offset;
        Position position;
        uint8 initial;
        uint8 capacity;
    }

    enum NodeKind {
        PLACE,
        TRANSITION
    }

    struct Node {
        string label;
        uint8 offset;
        NodeKind kind;
    }

    struct Arc {
        uint8 weight;
        Node source;
        Node target;
        bool inhibitor;
        bool read;
    }

    function toDeclaration(IPflowDSL pflow) public view returns (Declaration.PetriNet memory) {
        Declaration.place[] memory p = new Declaration.place[](pflow.vectorSize());
        for (uint8 i = 0; i < uint8(pflow.vectorSize()); i++) {
            p[i] = Declaration.place(pflow.place(i).label, pflow.place(i).position.x, pflow.place(i).position.y, pflow.place(i).initial, pflow.place(i).capacity);
        }
        Declaration.transition[] memory t = new Declaration.transition[](pflow.getTransitions().length);
        for (uint8 i = 0; i < uint8(pflow.getTransitions().length); i++) {
            t[i] = Declaration.transition(pflow.transition(i).label, pflow.transition(i).position.x, pflow.transition(i).position.y, pflow.transition(i).role);
        }
        Declaration.arc[] memory a = new Declaration.arc[](pflow.getArcs().length);
        for (uint8 i = 0; i < uint8(pflow.getArcs().length); i++) {
            assert(pflow.arc(i).source.kind != pflow.arc(i).target.kind);
            a[i] = Declaration.arc(
                pflow.arc(i).source.label,
                pflow.arc(i).target.label,
                pflow.arc(i).weight,
                pflow.arc(i).source.kind == Model.NodeKind.PLACE, // consume
                pflow.arc(i).target.kind == Model.NodeKind.PLACE, // produce
                pflow.arc(i).inhibitor,
                pflow.arc(i).read
            );
        }
        return Declaration.PetriNet(p, t, a);
    }

}

interface ModelInterface {
    function model() external returns (Model.PetriNet memory);

    function declaration() external returns (Declaration.PetriNet memory);

    function signal(uint8 action, uint8 scalar) external;

    function signalMany(uint8[] calldata actions, uint8[] calldata scalars) external;
}


contract PflowDSL is IPflowDSL {
    Model.Place[] public places;
    Model.Transition[] public transitions;
    Model.Arc[] public arcs;

    function vectorSize() external view returns (uint8) {
        return uint8(places.length);
    }

    function place(uint8 index) external view returns (Model.Place memory) {
        return places[index];
    }

    function transition(uint8 index) external view returns (Model.Transition memory) {
        return transitions[index];
    }

    function arc(uint8 index) external view returns (Model.Arc memory) {
        return arcs[index];
    }

    function getPlaces() external view returns (Model.Place[] memory) {
        return places;
    }

    function getTransitions() external view returns (Model.Transition[] memory) {
        return transitions;
    }

    function getArcs() external view returns (Model.Arc[] memory) {
        return arcs;
    }

    function placeNode(string memory label, uint8 offset) internal pure returns (Model.Node memory) {
        return Model.Node(label, offset, Model.NodeKind.PLACE);
    }

    function transitionNode(string memory label, uint8 offset) internal pure returns (Model.Node memory) {
        return Model.Node(label, offset, Model.NodeKind.TRANSITION);
    }

    function cell(string memory label, uint8 initial, uint8 capacity, Model.Position memory position) external returns (Model.Place memory) {
        Model.Place memory p = Model.Place(label, uint8(places.length), position, initial, capacity);
        places.push(p);
        return p;
    }

    function func(string memory label, uint8 vectorLen, uint8 action, uint8 role, Model.Position memory position) external returns (Model.Transition memory) {
        require(uint8(transitions.length) == action, "transactions must be declared in enum order");
        Model.Transition memory t = Model.Transition(label, action, position, role, new int8[](vectorLen), new int8[](vectorLen));
        transitions.push(t);
        return t;
    }

    function arrow(int8 weight, Model.Place memory p, Model.Transition memory t) external {
        require(weight > 0, "weight must be > 0");
        arcs.push(Model.Arc(uint8(weight), placeNode(p.label, p.offset), transitionNode(t.label, t.offset), false, false));
        transitions[t.offset].delta[p.offset] = 0 - weight;
    }

    function arrow(int8 weight, Model.Transition memory t, Model.Place memory p) external {
        require(weight > 0, "weight must be > 0");
        arcs.push(Model.Arc(uint8(weight), transitionNode(t.label, t.offset), placeNode(p.label, p.offset), false, false));
        transitions[t.offset].delta[p.offset] = weight;
    }

    // inhibit transition after threshold weight is reached
    function guard(int8 weight, Model.Place memory p, Model.Transition memory t) external {
        require(weight > 0, "weight must be > 0");
        arcs.push(Model.Arc(uint8(weight), placeNode(p.label, p.offset), transitionNode(t.label, t.offset), true, false));
        transitions[t.offset].guard[p.offset] = 0 - weight;
    }

    // inhibit transition until threshold weight is reached
    function guard(int8 weight, Model.Transition memory t, Model.Place memory p) external {
        require(weight > 0, "weight must be > 0");
        arcs.push(Model.Arc(uint8(weight), transitionNode(t.label, t.offset), placeNode(p.label, p.offset), true, true));
        transitions[t.offset].guard[p.offset] = weight;
    }
}

contract ModelInstance {
    IPflowDSL internal pflow;

    constructor(IPflowDSL _pflow) {
        pflow = _pflow;
    }

}

library ModelEnums {
    enum Roles {DEFAULT, HALT}
    enum Properties {oxygen, hydrogen, kudzu, spider, feathers, cola, balloon, _string, lighter, reactor, silk, propane, helium, water, mentos, balloon_on_string, basket, rope, candle, wax, wings, twine, SIZE}
    enum Actions { make_hot_air_baloon, become_spiderman, breathe_o2, burn_candle, cola_jetpack, crack_helium, crack_water, craft_water, craft_wings, drink_cola, eat_kudzu, eat_mentos, explode_hydrogen, explode_propane, get_balloon, get_bird, get_candle, get_cola_bottle, get_helium_tank, get_hydrogen_tank, get_kudzu, get_lighter, get_mentos, get_oxygen_tank, get_propane_tank, get_reactor, get_spider, get_string, get_water_bottle, jet_pack, make_baloon_on_string, make_basket, make_helium_balloon, make_hydrogen_balloon, make_oxygen_balloon, make_parashute, make_pillow, make_propane_balloon, make_rope, make_spider_silk, make_steam_jetpack, make_string, make_twine, make_twine_rope, make_wax, make_webshooter, stunt_plane, HALT}
}

library ModelPlaces {
    function _places(IPflowDSL pflow) public {
        pflow.cell("oxygen", 0, 0, Model.Position(7, 4));
        pflow.cell("hydrogen", 0, 0, Model.Position(8, 3));
        pflow.cell("kudzu", 0, 0, Model.Position(10, 3));
        pflow.cell("spider", 0, 0, Model.Position(3, 4));
        pflow.cell("feathers", 0, 0, Model.Position(11, 3));
        pflow.cell("cola", 0, 0, Model.Position(18, 13));
        pflow.cell("balloon", 0, 0, Model.Position(4, 4));
        pflow.cell("string", 0, 0, Model.Position(13, 3));
        pflow.cell("lighter", 0, 0, Model.Position(16, 3));
        pflow.cell("reactor", 0, 0, Model.Position(0, 7));
        pflow.cell("silk", 0, 0, Model.Position(4, 10));
        pflow.cell("propane", 0, 0, Model.Position(5, 3));
        pflow.cell("helium", 0, 0, Model.Position(6, 4));
        pflow.cell("water", 0, 0, Model.Position(7, 9));
        pflow.cell("mentos", 0, 0, Model.Position(18, 8));
        pflow.cell("balloon_on_string", 0, 0, Model.Position(5, 12));
        pflow.cell("basket", 0, 0, Model.Position(10, 7));
        pflow.cell("rope", 0, 0, Model.Position(15, 7));
        pflow.cell("candle", 0, 0, Model.Position(14, 3));
        pflow.cell("wax", 0, 0, Model.Position(17, 7));
        pflow.cell("wings", 0, 0, Model.Position(14, 11));
        pflow.cell("twine", 0, 0, Model.Position(12, 10));
    }
}

library ModelTransitions {
    // REVIEW: define the transitions
    enum Properties {oxygen, hydrogen, kudzu, spider, feathers, cola, balloon, _string, lighter, reactor, silk, propane, helium, water, mentos, balloon_on_string, basket, rope, candle, wax, wings, twine, SIZE}
    function _transitions(IPflowDSL pflow) public {
        pflow.func("make_hot_air_baloon", uint8(Properties.SIZE), uint8(0), uint8(0), Model.Position(12, 14));
        pflow.func("become_spiderman", uint8(Properties.SIZE), uint8(1), uint8(0), Model.Position(2, 13));
        pflow.func("breathe_o2", uint8(Properties.SIZE), uint8(2), uint8(0), Model.Position(20, 5));
        pflow.func("burn_candle", uint8(Properties.SIZE), uint8(3), uint8(0), Model.Position(16, 6));
        pflow.func("cola_jetpack", uint8(Properties.SIZE), uint8(4), uint8(0), Model.Position(16, 11));
        pflow.func("crack_helium", uint8(Properties.SIZE), uint8(5), uint8(0), Model.Position(1, 12));
        pflow.func("crack_water", uint8(Properties.SIZE), uint8(6), uint8(0), Model.Position(0, 10));
        pflow.func("craft_water", uint8(Properties.SIZE), uint8(7), uint8(0), Model.Position(7, 6));
        pflow.func("craft_wings", uint8(Properties.SIZE), uint8(8), uint8(0), Model.Position(15, 9));
        pflow.func("drink_cola", uint8(Properties.SIZE), uint8(9), uint8(0), Model.Position(21, 9));
        pflow.func("eat_kudzu", uint8(Properties.SIZE), uint8(10), uint8(0), Model.Position(20, 6));
        pflow.func("eat_mentos", uint8(Properties.SIZE), uint8(11), uint8(0), Model.Position(20, 7));
        pflow.func("explode_hydrogen", uint8(Properties.SIZE), uint8(12), uint8(0), Model.Position(19, 3));
        pflow.func("explode_propane", uint8(Properties.SIZE), uint8(13), uint8(0), Model.Position(19, 2));
        pflow.func("get_balloon", uint8(Properties.SIZE), uint8(14), uint8(0), Model.Position(3, 1));
        pflow.func("get_bird", uint8(Properties.SIZE), uint8(15), uint8(0), Model.Position(11, 1));
        pflow.func("get_candle", uint8(Properties.SIZE), uint8(16), uint8(0), Model.Position(13, 2));
        pflow.func("get_cola_bottle", uint8(Properties.SIZE), uint8(17), uint8(0), Model.Position(20, 14));
        pflow.func("get_helium_tank", uint8(Properties.SIZE), uint8(18), uint8(0), Model.Position(6, 1));
        pflow.func("get_hydrogen_tank", uint8(Properties.SIZE), uint8(19), uint8(0), Model.Position(8, 1));
        pflow.func("get_kudzu", uint8(Properties.SIZE), uint8(20), uint8(0), Model.Position(10, 1));
        pflow.func("get_lighter", uint8(Properties.SIZE), uint8(21), uint8(0), Model.Position(15, 2));
        pflow.func("get_mentos", uint8(Properties.SIZE), uint8(22), uint8(0), Model.Position(20, 13));
        pflow.func("get_oxygen_tank", uint8(Properties.SIZE), uint8(23), uint8(0), Model.Position(7, 2));
        pflow.func("get_propane_tank", uint8(Properties.SIZE), uint8(24), uint8(0), Model.Position(4, 1));
        pflow.func("get_reactor", uint8(Properties.SIZE), uint8(25), uint8(0), Model.Position(0, 1));
        pflow.func("get_spider", uint8(Properties.SIZE), uint8(26), uint8(0), Model.Position(2, 1));
        pflow.func("get_string", uint8(Properties.SIZE), uint8(27), uint8(0), Model.Position(12, 1));
        pflow.func("get_water_bottle", uint8(Properties.SIZE), uint8(28), uint8(0), Model.Position(19, 15));
        pflow.func("jet_pack", uint8(Properties.SIZE), uint8(29), uint8(0), Model.Position(10, 11));
        pflow.func("make_baloon_on_string", uint8(Properties.SIZE), uint8(30), uint8(0), Model.Position(5, 8));
        pflow.func("make_basket", uint8(Properties.SIZE), uint8(31), uint8(0), Model.Position(9, 5));
        pflow.func("make_helium_balloon", uint8(Properties.SIZE), uint8(32), uint8(0), Model.Position(5, 10));
        pflow.func("make_hydrogen_balloon", uint8(Properties.SIZE), uint8(33), uint8(0), Model.Position(8, 14));
        pflow.func("make_oxygen_balloon", uint8(Properties.SIZE), uint8(34), uint8(0), Model.Position(7, 12));
        pflow.func("make_parashute", uint8(Properties.SIZE), uint8(35), uint8(0), Model.Position(10, 15));
        pflow.func("make_pillow", uint8(Properties.SIZE), uint8(36), uint8(0), Model.Position(4, 15));
        pflow.func("make_propane_balloon", uint8(Properties.SIZE), uint8(37), uint8(0), Model.Position(7, 15));
        pflow.func("make_rope", uint8(Properties.SIZE), uint8(38), uint8(0), Model.Position(13, 5));
        pflow.func("make_spider_silk", uint8(Properties.SIZE), uint8(39), uint8(0), Model.Position(3, 6));
        pflow.func("make_steam_jetpack", uint8(Properties.SIZE), uint8(40), uint8(0), Model.Position(9, 9));
        pflow.func("make_string", uint8(Properties.SIZE), uint8(41), uint8(0), Model.Position(11, 6));
        pflow.func("make_twine", uint8(Properties.SIZE), uint8(42), uint8(0), Model.Position(12, 6));
        pflow.func("make_twine_rope", uint8(Properties.SIZE), uint8(43), uint8(0), Model.Position(13, 9));
        pflow.func("make_wax", uint8(Properties.SIZE), uint8(44), uint8(0), Model.Position(17, 4));
        pflow.func("make_webshooter", uint8(Properties.SIZE), uint8(45), uint8(0), Model.Position(13, 13));
        pflow.func("stunt_plane", uint8(Properties.SIZE), uint8(46), uint8(0), Model.Position(15, 15));
   }
}

library ModelArcs1 {
    function _arcs(IPflowDSL pflow) public {
        pflow.arrow(1, pflow.transition(23), pflow.place(0));
        pflow.arrow(1, pflow.transition(19), pflow.place(1));
        pflow.arrow(1, pflow.transition(20), pflow.place(2));
        pflow.arrow(1, pflow.place(2), pflow.transition(31));
        pflow.arrow(1, pflow.transition(15), pflow.place(4));
        pflow.arrow(1, pflow.transition(26), pflow.place(3));
        pflow.arrow(1, pflow.transition(14), pflow.place(6));
        pflow.arrow(1, pflow.transition(27), pflow.place(7));
        pflow.arrow(1, pflow.place(7), pflow.transition(38));
        pflow.arrow(1, pflow.transition(21), pflow.place(8));
        pflow.arrow(1, pflow.place(4), pflow.transition(8));
        pflow.arrow(1, pflow.place(3), pflow.transition(39));
        pflow.arrow(1, pflow.transition(39), pflow.place(10));
        pflow.arrow(1, pflow.transition(24), pflow.place(11));
        pflow.arrow(1, pflow.place(0), pflow.transition(7));
        pflow.arrow(1, pflow.place(1), pflow.transition(7));
        pflow.arrow(1, pflow.transition(18), pflow.place(12));
        pflow.arrow(1, pflow.place(12), pflow.transition(5));
        pflow.arrow(1, pflow.transition(6), pflow.place(0));
        pflow.arrow(1, pflow.transition(6), pflow.place(1));
        pflow.arrow(1, pflow.place(13), pflow.transition(6));
        pflow.arrow(1, pflow.transition(22), pflow.place(14));
        pflow.arrow(1, pflow.transition(17), pflow.place(5));
        pflow.arrow(1, pflow.place(5), pflow.transition(4));
        pflow.arrow(1, pflow.place(14), pflow.transition(4));
        pflow.arrow(1, pflow.transition(7), pflow.place(13));
        pflow.arrow(1, pflow.place(6), pflow.transition(30));
        pflow.arrow(1, pflow.transition(30), pflow.place(15));
        pflow.arrow(1, pflow.place(7), pflow.transition(30));
        pflow.arrow(1, pflow.transition(5), pflow.place(1));
        pflow.arrow(1, pflow.place(10), pflow.transition(35));
        pflow.arrow(1, pflow.place(7), pflow.transition(35));
        pflow.guard(1, pflow.transition(5), pflow.place(9));
        pflow.guard(1, pflow.transition(6), pflow.place(9));
        pflow.arrow(1, pflow.place(3), pflow.transition(1));
        pflow.arrow(1, pflow.place(9), pflow.transition(1));
        pflow.arrow(1, pflow.place(6), pflow.transition(0));
        pflow.arrow(1, pflow.place(11), pflow.transition(0));
        pflow.arrow(1, pflow.transition(38), pflow.place(17));
        pflow.arrow(1, pflow.transition(31), pflow.place(16));
        pflow.arrow(1, pflow.transition(16), pflow.place(18));
        pflow.guard(1, pflow.transition(44), pflow.place(8));
        pflow.arrow(1, pflow.place(18), pflow.transition(44));
        pflow.arrow(1, pflow.place(8), pflow.transition(3));
        pflow.arrow(1, pflow.place(18), pflow.transition(3));
    }
}

library ModelArcs2 {
    function _arcs(IPflowDSL pflow) public {
        pflow.arrow(1, pflow.transition(44), pflow.place(19));
        pflow.arrow(1, pflow.place(19), pflow.transition(8));
        pflow.arrow(1, pflow.place(1), pflow.transition(29));
        pflow.arrow(1, pflow.place(0), pflow.transition(29));
        pflow.guard(1, pflow.transition(29), pflow.place(8));
        pflow.arrow(1, pflow.place(14), pflow.transition(11));
        pflow.arrow(1, pflow.place(5), pflow.transition(9));
        pflow.arrow(1, pflow.place(12), pflow.transition(32));
        pflow.arrow(1, pflow.place(15), pflow.transition(32));
        pflow.arrow(1, pflow.place(15), pflow.transition(34));
        pflow.arrow(1, pflow.place(15), pflow.transition(33));
        pflow.arrow(1, pflow.place(0), pflow.transition(34));
        pflow.arrow(1, pflow.place(1), pflow.transition(33));
        pflow.arrow(1, pflow.place(10), pflow.transition(36));
        pflow.arrow(1, pflow.place(4), pflow.transition(36));
        pflow.arrow(1, pflow.place(2), pflow.transition(10));
        pflow.arrow(1, pflow.place(16), pflow.transition(0));
        pflow.arrow(1, pflow.place(11), pflow.transition(37));
        pflow.arrow(1, pflow.place(15), pflow.transition(37));
        pflow.guard(1, pflow.transition(2), pflow.place(0));
        pflow.guard(1, pflow.transition(1), pflow.place(10));
        pflow.arrow(1, pflow.place(10), pflow.transition(45));
        pflow.arrow(1, pflow.place(5), pflow.transition(45));
        pflow.arrow(1, pflow.place(10), pflow.transition(41));
        pflow.arrow(1, pflow.transition(41), pflow.place(7));
        pflow.arrow(1, pflow.place(17), pflow.transition(0));
        pflow.arrow(1, pflow.place(5), pflow.transition(46));
        pflow.arrow(1, pflow.place(20), pflow.transition(46));
        pflow.arrow(1, pflow.transition(8), pflow.place(20));
        pflow.arrow(1, pflow.place(11), pflow.transition(13));
        pflow.arrow(1, pflow.place(8), pflow.transition(13));
        pflow.arrow(1, pflow.place(1), pflow.transition(12));
        pflow.arrow(1, pflow.place(8), pflow.transition(12));
        pflow.arrow(1, pflow.place(9), pflow.transition(46));
        pflow.arrow(1, pflow.transition(25), pflow.place(9));
        pflow.arrow(1, pflow.place(2), pflow.transition(42));
        pflow.arrow(1, pflow.transition(42), pflow.place(21));
        pflow.arrow(1, pflow.transition(43), pflow.place(17));
        pflow.arrow(1, pflow.place(21), pflow.transition(43));
        pflow.arrow(1, pflow.place(11), pflow.transition(40));
        pflow.arrow(1, pflow.place(13), pflow.transition(40));
        pflow.guard(1, pflow.transition(40), pflow.place(8));
        pflow.arrow(1, pflow.transition(28), pflow.place(13));
        pflow.guard(1, pflow.transition(29), pflow.place(9));
   }
}

abstract contract Metamodel is ModelInstance, ModelInterface {

    // sequence is a monotonically increasing counter for each signal
    int8 public sequence = 0;

    // transform is a hook for derived contracts to implement state transitions
    function transform(uint8 i, Model.Transition memory t, uint8 scalar) internal virtual;

    // isInhibited is a hook for derived contracts to implement transition guards
    function isInhibited(Model.Transition memory t) internal view virtual returns (bool);

    // hasPermission implements an ACL for transitions based on user roles
    function hasPermission(Model.Transition memory t) internal view virtual returns (bool);

    function _signal(uint8 action, uint8 scalar) internal {
        Model.Transition memory t = pflow.transition(action);
        assert(!isInhibited(t));
        assert(action == t.offset);
        for (uint8 i = 0; i < uint8(pflow.vectorSize()); i++) {
            transform(i, t, scalar);
        }
        sequence++;
        emit Model.SignaledEvent(t.role, action, scalar);
    }

    function signal(uint8 action, uint8 scalar) external {
        _signal(action, scalar);
    }

    function signalMany(uint8[] calldata actions, uint8[] calldata scalars) external {
        require(actions.length == scalars.length, "ModelRegistry: invalid input");
        for (uint8 i = 0; i < actions.length; i++) {
            _signal(actions[i], scalars[i]);
        }
    }

    // model returns the model in a format suited for execution
    function model() external view returns (Model.PetriNet memory) {
        return Model.PetriNet(pflow.getPlaces(), pflow.getTransitions(), pflow.getArcs());
    }

    // declaration returns the model in a format suited for visualization
    function declaration() external view returns (Declaration.PetriNet memory) {
        return Model.toDeclaration(pflow);
    }

}


contract MyStateMachine is Metamodel {
    //  REVIEW: store the state of the contract
    int8[] public state = new int8[](uint8(ModelEnums.Properties.SIZE));

    function isInhibited(Model.Transition memory t) override internal view returns (bool) {
        for (uint8 i = 0; i < uint8(ModelEnums.Properties.SIZE); i++) {
            if (t.guard[i] != 0) {
                if (t.guard[i] < 0) {
                    // inhibit unless condition is met
                    if ((state[i] + t.guard[i]) > 0) {
                        return true;
                    }
                } else {
                    // inhibit until condition is met
                    if ((state[i] - t.guard[i]) < 0) {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    
    function hasPermission(Model.Transition memory t) internal override view returns (bool) {
        uint8[] memory roles = getRoles();
        for (uint i = 0; i < roles.length; i++) {
            if (uint8(roles[i]) == uint8(t.role)) {
                return true;
            }
        }
        revert("no permission");
    }
    
    function transform(uint8 i, Model.Transition memory t, uint8 scalar) override internal {
        require(scalar > 0, "invalid scalar");
        if (t.delta[i] != 0) {
            state[i] = state[i] + t.delta[i] * int8(scalar);
            require(state[i] >= 0, "underflow");
            if (pflow.place(i).capacity > 0) {
                require(state[i] <= int8(pflow.place(i).capacity), "overflow");
            }
        }
    }

    function getRoles() internal view returns (uint8[] memory) {
        uint8[] memory roles = new uint8[](2);
        roles[0] = uint8(ModelEnums.Roles.DEFAULT);
        roles[1] = uint8(ModelEnums.Roles.HALT);
        return roles;
    }

    constructor(IPflowDSL _pflow) ModelInstance(_pflow) {
        for (uint8 i = 0; i < uint8(ModelEnums.Properties.SIZE); i++) {
            state[i] = int8(pflow.place(i).initial);
        }
    }

}