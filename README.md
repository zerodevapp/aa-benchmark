# AA Benchmark

A benchmark for AA (ERC-4337) smart contract accounts.

All accounts use single-ECDSA signatures.  We plan on expanding to other signing schemes in the future (multisig, RSA, etc.).

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

## Results (as of Aug 31, 2023)

**Disclaimer** the numbers are obtained from local simulations.  On-chain numbers might differ slightly.

|                  | Creation | Native transfer | ERC20 transfer | Total  |
| ---------------- | -------- | --------------- | -------------- | ------ |
| SimpleAccount    | 410061   | 97690           | 86754          | 594505 |
| Biconomy         | 296892   | 100780          | 89577          | 487249 |
| Etherspot        | 305769   | 100091          | 89172          | 495032 |
| Kernel v2.0      | 366662   | 106800          | 95877          | 569339 |
| Kernel v2.1      | 291413   | 103240          | 92289          | 486942 |
| Kernel v2.1-lite | 256965   | 97331           | 86121          | 440417 |

### TODO

- [ ] add paymaster benchmark
- [ ] allow non-ECDSA benchmark
    - [ ] maybe RSA?
- [ ] add CI for cheking/getting the gas results
- [ ] L2 gas cost calculation
