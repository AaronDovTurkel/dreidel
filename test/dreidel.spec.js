const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dreidel", function () {
  it("Should deploy", async function () {
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    expect((await dreidel.list_games()).length).to.equal(0);
  });

  it("Should propose a game", async function () {
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1"),
    });

    expect((await dreidel.list_games()).length).to.equal(1);
  });

  it("Should join a game", async function () {
    const [_, addr1] = await ethers.getSigners();
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1"),
    });
    await dreidel
      .connect(addr1)
      .join_game(0, { value: ethers.utils.parseEther("1") });

    expect((await dreidel.list_games())[0].members.length).to.equal(2);
  });

  it("Should start a game", async function () {
    const [_, addr1, addr2] = await ethers.getSigners();
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1"),
    });
    await dreidel
      .connect(addr1)
      .join_game(0, { value: ethers.utils.parseEther("1") });
    await dreidel
      .connect(addr2)
      .join_game(0, { value: ethers.utils.parseEther("1") });

    expect((await dreidel.list_games())[0].status).to.equal(0);
    expect((await dreidel.list_games())[0].pot).to.equal(
      ethers.utils.parseEther("0.0003")
    );
  });
});
