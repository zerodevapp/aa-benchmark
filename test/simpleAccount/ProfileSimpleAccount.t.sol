pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    SimpleAccountFactory,
    SimpleAccount,
    SIMPLE_ACCOUNT_FACTORY_ADDRESS,
    SIMPLE_ACCOUNT_IMPL_ADDRESS,
    SIMPLE_ACCOUNT_FACTORY_BYTECODE,
    SIMPLE_ACCOUNT_IMPL_BYTECODE
} from "./SimpleAccountArtifacts.sol";

contract ProfileSimpleAccount is AAGasProfileBase {
    SimpleAccountFactory factory;

    function setUp() external {
        initializeTest();
        factory = SimpleAccountFactory(SIMPLE_ACCOUNT_FACTORY_ADDRESS);
        vm.etch(address(factory), SIMPLE_ACCOUNT_FACTORY_BYTECODE);
        vm.etch(SIMPLE_ACCOUNT_IMPL_ADDRESS, SIMPLE_ACCOUNT_IMPL_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns (bytes memory) {
        return abi.encodeWithSelector(SimpleAccount.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal override returns (bytes memory) {
        return signUserOpHash(key, _op);
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
