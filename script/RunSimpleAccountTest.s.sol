pragma solidity ^0.8.0;

import {SimpleAccountFactory, SimpleAccount} from "account-abstraction/samples/SimpleAccountFactory.sol";
import {UserOperation, IAccount} from "account-abstraction/core/EntryPoint.sol";
import {AATestScriptBase} from "./AATestScriptBase.s.sol";

contract RunSimpleAccountProfile is AATestScriptBase {
    SimpleAccountFactory factory = SimpleAccountFactory(0x9406Cc6185a346906296840746125a0E44976454);

    function fillData(address _to, uint256 _value, bytes memory _data) internal pure override returns(bytes memory) {
        return abi.encodeWithSelector(
            SimpleAccount.execute.selector,
            _to,
            _value,
            _data
        );
    }
    
    function getInitCode(address _owner) internal view override returns(bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                _owner,
                0
            )
        );
    }
    
    function getSignature(UserOperation memory _op) internal view override returns(bytes memory) {
        return signUserOpHash(key, _op);
    }

    function getAccountAddr(address _owner) internal view override returns(IAccount _account) {
        return IAccount(factory.getAddress(_owner,0));
    }
    
    function getCreationGasLimit() internal view override returns(uint256) {
        return 500000;
    }
}
