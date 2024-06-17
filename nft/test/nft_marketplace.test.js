const { expect } = require("chai"); 
const { ethers } = require('hardhat');

const toWei = (num) => ethers.utils.parseEther(num.toString());
const fromWei = (num) => ethers.utils.formatEther(num);

describe("NFTMarketplace", function () {
    //let NFT;
    let nft;
    //let Marketplace;
    let marketplace
    let deployer; // fee account
    let addr1; // addr to mint and create tokens
    let addr2; // addr to buy tokens
    let addrs; // remaining addresses
    let feePercent = 3;
    let URI = "sample URI"

    beforeEach(async function () {
        // Get the ContractFactories and Signers here.
        const SimpleNFS = await ethers.getContractFactory("SimpleNFS");
        const MarketPlace = await ethers.getContractFactory("MarketPlace");
        
        [deployer, addr1, addr2, ...addrs] = await ethers.getSigners();

        // To deploy our contracts
        nft = await SimpleNFS.deploy();
        marketplace = await MarketPlace.deploy();
    });

    describe("Deployment", function () {
        it("Should track name and symbol of the nft collection", async function () {
            const nftName = "DApp NFT";
            const nftSymbol = "DAPP";

            expect(await nft.name()).to.equal(nftName);
            expect(await nft.symbol()).to.equal(nftSymbol);
        });

        it("Should track feeAccount and feePercent of the marketplace", async function () {
            expect(await marketplace.feeAccount()).to.equal(deployer.address);
            expect(await marketplace.feePercent()).to.equal(feePercent);
        });
    })

});


/*

{
  "dependencies": {
    "@openzeppelin/contracts": "^5.0.2"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^2.0.0",
    "chai": "^5.1.1",
    "hardhat": "^2.12.0"
  }
}

// "@nomiclabs/hardhat-waffle": "^2.0.6",
    // "ethereum-waffle": "^2.2.0",
*/