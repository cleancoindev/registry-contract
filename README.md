# Microsponsors Proof-of-Content Registry Contract

On-chain registry that maps Microsponsors user content to their Ethereum address. Functionally, this is a whitelist that will be integrated into our onboarding flow. It will ensure that only verified users are transacting.

Boilerplate source code is more or less copied/ compiled from [0x's Whitelist.sol example contract](https://github.com/0xProject/0x-monorepo/blob/development/contracts/exchange/contracts/examples/Whitelist.sol)


## Install, Compile & Deploy

Install dependencies: `$ npm install`

Start Ganache in another terminal: `$ ganache-cli -p 8545`

Compile: `$ npm run compile`

Note that in /migrations/2_deploy_contracts.js, the second argument to `.deploy()` must be the 0x Exchange contract that the Whitelist forwards the order to after whitelist validation.

Compile & Deploy in one step: `$ npm run deploy`

* Note that dependency versions are locked for safety/ consistency. Updates to package dependencies will happen manually on a case-by-case basis.

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
After contract is deployed via ganache-cli

Open truffle console and wire up test users:
```
$ truffle console --network development
```

### Create Whitelist instance
```
> Whitelist.deployed().then(inst => { wi = inst })
```
`wi` is now your whitelist instance, can be referred to in console session

### Add or remove an address to the whitelist
```
wi.updateWhitelistStatus("0xc835cf67962948128157de5ca5b55a4e75f572d2", "0x666f6f2e636f6d", true)
```
Third param is `false` to remove an address from the whitelist

### Check if an address is whitelisted
```
> wi.isWhitelisted("0xc835cf67962948128157de5ca5b55a4e75f572d2")
true
```


## Dev Notes
How this was put together:
```
$ truffle init
$ npm install @0x/contracts-exchange --save`
$ truffle compile
$ truffle migrate --network development
```
...per instructions [here](https://github.com/0xProject/0x-monorepo/tree/development/contracts/exchange)
