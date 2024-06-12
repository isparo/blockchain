// migrations/2_deploy_contracts.js
const DropboxV2 = artifacts.require("DropboxV2");

module.exports = function (deployer) {
  deployer.deploy(DropboxV2);
};
