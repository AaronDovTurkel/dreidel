const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dreidel", function () {
  it("Should deploy", async function () {
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    expect((await dreidel)).to.not.be.undefined;
  });

  it("Should propose a game", async function () {
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1"),
    });

    expect((await dreidel.games(0)).member_limit).to.equal(3);
  });

  it("Should join a game", async function () {
    const [owner, addr1] = await ethers.getSigners();
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1"),
    });
    await dreidel
      .connect(addr1)
      .join_game(0, { value: ethers.utils.parseEther("1") });

    expect((await dreidel.get_game_members(0)).length).to.equal(2);
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

    expect((await dreidel.games(0)).status).to.equal(0);
    expect((await dreidel.games(0)).pot).to.equal(
      ethers.utils.parseEther("0.0003")
    );
  });

  it("should buy in extra money", async function () {
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
    await dreidel.connect(addr2).buyin({ value: ethers.utils.parseEther("1") });

    expect((await dreidel.member_buyin(addr2.getAddress()))).to.equal(
      ethers.utils.parseEther("1.9999")
    );
  })

  it("should spin the dreidel", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const Dreidel = await ethers.getContractFactory("Dreidel");
    const dreidel = await Dreidel.deploy();
    await dreidel.deployed();

    await dreidel.propose_game(ethers.utils.parseEther("0.0001"), 3, {
      value: ethers.utils.parseEther("1")
    });
    await dreidel
      .connect(addr1)
      .join_game(0, { value: ethers.utils.parseEther("1") });
    await dreidel
      .connect(addr2)
      .join_game(0, { value: ethers.utils.parseEther("1") });

    await expect(dreidel.spin(0)).to.emit(dreidel, "Spin");
    expect((await dreidel.games(0)).turn).to.equal(1);

    // console.log((await dreidel.games(0)).pot.toString());
    // console.log((await dreidel.member_buyin(owner.getAddress())).toString());
    // console.log(ethers.utils.parseEther(".0003").toString())

    if (((await dreidel.games(0)).pot.toString()) === (ethers.utils.parseEther(".0005").toString())) {
      expect((await dreidel.member_buyin(owner.getAddress())).toString()).to.equal(
        ethers.utils.parseEther(".9997").toString()
      )
    }

    if (((await dreidel.games(0)).pot.toString()) === (ethers.utils.parseEther(".0003").toString()) && (await dreidel.member_buyin(addr1.getAddress())).toString() === "999800000000000000") {
      expect((await dreidel.member_buyin(owner.getAddress())).toString()).to.equal(
        ethers.utils.parseEther("1.0001").toString()
      )
    }

    if (((await dreidel.games(0)).pot.toString()) === (ethers.utils.parseEther(".0003").toString()) && (await dreidel.member_buyin(addr1.getAddress())).toString() === "999900000000000000") {
      expect((await dreidel.member_buyin(owner.getAddress())).toString()).to.equal(
        ethers.utils.parseEther(".9999").toString()
      )
    }

    if (((await dreidel.games(0)).pot.toString()) === (ethers.utils.parseEther(".00015").toString())) {
      expect((await dreidel.member_buyin(owner.getAddress())).toString()).to.equal(
        ethers.utils.parseEther("1.00005").toString()
      )
    }

    if (((await dreidel.games(0)).pot.toString()) === (ethers.utils.parseEther(".00015").toString())) {
      expect((await dreidel.member_buyin(owner.getAddress())).toString()).to.equal(
        ethers.utils.parseEther("1.00005").toString()
      )
    }
  })
});
