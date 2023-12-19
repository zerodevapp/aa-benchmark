pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    Kernel,
    KernelFactory,
    Operation,
    KERNEL_FACTORY_ADDRESS,
    KERNEL_FACTORY_CODE,
    KERNEL_LITE_ADDRESS,
    KERNEL_LITE_CODE
} from "./KernelArtifacts.sol";

contract ProfileKernelLite is AAGasProfileBase {
    address kernelImpl;
    KernelFactory factory;
    address factoryOwner;

    function setUp() external {
        factoryOwner = address(0);
        initializeTest("kernelLite");
        factory = KernelFactory(KERNEL_FACTORY_ADDRESS);
        kernelImpl = KERNEL_LITE_ADDRESS;
        vm.etch(KERNEL_FACTORY_ADDRESS, KERNEL_FACTORY_CODE);
        vm.etch(KERNEL_LITE_ADDRESS, KERNEL_LITE_CODE);
        vm.startPrank(factoryOwner);
        factory.setImplementation(kernelImpl, true);
        vm.stopPrank();
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(Kernel.execute.selector, _to, _value, _data, Operation.Call);
    }

    function createAccount(address _owner) internal override {
        if (address(account).code.length == 0) {
            factory.createAccount(
                kernelImpl, abi.encodeWithSelector(Kernel.initialize.selector, address(0), abi.encodePacked(_owner)), 0
            );
        }
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        return IAccount(
            factory.getAccountAddress(
                abi.encodeWithSelector(Kernel.initialize.selector, address(0), abi.encodePacked(_owner)), 0
            )
        );
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                kernelImpl,
                abi.encodeWithSelector(Kernel.initialize.selector, address(0), abi.encodePacked(_owner)),
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
