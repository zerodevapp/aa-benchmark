pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    MinimalAccountFactory,
    MINIMAL_ACCOUNT_FACTORY_ADDRESS,
    MINIMAL_ACCOUNT_FACTORY_BYTECODE
} from "./MinimalAccountArtifacts.sol";

contract ProfileMinimalAccount is AAGasProfileBase {
    MinimalAccountFactory factory;

    function setUp() external {
        initializeTest("minimalAccount");
        factory = MinimalAccountFactory(MINIMAL_ACCOUNT_FACTORY_ADDRESS);
        vm.etch(address(factory), MINIMAL_ACCOUNT_FACTORY_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns (bytes memory) {
        return abi.encodePacked(_to, uint128(_value), _data);
    }

    function getSignature(UserOperation memory _op) internal override returns (bytes memory) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, ECDSA.toEthSignedMessageHash(hash));
        return abi.encodePacked(v, r, s);
    }

    function createAccount(address _owner) internal override {
        factory.createAccount(_owner, 0);
    }

    function getAccountAddr(address _owner) internal override returns (IAccount) {
        return IAccount(factory.getAddress(_owner, 0));
    }

    function getInitCode(address _owner) internal override returns (bytes memory) {
        return abi.encodePacked(address(factory), abi.encodeWithSelector(factory.createAccount.selector, _owner, 0));
    }
}
