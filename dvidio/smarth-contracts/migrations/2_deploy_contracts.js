// migrations/2_deploy_contracts.js
const dVideos = artifacts.require("dVideos");

module.exports = function (deployer) {
  deployer.deploy(dVideos);
};