pragma solidity ^0.8.0;

import "./TestBase.sol";
import {ECDSAKernelFactory, ECDSAValidator, KernelFactory} from "kernel/src/factory/ECDSAKernelFactory.sol";
import {AdminLessERC1967Factory} from "kernel/src/factory/AdminLessERC1967Factory.sol";
import {Kernel, Operation} from "kernel/src/Kernel.sol";
contract ProfileKernel is AAGasProfileBase {
    ECDSAKernelFactory factory;
    KernelFactory kernelFactory;
    ECDSAValidator validator;
    AdminLessERC1967Factory proxyFactory;
    function setUp() external {
        initializeTest();
        proxyFactory = new AdminLessERC1967Factory();
        kernelFactory = new KernelFactory(proxyFactory, entryPoint);
        validator = new ECDSAValidator();
        factory = new ECDSAKernelFactory(kernelFactory, validator, entryPoint);
        
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns(bytes memory) {
        return abi.encodeWithSelector(
            Kernel.execute.selector,
            _to,
            _value,
            _data,
            Operation.Call
        );
    }

    function createAccount(address _owner) internal override {
        if(address(account).code.length == 0)
            factory.createAccount(_owner, 0);
    }

    function getAccountAddr(address _owner) internal override returns(IAccount) {
        return IAccount(factory.getAccountAddress(_owner,0));
    }

    function getInitCode(address _owner) internal override returns(bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                _owner,
                0
            )
        );
    }

    function getSignature(UserOperation memory _op) internal override returns(bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), signUserOpHash(key, _op));
    }
}
