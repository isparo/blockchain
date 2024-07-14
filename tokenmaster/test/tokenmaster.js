const { ethers } = require('hardhat');
const { expect } = require("chai")


const toWei = (num) => ethers.parseEther(num.toString());
const fromWei = (num) => ethers.formatEther(num)

describe("tokenmaster", () => {
    let tokenMaster
    let deployer, buyer

    const NAME = "TokenMaster"
    const SYMBOL = "TM"

    const OCCASION_NAME = "ETH Texas"
    const OCCASION_COST = toWei(1);
    const OCCASION_MAX_TICKETS = 100
    const OCCASION_DATE = "Apr 27"
    const OCCASION_TIME = "10:00AM CST"
    const OCCASION_LOCATION = "Austin, Texas"

    beforeEach(async () => {
        // Setup accounts
        [deployer, buyer] = await ethers.getSigners()

        // Deploy contract
        const TokenMaster = await ethers.getContractFactory("TokenMaster")
        tokenMaster = await TokenMaster.deploy()

        console.log(deployer.address);
        console.log(buyer.address);

        const transaction = await tokenMaster.connect(deployer).list(
          OCCASION_NAME,
          OCCASION_COST,
          OCCASION_MAX_TICKETS,
          OCCASION_DATE,
          OCCASION_TIME,
          OCCASION_LOCATION
        )

        await transaction.wait()
    });

    describe("Deployment", () => {
        it("Sets the name", async () => {
            expect(await tokenMaster.name()).to.equal(NAME)
        })

        it("Sets the symbol", async () => {
            expect(await tokenMaster.symbol()).to.equal(SYMBOL)
        })

        it("Sets the owner", async () => {
            expect(await tokenMaster.owner()).to.equal(deployer.address)
        })
    });

    describe("Occasions", () => {
        it('Returns occasions attributes', async () => {
          const occasions = await tokenMaster.getAllOccasions()
          expect(occasions[0].name).to.be.equal(OCCASION_NAME)
          expect(occasions[0].cost).to.be.equal(OCCASION_COST)
          expect(occasions[0].tickets).to.be.equal(OCCASION_MAX_TICKETS)
          expect(occasions[0].date).to.be.equal(OCCASION_DATE)
          expect(occasions[0].time).to.be.equal(OCCASION_TIME)
          expect(occasions[0].location).to.be.equal(OCCASION_LOCATION)
        })
      })

});