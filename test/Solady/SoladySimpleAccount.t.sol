pragma solidity ^0.8.0;

import "src/TestBase.sol";

import {
    SOLADY_ERC4337_BYTECODE,
    SOLADY_ERC4337_FACTORY_BYTECODE,
    SOLADY_FACTORY,
    SOLADY_ERC4337,
    ERC4337Factory,
    ERC4337
} from "./SoladyArtifacts.sol";

contract SoladyERC4337Test is AAGasProfileBase {
    ERC4337Factory factory;

    function setUp() external {
        initializeTest("solady");
        factory = ERC4337Factory(SOLADY_FACTORY);
        vm.etch(SOLADY_FACTORY, SOLADY_ERC4337_FACTORY_BYTECODE);
        vm.etch(SOLADY_ERC4337, SOLADY_ERC4337_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(ERC4337.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        (bool success, bytes memory data) =
            address(factory).call(abi.encodeWithSelector(factory.deployDeterministic.selector, _owner, 0));
    }
    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        bytes32 hash = factory.initCodeHash();
        return IAccount(predictDeterministicAddress(hash,0 , address(SOLADY_FACTORY)));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory), abi.encodeWithSelector(factory.deployDeterministic.selector, _owner, 0)
        );
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }

    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
    internal
    pure
    returns (address predicted)
{
    /// @solidity memory-safe-assembly
    assembly {
        // Compute and store the bytecode hash.
        mstore8(0x00, 0xff) // Write the prefix.
        mstore(0x35, hash)
        mstore(0x01, shl(96, deployer))
        mstore(0x15, salt)
        predicted := keccak256(0x00, 0x55)
        mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
    }
}
}
