module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545, // Puerto predeterminado de Ganache
      network_id: "*", // Cualquier red
    },
  },
  compilers: {
    solc: {
      version: "0.8.0", // Version del compilador Solidity
    },
  },
};
