// require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.20",
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      network_id: "*",
    },
  },
};