pragma solidity ^0.8.0;

import "./TestBase.sol";
import {KernelFactory} from "kernel/src/factory/KernelFactory.sol";
import {Kernel, KernelStorage, Operation} from "kernel/src/Kernel.sol";
import {KernelLiteECDSA} from "kernel/src/lite/KernelLiteECDSA.sol";
import {ECDSAValidator } from "kernel/src/validator/ECDSAValidator.sol";
contract ProfileKernel is AAGasProfileBase {
    KernelLiteECDSA kernelImpl;
    KernelFactory factory;
    ECDSAValidator validator;
    address factoryOwner;
    function setUp() external {
        factoryOwner = makeAddr("factoryOwner");
        initializeTest();
        factory = new KernelFactory(factoryOwner);
        kernelImpl = new KernelLiteECDSA(entryPoint);
        vm.startPrank(factoryOwner);
        factory.setImplementation(address(kernelImpl), true);
        vm.stopPrank();
        validator = new ECDSAValidator();
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
            factory.createAccount(address(kernelImpl), abi.encodeWithSelector(KernelStorage.initialize.selector, validator, abi.encodePacked(_owner)), 0);
    }

    function getAccountAddr(address _owner) internal override returns(IAccount) {
        return IAccount(factory.getAccountAddress(abi.encodeWithSelector(KernelStorage.initialize.selector, validator, abi.encodePacked(_owner)),0));
    }

    function getInitCode(address _owner) internal override returns(bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                kernelImpl,
                abi.encodeWithSelector(KernelStorage.initialize.selector, validator, abi.encodePacked(_owner)),
                0
            )
        );
    }

    function getSignature(UserOperation memory _op) internal override returns(bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), signUserOpHash(key, _op));
    }
}
