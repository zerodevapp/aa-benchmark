pragma solidity ^0.8.0;

import "src/TestBase.sol";
import {
    ERC7579Account,
    ERC7579Factory,
    IBootstrap,
    ERC7579_FACTORY_ADDRESS,
    ERC7579_FACTORY_CODE,
    ERC7579_ACCOUNT_ADDRESS,
    ERC7579_ACCOUNT_CODE,
    ECDSA_VALIDATOR_ADDRESS,
    ECDSA_VALIDATOR_CODE,
    BOOTSTRAP_ADDRESS,
    BOOTSTRAP_CODE
} from "./ERC7579Artifacts.sol";

contract ProfileERC7579 is AAGasProfileBase {
    address implementation;
    ERC7579Factory factory;
    address factoryOwner;
    address validator;
    IBootstrap bootstrap;

    function setUp() external {
        initializeTest("erc7579");
        factory = ERC7579Factory(ERC7579_FACTORY_ADDRESS);
        implementation = ERC7579_ACCOUNT_ADDRESS;
        vm.etch(ERC7579_FACTORY_ADDRESS, ERC7579_FACTORY_CODE);
        vm.etch(ERC7579_ACCOUNT_ADDRESS, ERC7579_ACCOUNT_CODE);
        validator = ECDSA_VALIDATOR_ADDRESS;
        vm.etch(ECDSA_VALIDATOR_ADDRESS, ECDSA_VALIDATOR_CODE);
        bootstrap = IBootstrap(BOOTSTRAP_ADDRESS);
        vm.etch(BOOTSTRAP_ADDRESS, BOOTSTRAP_CODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(ERC7579Account.execute.selector, _to, _value, _data);
    }

    function createAccount(address _owner) internal override {
        if (address(account).code.length == 0) {
            factory.createAccount(
                0,
                abi.encode(
                    address(bootstrap), abi.encodeCall(IBootstrap.singleInitMSA, (validator, abi.encodePacked(_owner)))
                )
            );
        }
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        return IAccount(
            factory.getAddress(
                0,
                abi.encode(
                    address(bootstrap), abi.encodeCall(IBootstrap.singleInitMSA, (validator, abi.encodePacked(_owner)))
                )
            )
        );
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                0,
                abi.encode(
                    address(bootstrap), abi.encodeCall(IBootstrap.singleInitMSA, (validator, abi.encodePacked(_owner)))
                )
            )
        );
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        return abi.encodePacked(validator, signUserOpHash(key, _op));
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }
}
