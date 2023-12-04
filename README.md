# AA Benchmark

A benchmark for AA (ERC-4337) smart contract accounts.

All accounts use single-ECDSA signatures.  We plan on expanding to other signing schemes in the future (multisig, RSA, etc.).

## Results (as of Oct 18, 2023)

**Disclaimer** the numbers are obtained from local simulations.  On-chain numbers might differ slightly.

Since these are gas numbers, lower is better.

|                  | Creation | Native transfer | ERC20 transfer | Total  |
| ---------------- | -------- | --------------- | -------------- | ------ |
| SimpleAccount    | 383218   | 101319          | 90907          | 575444 |
| Biconomy         | 270013   | 104408          | 93730          | 468151 |
| Etherspot        | 279219   | 103719          | 93324          | 476262 |
| Kernel v2.0      | 339882   | 110018          | 99622          | 549522 |
| Kernel v2.1      | 265215   | 106460          | 96038          | 467713 |
| Kernel v2.1-lite | 230968   | 101002          | 90321          | 422291 |
| Solady ERC4337   | 211982   | 99965           | 89346          | 401293 |
| SoulWalletCore   | 276529   | 101162          | 90466          | 468157 |


## How to add your implementation

1. Fork this repo.
2. Add your test file to `./test/`; create a folder if needed.
3. Inherit `src/TestBase.sol` and override `getSignature()`, `fillData()`, `createAccount()`, `getAccountAddr()`, `getInitCode()`.
    - `getSignature()`: should return appropriate signature based on `_op` (e.g. should return ECDSA signature).
    - `fillData()`: should return appropriate data for `userOp.callData`.
    - `createAccount()`: should create the wallet.  Skip this if your factory only allows for creation through the EntryPoint.
    - `getAccountAddr()`: should return the counterfactual address for the given `_owner`.
    - `getInitCode()`: should return `userOp.initCode`.
4. Write `setUp()` function to set the initial test condition.  For instance, it might deploy the factory and the implementation contract. **NOTICE** since we don't want this repo to have too many dependencies, please use `vm.etch` and use your predicted address & bytecode to deploy the contract instead of importing your whole code.  This will also make it easy to test without compiler setup fiasco.
5. Run `WRITE_GAS_PROFILE=true forge test -vv` this will show you the results of the benchmark and also output the result as a JSON file to `results/`.
6. Make a PR to this repository.

### TODO

- [ ] add paymaster benchmark
- [ ] allow non-ECDSA benchmark
    - [ ] maybe RSA?
- [ ] add CI for cheking/getting the gas results
- [ ] L2 gas cost calculation
