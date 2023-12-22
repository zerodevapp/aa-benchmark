pragma solidity ^0.8.0;

import "src/TestBase.sol";

import {
    LIGHT_ACCOUNT_FACTORY_BYTECODE,
    LIGHT_ACCOUNT_BYTECODE,
    LIGHT_ACCOUNT,
    LIGHT_ACCOUNT_FACTORY,
    LightAccountFactory, 
    LightAccount
} from "./LightAccountArtificats.sol";

contract LightAccountTest is AAGasProfileBase {
    LightAccountFactory factory;

    function setUp() external {
        initializeTest("LightAccount");
        factory = LightAccountFactory(LIGHT_ACCOUNT_FACTORY);
        vm.etch(LIGHT_ACCOUNT_FACTORY, LIGHT_ACCOUNT_FACTORY_BYTECODE);
        vm.etch(LIGHT_ACCOUNT, LIGHT_ACCOUNT_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(LightAccount.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        (bool success, bytes memory data) =
            address(factory).call(abi.encodeWithSelector(factory.createAccount.selector, _owner, 0));
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        return IAccount(factory.getAddress(_owner, 0));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return
            abi.encodePacked(address(factory), abi.encodeWithSelector(factory.createAccount.selector, _owner, 0));
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
