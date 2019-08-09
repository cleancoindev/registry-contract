# Proof-of-Content Registry Contract

[WIP] On-chain registry that maps a users' Ethereum `address` to an `isWhitelisted` boolean and a `contentId`, as defined in our [utils.js library here](https://github.com/microsponsors/utils.js#contentid).

Bids and fills in the [0x Protocol](https://0x.org) format will be validated by this contract.

Boilerplate whitelist source code is more or less copy-pasted from [0x's Whitelist.sol example contract](https://github.com/0xProject/0x-monorepo/blob/development/contracts/exchange/contracts/examples/Whitelist.sol)


## Install, Compile & Deploy

Install dependencies: `$ npm install`

Start Ganache in another terminal: `$ ganache-cli -p 8545`

Compile: `$ npm run compile`

Compile & Deploy in one step: `$ npm run deploy`

Note that in /migrations/2_deploy_contracts.js, the second argument to `.deploy()` must be the 0x Exchange contract that the Whitelist forwards the order to after whitelist validation.

* Note: dependency versions are locked for safety/ consistency. Updates to package dependencies will happen manually on a case-by-case basis.

### Versioning
This stack seems to be sensitive to versioning, so capturing details here:

* truffle v5.0.21
* ganache-cli v6.4.3
* solc compiler 0.5.5, specified in truffle-config.js

### Linter
Install [solhint](https://www.npmjs.com/package/solhint) globally and run the linter:
```
$ npm install -g solhint
$ npm run lint
```


## Scenarios
Start ganache in one terminal, truffle console in another.
```
$ ganache-cli -p 8545
$ truffle console --network development
```


## Manage Whitelist
```
> Whitelist.deployed().then(inst => { wi = inst })
```
`wi` = whitelist instance

### adminUpdate()
Admin: Add/remove address to whitelist, map it to contentId.
Is pausable.
* @param `target`: Address to add or remove from whitelist.
* @param `contentId`: Hex-encoded, Ex: web3.utils.utf8ToHex('foo.com')
* @param `isApproved`: isWhitelisted status boolean for address.
```
wi.adminUpdate(
  "0xc835cf67962948128157de5ca5b55a4e75f572d2",
  "0x666f6f2e636f6d",
  true)
```
The `contentId` is designed to be pretty flexible in this contract (just a simple string) to allow for maximum forward-compatibility. Details on format [here](https://github.com/microsponsors/utils.js#contentid).

### adminUpdateWhitelistStatus()
Admin: Add or remove address from whitelist (set isWhitelisted to false).
Is pausable.
* @param `target`: Address to add or remove from whitelist.
* @param `isApproved`: isWhitelisted status boolean for address.
```
wi.adminUpdateWhitelistStatus(
  "0xc835cf67962948128157de5ca5b55a4e75f572d2",
  false
);
```

### adminRemoveContentIdFromAddress()
Is pausable.
* @param `target`: Address to remove content id from.
* @param `contentId`: Content id to remove.
```
wi.adminRemoveContentIdFromAddress(
  "0xc835cf67962948128157de5ca5b55a4e75f572d2",
  "0x666f6f2e636f6d"
);
```

### adminGetAddressByContentId()
Admin: Get valid whitelist address mapped to a contentId.
* @param `contentId`: Hex-encoded. Ex: `web3.toHex('foo.com')`
```
wi.adminGetAddressByContentId("0x666f6f2e636f6d")
```

### adminGetContentIdsByAddress()
Admin: Get the contentId mapped to the valid whitelist address.
Handle hex-encoded return value: `web3.toUtf8(<return value>)`
```
wi.adminGetContentIdByAddress("0xc835cf67962948128157de5ca5b55a4e75f572d2")
```

### isWhitelisted()
Check isWhitelisted status boolean for an address.
```
> wi.isWhitelisted("0xc835cf67962948128157de5ca5b55a4e75f572d2")
```

### getContentIdsByAddress()
Get contentIds for valid whitelist address.
Only if msg.sender is asking for own mapping.
```
wi.getContentIdByAddress({from: "0xc835cf67962948128157de5ca5b55a4e75f572d2"})
```

### removeContentIdFromAddress()
Valid whitelisted address can remove its own content id.
Is pausable.
* @param `contentId`: Content id to remove.
```
wi.removeContentIdFromAddress("0x666f6f2e636f6d");
```


## 0x Exchange Functions

### isValidSignature()
Verifies signer is same as signer of current transaction.

### fillOrderIfWhitelisted()
Is pausable.


## Pause contract
Admin: Stops editing of state for contract and filling of orders.
Does not stop reads!

### pause()
### unpause()


## Dev Notes
How this was put together:
```
$ truffle init
$ npm install @0x/contracts-exchange --save`
$ truffle compile
$ truffle migrate --network development
```
...per instructions in [0x Monorepo here](https://github.com/0xProject/0x-monorepo/tree/development/contracts/exchange)
