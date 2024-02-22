pragma solidity ^0.8.0;

import "src/TestBase.sol";

import {
    ALCHEMY_MODULAR_ACCOUNT_FACTORY_BYTECODE,
    ALCHEMY_MODULAR_ACCOUNT_BYTECODE,
    ALCHEMY_MODULAR_ACCOUNT,
    ALCHEMY_MODULAR_ACCOUNT_FACTORY,
    ALCHEMY_MODULAR_ACCOUNT_MULTI_OWNER_MODULE_BYTECODE,
    ALCHEMY_MODULAR_ACCOUNT_MULTI_OWNER_MODULE,
    AlchemyModularAccountFactory,
    AlchemyModularAccount
} from "./AlchemyModularAccountArtificats.sol";

contract AlchemyModularAccountTest is AAGasProfileBase {
    AlchemyModularAccountFactory factory;

    function setUp() external {
        initializeTest("AlchemyModularAccount");
        factory = AlchemyModularAccountFactory(ALCHEMY_MODULAR_ACCOUNT_FACTORY);
        vm.etch(ALCHEMY_MODULAR_ACCOUNT_FACTORY, ALCHEMY_MODULAR_ACCOUNT_FACTORY_BYTECODE);
        vm.etch(ALCHEMY_MODULAR_ACCOUNT, ALCHEMY_MODULAR_ACCOUNT_BYTECODE);
        vm.etch(ALCHEMY_MODULAR_ACCOUNT_MULTI_OWNER_MODULE, ALCHEMY_MODULAR_ACCOUNT_MULTI_OWNER_MODULE_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(AlchemyModularAccount.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        address[] memory owners = new address[](1);
        owners[0] = _owner;
        (bool success, bytes memory data) =
            address(factory).call(abi.encodeWithSelector(factory.createAccount.selector, 0, owners));
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        address[] memory owners = new address[](1);
        owners[0] = _owner;
        return IAccount(factory.getAddress(0, owners));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        address[] memory owners = new address[](1);
        owners[0] = _owner;
        return abi.encodePacked(address(factory), abi.encodeWithSelector(factory.createAccount.selector, 0, owners));
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
