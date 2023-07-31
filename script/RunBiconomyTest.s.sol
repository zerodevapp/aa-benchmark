pragma solidity ^0.8.0;

import {EtherspotWalletFactory, EtherspotWallet} from "etherspot-prime-contracts/wallet/EtherspotWalletFactory.sol";
import {UserOperation, IAccount} from "account-abstraction/core/EntryPoint.sol";
import {AATestScriptBase} from "./AATestScriptBase.s.sol";

interface SmartAccountFactory {
    function deployCounterFactualAccount(
        address _owner,
        uint256 _index
    ) external returns (address proxy);
    function getAddressForCounterFactualAccount(
        address _owner,
        uint256 _index
    ) external view returns (address _account);
}

interface SmartAccount {
    function executeCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;
}

contract RunBiconomyProfile is AATestScriptBase {
    SmartAccountFactory factory = SmartAccountFactory(0x000000F9eE1842Bb72F6BBDD75E6D3d4e3e9594C);
    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns(bytes memory) {
        return abi.encodeWithSelector(
            SmartAccount.executeCall.selector,
            _to,
            _value,
            _data
        );
    }
    function getSignature(UserOperation memory _op) internal view override returns(bytes memory) {
        return signUserOpHash(key, _op);
    }
    function getAccountAddr(address _owner) internal view override returns(IAccount) {
        (bool success, bytes memory data) = address(factory).staticcall(abi.encodeWithSelector(factory.getAddressForCounterFactualAccount.selector, _owner, 0));
        require(success, "getAccountAddr failed");
        return IAccount(abi.decode(data, (address)));
    }

    function getInitCode(address _owner) internal view override returns(bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.deployCounterFactualAccount.selector,
                _owner,
                0
            )
        );
    }
    
    function getCreationGasLimit() internal view override returns(uint256) {
        return 300000;
    }
}
