pragma solidity ^0.8.0;

import {UserOperation, IAccount} from "I4337/IAccount.sol";
import {AATestScriptBase} from "./AATestScriptBase.s.sol";
import {EtherspotWalletFactory, EtherspotWallet} from "test/etherspot/EtherspotArtifacts.sol";

contract RunEtherspotProfile is AATestScriptBase {
    EtherspotWalletFactory factory = EtherspotWalletFactory(0xBabd8268f9579b05E6042661081eF6015E1d34dE);

    function fillData(address _to, uint256 _value, bytes memory _data) internal override returns (bytes memory) {
        return abi.encodeWithSelector(EtherspotWallet.execute.selector, _to, _value, _data);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return signUserOpHash(key, _op);
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

    function getCreationGasLimit() internal view override returns (uint256) {
        return 300000;
    }
}
