pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    Kernel,
    KernelFactory,
    Operation,
    KERNEL_FACTORY_ADDRESS,
    KERNEL_FACTORY_CODE,
    KERNEL_ADDRESS,
    KERNEL_CODE,
    KERNEL_ECDSA_VALIDATOR_ADDRESS,
    KERNEL_ECDSA_VALIDATOR_CODE
} from "./KernelArtifacts.sol";

contract ProfileKernel is AAGasProfileBase {
    Kernel kernelImpl;
    KernelFactory factory;
    address validator;
    address factoryOwner;

    function setUp() external {
        factoryOwner = address(0);
        initializeTest("kernelv2_1");
        factory = KernelFactory(KERNEL_FACTORY_ADDRESS);
        vm.etch(KERNEL_FACTORY_ADDRESS, KERNEL_FACTORY_CODE);
        kernelImpl = Kernel(KERNEL_ADDRESS);
        vm.etch(KERNEL_ADDRESS, KERNEL_CODE);
        vm.startPrank(factoryOwner);
        factory.setImplementation(address(kernelImpl), true);
        vm.stopPrank();
        validator = KERNEL_ECDSA_VALIDATOR_ADDRESS;
        vm.etch(KERNEL_ECDSA_VALIDATOR_ADDRESS, KERNEL_ECDSA_VALIDATOR_CODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(Kernel.execute.selector, _to, _value, _data, Operation.Call);
    }

    function createAccount(address _owner) internal override {
        if (address(account).code.length == 0) {
            factory.createAccount(
                address(kernelImpl),
                abi.encodeWithSelector(Kernel.initialize.selector, validator, abi.encodePacked(_owner)),
                0
            );
        }
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        return IAccount(
            factory.getAccountAddress(
                abi.encodeWithSelector(Kernel.initialize.selector, validator, abi.encodePacked(_owner)), 0
            )
        );
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                kernelImpl,
                abi.encodeWithSelector(Kernel.initialize.selector, validator, abi.encodePacked(_owner)),
                0
            )
        );
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), signUserOpHash(key, _op));
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"00000000fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
