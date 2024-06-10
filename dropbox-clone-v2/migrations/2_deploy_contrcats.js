// migrations/2_deploy_contracts.js
// const DropboxV2 = artifacts.require("DropboxV2");

// module.exports = function (deployer) {
//   deployer.deploy(DropboxV2);
// };

const NFT = artifacts.require("NFT");
const Marketplace = artifacts.require("Marketplace");

module.exports = async function(deployer, _network, accounts) {
  console.log("Deploying contracts with the account:", accounts[0]);
  
  // Deploy contracts
  await deployer.deploy(Marketplace, 1);
  await deployer.deploy(NFT);

  // Save contract addresses to a JSON file for frontend
  const contractsDataDir = "../../frontend/contractsData";
  const fs = require("fs");

  if (!fs.existsSync(contractsDataDir)) {
    fs.mkdirSync(contractsDataDir);
  }

  const marketplaceAddress = Marketplace.address;
  const nftAddress = NFT.address;

  fs.writeFileSync(
    `${contractsDataDir}/Marketplace-address.json`,
    JSON.stringify({ address: marketplaceAddress }, null, 2)
  );

  fs.writeFileSync(
    `${contractsDataDir}/NFT-address.json`,
    JSON.stringify({ address: nftAddress }, null, 2)
  );

  const marketplaceArtifact = artifacts.readArtifactSync("Marketplace");
  const nftArtifact = artifacts.readArtifactSync("NFT");

  fs.writeFileSync(
    `${contractsDataDir}/Marketplace.json`,
    JSON.stringify(marketplaceArtifact, null, 2)
  );

  fs.writeFileSync(
    `${contractsDataDir}/NFT.json`,
    JSON.stringify(nftArtifact, null, 2)
  );
};
