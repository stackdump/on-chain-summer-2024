import { expect } from "chai";
import hre from "hardhat";

describe("Jetsam", function () {
  async function deployFixture() {
    const [owner] = await hre.ethers.getSigners();
    const Model= await hre.ethers.getContractFactory("Model");
    const model= await Model.deploy();

    const ModelEnums = await hre.ethers.getContractFactory("ModelEnums");
    const modelEnums = await ModelEnums.deploy();

    const ModelTransitions = await hre.ethers.getContractFactory("ModelTransitions");
    const modelTransitions = await ModelTransitions.deploy();

    const ModelPlaces = await hre.ethers.getContractFactory("ModelPlaces");
    const modelPlaces = await ModelPlaces.deploy();

    const ModelArcs1 = await hre.ethers.getContractFactory("ModelArcs1");
    const modelArcs1 = await ModelArcs1.deploy();

    const ModelArcs2 = await hre.ethers.getContractFactory("ModelArcs2");
    const modelArcs2 = await ModelArcs2.deploy();

    const MyStateMachineArtifact = await hre.artifacts.readArtifact("MyStateMachine");
    const MyStateMachine = await hre.ethers.getContractFactory("MyStateMachine", {
      libraries: {
        Model: model.getAddress(),
        ModelEnums: modelEnums.getAddress(),
        ModelTransitions: modelTransitions.getAddress(),
        ModelPlaces: modelPlaces.getAddress(),
        ModelArcs1: modelArcs1.getAddress(),
        ModelArcs2: modelArcs2.getAddress()
      }
    });

    return {
    };
  }

  it("Should deploy the contract", async function () {
    await deployFixture();
    //const addr = await model.getAddress();
    //console.log({ address: addr});
    //expect(addr).to.equal('0x5FbDB2315678afecb367f032d93F642f64180aa3');
  });

});
