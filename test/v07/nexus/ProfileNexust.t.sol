pragma solidity ^0.8.0;

import {AAGasProfileBase07} from "src/TestBase07.sol";
import {DeployArtifact, ArtifactsLib} from "src/artifacts/ArtifactsLib.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import "./NexusArtifacts.sol";

contract ProfileNexus is AAGasProfileBase07 {
    INexusFactory public nexusFactory;
    address ecdsaValidator;

    address bootstrap;
    address nexus;

    function _initializeTest() internal override {
        name = "Nexus";

        ecdsaValidator = ArtifactsLib.deploy(DeployArtifact({initCode: K1_VALIDATOR_INITCODE, addr: K1_VALIDATOR_ADDR}));

        bootstrap =
            ArtifactsLib.deploy(DeployArtifact({initCode: NEXUS_BOOTSTRAP_INITCODE, addr: NEXUS_BOOTSTRAP_ADDR}));

        nexus = ArtifactsLib.deploy(DeployArtifact({initCode: NEXUS_INITCODE, addr: NEXUS_ADDR}));

        nexusFactory = INexusFactory(
            ArtifactsLib.deploy(DeployArtifact({initCode: NEXUS_FACTORY_INITCODE, addr: NEXUS_FACTORY_ADDR}))
        );
    }

    function _createAccount() internal override returns (address) {
        return nexusFactory.createAccount(initializeData(), bytes32(0));
    }

    function _fillData(address _recipient, uint256 _amount, bytes memory _data)
        internal
        override
        returns (bytes memory)
    {
        return abi.encodeWithSelector(INexus.execute.selector, bytes32(0), abi.encodePacked(_recipient, _amount, _data));
    }

    function _getNonce(PackedUserOperation memory _op) internal override returns (uint256) {
        return entryPoint.getNonce(address(account), 0);
    }

    function initializeData() internal returns (bytes memory) {
        return abi.encode(
            bootstrap,
            abi.encodeWithSelector(INexusBootstrap.initNexusWithDefaultValidator.selector, abi.encodePacked(owner))
        );
    }

    function _getAccount() internal override returns (address) {
        return nexusFactory.computeAccountAddress(initializeData(), bytes32(0));
    }

    function _getInitCode() internal override returns (bytes memory) {
        return abi.encodePacked(
            nexusFactory, abi.encodeWithSelector(INexusFactory.createAccount.selector, initializeData(), bytes32(0))
        );
    }

    function _getCreationGasLimit() internal override returns (uint256) {
        return 1000000;
    }

    function _getSignature(PackedUserOperation memory _op) internal override returns (bytes memory) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = vm.sign(key, hash);
        return abi.encodePacked(r, s, v);
    }
}
