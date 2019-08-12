const Whitelist = artifacts.require("Whitelist")

module.exports = function(deployer) {

  /**
   * Second arg is the 0x Exchange contract location that the Whitelist will
   * forward the order to after it verifies Whitelist status of maker + taker:
   */

  // TODO: process.env Exchange contract argument
  deployer.deploy(Whitelist, "0x080bf510fcbf18b91105470639e9561022937712");
};

