async function main() {
  // Setup accounts
  const [deployer] = await ethers.getSigners()
  console.log("Deploying contracts with the account:", deployer.address);

  const CertificateNFT = await ethers.getContractFactory("CertificateNFT");
  const certificateNFT = await CertificateNFT.deploy()

  const nftContrAddrr = await crowdfunding.target;
  console.log(`Deployed CertificateNFT Contract at: ${nftContrAddrr}\n`)

  // Get the ContractFactories and Signers here.
  const Crowdfunding = await ethers.getContractFactory("Crowdfunding");
  const crowdfunding = await Crowdfunding.deploy(certificateNFT.target);
  
  const addrr = await crowdfunding.target;

  console.log(`Deployed crowdfunding Contract at: ${addrr}\n`)
}

main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});