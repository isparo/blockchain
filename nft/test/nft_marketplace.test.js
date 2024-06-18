const { expect } = require("chai"); 
const { ethers } = require('hardhat');

const tokens = (n) => {
    return ethers.utils.parseUnits(n.toString(), 'ether')
}

const toWei = (num) => ethers.utils.parseEther(num.toString());
// const fromWei = (num) => ethers.utils.formatEther(num);

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
        marketplace = await MarketPlace.deploy();
        nft = await SimpleNFS.deploy();

        console.log(marketplace.target)
        console.log(nft.target)
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
    });

    describe("Minting NFTs", function(){
        it("Should track each minted NFT", async function () {
            // addr1 mints an nft
            await nft.connect(addr1).mint(URI)
            expect(await nft.tokenCount()).to.equal(1);
            expect(await nft.balanceOf(addr1.address)).to.equal(1);
            expect(await nft.tokenURI(1)).to.equal(URI);
            // addr2 mints an nft
            await nft.connect(addr2).mint(URI)
            expect(await nft.tokenCount()).to.equal(2);
            expect(await nft.balanceOf(addr2.address)).to.equal(1);
            expect(await nft.tokenURI(2)).to.equal(URI);
          });
    });

    describe("Making marketplace items", function () {
        beforeEach(async function () {
          // addr1 mints an nft
          await nft.connect(addr1).mint(URI)

          // addr1 approves marketplace to spend nft
          await nft.connect(addr1).setApprovalForAll(marketplace.target, true)
        })
    
    
        it("Should track newly created item, transfer NFT from seller to marketplace and emit Offered event", async function () {
          // addr1 offers their nft at a price of 1 ether

        //   const price = 2
        //   let result 

          let pri = ethers.utils.parseEther(price);
          console.log(pri)

          await expect(marketplace.connect(addr1).makeItem(nft.target, 1 , toWei(2)))
            .to.emit(marketplace, "Offered")
            .withArgs(
              1,
              nft.target,
              1,
              toWei(2),
              addr1.address
            )

          //Owner of NFT should now be the marketplace
          expect(await nft.ownerOf(1)).to.equal(marketplace.target);
          // Item count should now equal 1
        //   expect(await marketplace.itemCount()).to.equal(1)
        //   // Get item from items mapping then check fields to ensure they are correct
        //   const item = await marketplace.items(1)
        //   expect(item.itemId).to.equal(1)
        //   expect(item.nft).to.equal(nft.target)
        //   expect(item.tokenId).to.equal(1)
        //   expect(item.price).to.equal(toWei(price))
        //   expect(item.sold).to.equal(false)
        });
    
        it("Should fail if price is set to zero", async function () {
          await expect(
            marketplace.connect(addr1).makeItem(nft.target, 1, 0)
          ).to.be.revertedWith("Price must be greater than zero");
        });
    
      });

});
