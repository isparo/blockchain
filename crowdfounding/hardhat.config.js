require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.24",
  networks: {
    ganache: {
      url: "http://127.0.0.1:7545",
      network_id: "*",
      gas: 6721975,
      blockGasLimit: 6721975,
    },
  },
};