pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    BCNMY_IMPL,
    BCNMY_IMPL_BYTECODE,
    BCNMY_FACTORY,
    BCNMY_FACTORY_BYTECODE,
    SmartAccountFactory,
    SmartAccount
} from "./BcnmyArtifacts.sol";

contract ProfileBcnmy is AAGasProfileBase {
    SmartAccountFactory factory;

    function setUp() external {
        initializeTest("biconomy");
        factory = SmartAccountFactory(BCNMY_FACTORY);
        vm.etch(BCNMY_FACTORY, BCNMY_FACTORY_BYTECODE);
        vm.etch(BCNMY_IMPL, BCNMY_IMPL_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns (bytes memory) {
        return abi.encodeWithSelector(SmartAccount.executeCall.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal override returns (bytes memory) {
        return signUserOpHash(key, _op);
    }

    function createAccount(address _owner) internal override {
        (bool success, bytes memory data) =
            address(factory).call(abi.encodeWithSelector(factory.deployCounterFactualAccount.selector, _owner, 0));
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        (bool success, bytes memory data) = address(factory).staticcall(
            abi.encodeWithSelector(factory.getAddressForCounterFactualAccount.selector, _owner, 0)
        );
        require(success, "getAccountAddr failed");
        return IAccount(abi.decode(data, (address)));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory), abi.encodeWithSelector(factory.deployCounterFactualAccount.selector, _owner, 0)
        );
    }
}
