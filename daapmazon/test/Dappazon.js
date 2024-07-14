const { expect } = require("chai"); 
const { ethers } = require('hardhat');



const toWei = (num) => ethers.utils.parseEther(num.toString());
// const fromWei = (num) => ethers.utils.formatEther(num);
const fromWei = (num) => ethers.utils.formatEther(num)

// Global constants for listing an item...
const ID = 1
const NAME = "Shoes"
const CATEGORY = "home"
const IMAGE = "https://ipfs.io/ipfs/QmTYEboq8raiBs7GTUg2yLXB3PMz6HuBNgNfSZBx5Msztg/shoes.jpg"
const COST = toWei(1);
const RATING = 4
const STOCK = 5

describe("Dappazon", () => {
    let dappazon
    let deployer, buyer, buyerWithoutBalanse

    beforeEach(async () => {
        // Setup accounts
        [deployer, buyer, buyerWithoutBalanse] = await ethers.getSigners()

        // Deploy contract
        const Dappazon = await ethers.getContractFactory("Dappazon")
        dappazon = await Dappazon.deploy()
    })

    describe("Deployment", () => {
        it("Sets the owner", async () => {
            expect(await dappazon.owner()).to.equal(deployer.address)
        })
    })

    describe("Listing", () => {
        let transaction

        it("Emits List event",async () => {
             // List a item
             transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
             await transaction.wait()
            expect(transaction).to.emit(dappazon, "List")
        })

        it("Shuld add new items", async () => {
             // List a item
             transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
             await transaction.wait()

            const item = await dappazon.items(ID)
            
            expect(item.id).to.equal(ID)
            expect(item.name).to.equal(NAME)
            //expect(item.category).to.equal(CATEGORY)
            expect(item.image).to.equal(IMAGE)
            expect(item.cost).to.equal(COST)
            expect(item.rating).to.equal(RATING)
            expect(item.stock).to.equal(STOCK)

            const arrayLength = await dappazon.getHomeGroupingLength();
            expect(arrayLength).to.equal(1)
        });

        it("Should fail when is not deployer", async () => {
            try {
                await dappazon.connect(buyer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
                expect.fail("La transacción debería fallar");
            } catch (error) {
                expect(error.message.includes("revert")).to.equal(true)
            }
        });
    });

    describe("Buying", () => {
        let transaction

        it("Emits Buy event",async () => {
            // List a item
            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()
            
            // List a item
            transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
            await transaction.wait()
            expect(transaction).to.emit(dappazon, "Buy")
        })

        it("Product unavailable", async () => {
            try {
                // List a item
                transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, 1)
                await transaction.wait()

                transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
                await transaction.wait()
                expect(transaction).to.emit(dappazon, "Buy")

                transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
                await transaction.wait()

                expect.fail("La transacción debería fallar");
            } catch (error) {
                expect(error.message.includes("revert")).to.equal(true)
            }
        });

        it("Updates the contract balance", async () => {

            const previousBalance = await ethers.provider.getBalance(dappazon.address)

            // List a item
            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()

            transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
            await transaction.wait()
            
            transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
            await transaction.wait()
        
            result = await ethers.provider.getBalance(dappazon.address)

            expect(+fromWei(result)).to.equal(+fromWei(previousBalance) + +fromWei(COST) + +fromWei(COST))

            
        })

        it("sends invalid cost value", async () => {
            try{
                // List a item
                transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, 1)
                await transaction.wait()

                transaction = await dappazon.connect(buyer).buy(ID, { value: 0 })
                await transaction.wait()
            } catch(error) {
                
                expect(error.message.includes("invalid value")).to.equal(true)
            }
        })
    });

    describe("Withdrawing", () => {
        let balanceBefore
    
        beforeEach(async () => {
          // List a item
          let transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
          await transaction.wait()
    
          // Buy a item
          transaction = await dappazon.connect(buyer).buy(ID, { value: COST })
          await transaction.wait()
    
          // Get Deployer balance before
          balanceBefore = await ethers.provider.getBalance(deployer.address)
    
          // Withdraw
          transaction = await dappazon.connect(deployer).withdraw()
          await transaction.wait()
        })
    
        it('Updates the owner balance', async () => {
          const balanceAfter = await ethers.provider.getBalance(deployer.address)
          expect(balanceAfter).to.be.greaterThan(balanceBefore)
        })
    
        it('Updates the contract balance', async () => {
          const result = await ethers.provider.getBalance(dappazon.address)
          expect(result).to.equal(0)
        })
    });

    describe("getByCategory", () => {

        it("should list by category", async () =>{
            // List a item
            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()

            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()

            const arrayLength = await dappazon.getHomeGroupingLength();
            expect(arrayLength).to.equal(2)

            let res = await dappazon.connect(buyer).getByCategory(CATEGORY)
            expect(res[0].category).to.equal(1)
            expect(res.length).to.equal(2)
        });

        it("should not list by category", async () =>{
            // List a item
            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()

            const item = await dappazon.items(ID)
            expect(item.id).to.equal(ID)
            expect(item.name).to.equal(NAME)
            //expect(item.category).to.equal(CATEGORY)
            expect(item.image).to.equal(IMAGE)
            expect(item.cost).to.equal(COST)
            expect(item.rating).to.equal(RATING)
            expect(item.stock).to.equal(STOCK)

            const arrayLength = await dappazon.getHomeGroupingLength();
            expect(arrayLength).to.equal(1)

            let res = await dappazon.connect(buyer).getByCategory("other")
           // expect(res[0].category).to.equal(1)
            expect(res.length).to.equal(0)
        });
    });

    describe("updateStock", () => {
        it("should update the stock", async () => {
            // List a item
            transaction = await dappazon.connect(deployer).list(ID, NAME, CATEGORY, IMAGE, COST, RATING, STOCK)
            await transaction.wait()

            const item = await dappazon.items(ID)
            const currentStock = item.stock;
            await dappazon.connect(deployer).updateStock(ID,10);
            const itemUopdated = await dappazon.items(ID)
            expect(currentStock).to.lessThan(itemUopdated.stock);
            expect(itemUopdated.stock).to.equal(10);
        })
    })
});