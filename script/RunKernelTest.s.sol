pragma solidity ^0.8.0;

import {ECDSAKernelFactory} from "kernel/src/factory/ECDSAKernelFactory.sol";
import {EntryPoint, UserOperation, IAccount} from "account-abstraction/core/EntryPoint.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Kernel, Operation} from "kernel/src/Kernel.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {MockNFT} from "src/MockNFT.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import {AATestScriptBase} from "./AATestScriptBase.s.sol";

interface SafeMintNFT {
    function totalSupply() external view returns(uint256);
    function safeMint(address _to) external;
}

contract RunKernelProfile is AATestScriptBase {
    ECDSAKernelFactory factory = ECDSAKernelFactory(0x4caf43D403Cf2e9cDE274E58343d3D0DCA1C571d);

    function fillData(address _to, uint256 _value, bytes memory _data) internal pure override returns(bytes memory) {
        return abi.encodeWithSelector(
            Kernel.execute.selector,
            _to,
            _value,
            _data,
            Operation.Call
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
        return abi.encodePacked(bytes4(0x00000000), signUserOpHash(key, _op));
    }

    function getAccountAddr(address _owner) internal view override returns(IAccount _account) {
        return IAccount(factory.getAccountAddress(_owner, 0));
    }
}
