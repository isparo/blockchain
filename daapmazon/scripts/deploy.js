async function main() {
  // Setup accounts
  const [deployer] = await ethers.getSigners()
  console.log("Deploying contracts with the account:", deployer.address);

  // Get the ContractFactories and Signers here.
  const Dappazon = await ethers.getContractFactory("Dappazon");
  const dappazon = await Dappazon.deploy()
  
  const addrr = await dappazon.target;

  console.log(`Deployed Dappazon Contract at: ${addrr}\n`)
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});