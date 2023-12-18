pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    SOULWALLETCORE_IMPL,
    SOULWALLETCORE_IMPL_BYTECODE,
    SOULWALLETCORE_FACTORY,
    SOULWALLETCORE_FACTORY_BYTECODE,
    SoulWalletFactory,
    SoulWalletCore
} from "./SoulWalletCoreArtifacts.sol";

contract ProfileBcnmy is AAGasProfileBase {
    SoulWalletFactory factory;

    function setUp() external {
        initializeTest("SoulWalletCore");
        factory = SoulWalletFactory(SOULWALLETCORE_FACTORY);
        vm.etch(SOULWALLETCORE_FACTORY, SOULWALLETCORE_FACTORY_BYTECODE);
        vm.etch(SOULWALLETCORE_IMPL, SOULWALLETCORE_IMPL_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal pure override returns (bytes memory) {
        return abi.encodeWithSelector(SoulWalletCore.execute.selector, _to, _value, _data);
    }

    function _packHash(address _account, bytes32 hash) private view returns (bytes32) {
        uint256 _chainid;
        assembly {
            _chainid := chainid()
        }
        return keccak256(abi.encode(hash, _account, _chainid));
    }

    function _packSignature(address validatorAddress, bytes memory signature) private pure returns (bytes memory) {
        uint32 sigLen = uint32(signature.length);
        return abi.encodePacked(validatorAddress, sigLen, signature);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        bytes32 userOpHash = entryPoint.getUserOpHash(_op);

        bytes32 hash = ECDSA.toEthSignedMessageHash(_packHash(_op.sender, userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        return _packSignature(address(0), abi.encodePacked(r, s, v));
    }

    function createAccount(address _owner) internal override {
        bytes32 ownerBytes32 = bytes32(uint256(uint160(_owner)));
        bytes memory initializer = abi.encodeWithSelector(SoulWalletCore.initialize.selector, ownerBytes32);

        (bool success,) = address(factory).call(abi.encodeWithSelector(factory.createWallet.selector, initializer, 0));
        (success);
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        bytes32 ownerBytes32 = bytes32(uint256(uint160(_owner)));
        bytes memory initializer = abi.encodeWithSelector(SoulWalletCore.initialize.selector, ownerBytes32);
        (bool success, bytes memory data) =
            address(factory).staticcall(abi.encodeWithSelector(factory.getWalletAddress.selector, initializer, 0));
        require(success, "getAccountAddr failed");
        return IAccount(abi.decode(data, (address)));
    }

    function getInitCode(address _owner) internal pure override returns (bytes memory) {
        bytes32 ownerBytes32 = bytes32(uint256(uint160(_owner)));
        bytes memory initializer = abi.encodeWithSelector(SoulWalletCore.initialize.selector, ownerBytes32);
        return abi.encodePacked(
            SOULWALLETCORE_FACTORY, abi.encodeWithSelector(SoulWalletFactory.createWallet.selector, initializer, 0)
        );
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        (_op);
        return
        hex"0000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    }
}
