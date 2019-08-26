const Whitelist = artifacts.require("Whitelist")

module.exports = function(deployer) {

  /**
   * Second arg is the 0x Exchange contract location that the Whitelist will
   * forward the order to after it verifies Whitelist status of maker + taker:
   */
  deployer.deploy(
    Whitelist,
    "0x30589010550762d2f0d06f650D8e8B6Ade6DBf4b" // Ox Exchange on Kovan
  );
};

// 0x Exchange contract
// Kovan (aka 42):
// 0x30589010550762d2f0d06f650D8e8B6Ade6DBf4b

// Mainnet:
// 0x080bf510fcbf18b91105470639e9561022937712
