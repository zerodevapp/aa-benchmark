pragma solidity ^0.8.0;

import {AAGasProfileBase07} from "src/TestBase07.sol";
import {DeployArtifact, ArtifactsLib} from "src/artifacts/ArtifactsLib.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import "./AlchemyArtifacts.sol";

contract ProfileAlchemy7702 is AAGasProfileBase07 {
    address implementation;

    function _initializeTest() internal override {
        name = "Alchemy 7702";

        implementation = ArtifactsLib.deploy(DeployArtifact({initCode: MODULAR_ACCOUNT_ALCHEMY_7702_INITCODE, addr: MODULAR_ACCOUNT_ALCHEMY_7702_ADDR}));

        vm.etch(owner, abi.encodePacked(hex"ef0100", address(implementation)));
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
            abi.encodeWithSignature("execute(address,uint256,bytes)", _recipient, _amount, _data);
    }

    function _getNonce(PackedUserOperation memory _op) internal override returns (uint256) {
        return entryPoint.getNonce(address(account), 1);
    }

    function initializeData() internal returns (bytes memory) {
        return hex"";
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
        return abi.encodePacked(bytes1(0xff), bytes1(0x00), r, s, v);
    }
}
