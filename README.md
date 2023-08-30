# AA benchmark

AA benchmark framework to check gas efficiency of the wallet implementation

This framework only applies to ECDSA based signature but willing to expand further as a future work.

**Disclaimer** local transaction gas results will differ from those happen on-chain, the result of the benchmark only represents the high-level gas-efficiency and does not guarantee the exact gas cost of the userOp

## How to add your implementation

1. fork this repo
2. add your test file to `./test/`, create folder if you needed
3. inherit `src/TestBase.sol` and override `getSignature()`, `fillData()`, `createAccount()`, `getAccountAddr()`, `getInitCode()`
    - getSignature() : should return appropriate signature based on `_op` (eg. should return ecdsa signature)
    - fillData() : should return appropriate data for userOp.callData
    - createAccount() : should create the wallet. skip this if your factory only allow creation through entryPoint
    - getAccountAddr() : should return address for the predicted wallet when `_owner` is given.
    - getInitCode() : should return userOp.initCode
4. write `setUp()` function to set the initial test condition. like deploying the factory and implementation contract. **NOTICE** since we don't want this repo to have bunch of dependencies, please use vm.etch and use your predicted address, bytecode to deploy the contract instead of importing your whole code. this will also make you easy to test without compiler setup fiasco
5. run `WRITE_GAS_PROFILE=true forge test -vv` this will show you the results of the benchmark and also write json file to `results/`
6. make sure the contract you added to work properly and make a PR to this repository

## Results(for vanila only)

|                  | Creation | Native transfer | ERC20 transfer | Total  |
| ---------------- | -------- | --------------- | -------------- | ------ |
| SimpleAccount    | 410061   | 97690           | 86754          | 594505 |
| Kernel v2.0      | 366662   | 106800          | 95877          | 569339 |
| Kernel v2.1-lite | 256965   | 97331           | 86121          | 440417 |
| Kernel v2.1      | 291413   | 103240          | 92289          | 486942 |
| Biconomy         | 296892   | 100780          | 89577          | 487249 |
| Etherspot        | 305769   | 100091          | 89172          | 495032 |

### TODO
- [ ] add paymaster benchmark
- [ ] allow non-ecdsa benchmark
    - [ ] maybe RSA?
- [ ] add CI for cheking/getting the gas result
- [ ] L2 Gas cost calculation
