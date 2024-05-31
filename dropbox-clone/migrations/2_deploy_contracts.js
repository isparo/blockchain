// migrations/2_deploy_contracts.js
const SimpleDropbox = artifacts.require("SimpleDropbox");

module.exports = function (deployer) {
  deployer.deploy(SimpleDropbox);
};
