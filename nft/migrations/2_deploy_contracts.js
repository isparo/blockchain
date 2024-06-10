// migrations/2_deploy_contracts.js
const SimpleNFS = artifacts.require("SimpleNFS");

module.exports = function (deployer) {
  deployer.deploy(SimpleNFS);
};
