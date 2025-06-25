pragma solidity ^0.8.0;

import {AAGasProfileBase07} from "src/TestBase07.sol";
import {DeployArtifact, ArtifactsLib} from "src/artifacts/ArtifactsLib.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import "./KernelArtifacts.sol";

contract ProfileKernel7702 is AAGasProfileBase07 {
    IKernelFactory public kernelFactory;
    address ecdsaValidator;
    address kernel;

    function _initializeTest() internal override {
        name = "Kernel 3.3 7702";

        kernel = ArtifactsLib.deploy(DeployArtifact({initCode: KERNEL_3_3_INITCODE, addr: KERNEL_3_3_ADDR}));

        kernelFactory = IKernelFactory(
            ArtifactsLib.deploy(DeployArtifact({initCode: KERNEL_3_3_FACTORY_INITCODE, addr: KERNEL_3_3_FACTORY_ADDR}))
        );

        ecdsaValidator =
            ArtifactsLib.deploy(DeployArtifact({initCode: ECDSA_VALIDATOR_INITCODE, addr: ECDSA_VALIDATOR_ADDR}));

        vm.etch(owner, abi.encodePacked(hex"ef0100", address(kernel)));
    }

    function _createAccount() internal override returns (address) {
        return owner;
    }

    function _fillData(address _recipient, uint256 _amount, bytes memory _data)
        internal
        override
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(IKernel.execute.selector, bytes32(0), abi.encodePacked(_recipient, _amount, _data));
    }

    function _getNonce(PackedUserOperation memory _op) internal override returns (uint256) {
        return entryPoint.getNonce(address(account), 0);
    }

    function initializeData() internal returns (bytes memory) {
        return abi.encodeWithSelector(
            IKernel.initialize.selector,
            bytes21(abi.encodePacked(bytes1(0x01), ecdsaValidator)),
            address(0),
            abi.encodePacked(owner),
            hex"",
            new bytes[](0)
        );
    }

    function _getAccount() internal override returns (address) {
        return owner;
    }

    function _getInitCode() internal override returns (bytes memory) {
        return hex"";
    }

    function _getCreationGasLimit() internal override returns (uint256) {
        return 1000000;
    }

    function _getSignature(PackedUserOperation memory _op) internal override returns (bytes memory) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = vm.sign(key, ECDSA.toEthSignedMessageHash(hash));
        return abi.encodePacked(r, s, v);
    }
}
