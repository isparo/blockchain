async function main() {
    const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  

    // Get the ContractFactories and Signers here.
    const SimpleNFS = await ethers.getContractFactory("SimpleNFS");
    const MarketPlace = await ethers.getContractFactory("MarketPlace");
    // deploy contracts
    const marketplace = await MarketPlace.deploy();
    const simpleNFS = await SimpleNFS.deploy();

    console.log('marketplace.address:')
    console.log(marketplace.target)
    console.log('simpleNFS.address')
    console.log(simpleNFS.target)
}
  
main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});