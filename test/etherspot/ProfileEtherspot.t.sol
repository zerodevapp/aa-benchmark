pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    EtherspotWalletFactory,
    EtherspotWallet,
    ETHERSPOT_IMPL_ADDRESS,
    ETHERSPOT_IMPL_BYTECODE,
    ETHERSPOT_FACTORY_ADDRESS,
    ETHERSPOT_FACTORY_BYTECODE
} from "./EtherspotArtifacts.sol";

contract ProfileEtherspot is AAGasProfileBase {
    EtherspotWalletFactory factory;

    function setUp() external {
        initializeTest("etherspot");
        factory = EtherspotWalletFactory(ETHERSPOT_FACTORY_ADDRESS);
        vm.etch(ETHERSPOT_FACTORY_ADDRESS, ETHERSPOT_FACTORY_BYTECODE);
        vm.etch(ETHERSPOT_IMPL_ADDRESS, ETHERSPOT_IMPL_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(EtherspotWallet.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        (bool success, bytes memory data) =
            address(factory).call(abi.encodeWithSelector(factory.createAccount.selector, entryPoint, _owner, 0));
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        (bool success, bytes memory data) =
            address(factory).staticcall(abi.encodeWithSelector(factory.getAddress.selector, entryPoint, _owner, 0));
        require(success, "getAccountAddr failed");
        return IAccount(abi.decode(data, (address)));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory), abi.encodeWithSelector(factory.createAccount.selector, entryPoint, _owner, 0)
        );
    }

    function getDummySig(UserOperation memory _op) internal pure override returns(bytes memory) {
        return hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
