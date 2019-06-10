const Whitelist = artifacts.require("Whitelist")

module.exports = function(deployer) {
  deployer.deploy(Whitelist, "0x4f833a24e1f95d70f028921e27040ca56e09ab0b");
};

/* 0x Exchange Contract Locations:
[
    {
        "name": "Exchange",
        "version": "2.0.0",
        "changes": [
            {
                "note": "protocol v2 deploy",
                "networks": {
                    "1": "0x4f833a24e1f95d70f028921e27040ca56e09ab0b",
                    "3": "0x4530c0483a1633c7a1c97d2c53721caff2caaaaf",
                    "4": "0x22ebc052f43a88efa06379426120718170f2204e",
                    "42": "0x35dd2932454449b14cee11a94d3674a936d5d7b2"
                }
            }
        ]
    }
]
*/