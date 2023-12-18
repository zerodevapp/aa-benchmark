pragma solidity ^0.8.0;

import "src/TestBase.sol";

import {
    SAFE_FACTORY_BYTECODE,
    SAFE_ACCOUNT_BYTECODE,
    SAFE_4337_MODULE_BYTECODE,
    SAFE_FACTORY,
    SAFE_4337_MODULE,
    ADD_MODULES_LIB_BYTECODE,
    ADD_MODULES_LIB,
    SAFE_ACCOUNT,
    SafeProxyFactory,
    Safe4337Module,
    Safe,
    AddModulesLib
} from "./SafeArtifacts.sol";

contract SoladyERC4337Test is AAGasProfileBase {
    SafeProxyFactory factory;

    function setUp() external {
        initializeTest("Safe");
        factory = SafeProxyFactory(SAFE_FACTORY);
        vm.etch(SAFE_FACTORY, SAFE_FACTORY_BYTECODE);
        vm.etch(SAFE_ACCOUNT, SAFE_ACCOUNT_BYTECODE);
        vm.etch(SAFE_4337_MODULE, SAFE_4337_MODULE_BYTECODE);
        vm.etch(ADD_MODULES_LIB, ADD_MODULES_LIB_BYTECODE);
        setAccount();
    }

    function fillData(address _to, uint256 _value, bytes memory _data) internal view override returns (bytes memory) {
        return abi.encodeWithSelector(Safe4337Module.executeUserOp.selector, _to, _value, _data, 0);
    }

    function getSignature(UserOperation memory _op) internal view override returns (bytes memory) {
        (bytes memory operation, uint48 validAfter, uint48 validUntil) = _getSafeOp(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, keccak256(operation));
        bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(validAfter, validUntil, signature);
    }

    function createAccount(address _owner) internal override {
        (bool success, bytes memory data) = address(factory).call(
            abi.encodeWithSelector(factory.createProxyWithNonce.selector, SAFE_ACCOUNT, _initializerCalldata(_owner), 0)
        );
    }

    function getAccountAddr(address _owner) internal view override returns (IAccount) {
        console2.log("_owner", _owner);
        bytes32 salt = keccak256(abi.encodePacked(keccak256(_initializerCalldata(_owner)), uint256(0)));
        bytes memory deploymentData = abi.encodePacked(factory.proxyCreationCode(), uint256(uint160(SAFE_ACCOUNT)));

        bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), SAFE_FACTORY, salt, keccak256(deploymentData)));

        return IAccount(address(uint160(uint256(rawAddress))));
    }

    function getInitCode(address _owner) internal view override returns (bytes memory) {
        return abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(factory.createProxyWithNonce.selector, SAFE_ACCOUNT, _initializerCalldata(_owner), 0)
        );
    }

    function getDummySig(UserOperation memory _op) internal pure override returns (bytes memory) {
        return
        hex"fffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c";
    }

    bytes32 private constant SAFE_OP_TYPEHASH = keccak256(
        "SafeOp(address safe,uint256 nonce,bytes initCode,bytes callData,uint256 callGasLimit,uint256 verificationGasLimit,uint256 preVerificationGas,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,bytes paymasterAndData,uint48 validAfter,uint48 validUntil,address entryPoint)"
    );

    struct EncodedSafeOpStruct {
        bytes32 typeHash;
        address safe;
        uint256 nonce;
        bytes32 initCodeHash;
        bytes32 callDataHash;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes32 paymasterAndDataHash;
        uint48 validAfter;
        uint48 validUntil;
        address entryPoint;
    }

    function _getSafeOp(UserOperation memory userOp)
        internal
        view
        returns (bytes memory operationData, uint48 validAfter, uint48 validUntil)
    {
        validAfter = 0;
        validUntil = type(uint48).max;
        EncodedSafeOpStruct memory encodedSafeOp = EncodedSafeOpStruct({
            typeHash: SAFE_OP_TYPEHASH,
            safe: userOp.sender,
            nonce: userOp.nonce,
            initCodeHash: keccak256(userOp.initCode),
            callDataHash: keccak256(userOp.callData),
            callGasLimit: userOp.callGasLimit,
            verificationGasLimit: userOp.verificationGasLimit,
            preVerificationGas: userOp.preVerificationGas,
            maxFeePerGas: userOp.maxFeePerGas,
            maxPriorityFeePerGas: userOp.maxPriorityFeePerGas,
            paymasterAndDataHash: keccak256(userOp.paymasterAndData),
            validAfter: validAfter,
            validUntil: validUntil,
            entryPoint: Safe4337Module(SAFE_4337_MODULE).SUPPORTED_ENTRYPOINT()
        });

        bytes32 safeOpStructHash;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Since the `encodedSafeOp` value's memory layout is identical to the result of `abi.encode`-ing the
            // individual `SafeOp` fields, we can pass it directly to `keccak256`. Additionally, there are 14
            // 32-byte fields to hash, for a length of `14 * 32 = 448` bytes.
            safeOpStructHash := keccak256(encodedSafeOp, 448)
        }

        operationData = abi.encodePacked(
            bytes1(0x19), bytes1(0x01), Safe4337Module(SAFE_4337_MODULE).domainSeparator(), safeOpStructHash
        );
    }

    function _initializerCalldata(address _owner) internal pure returns (bytes memory) {
        address[] memory ownerArr = new address[](1);
        ownerArr[0] = _owner;
        address[] memory moduleArr = new address[](1);
        moduleArr[0] = SAFE_4337_MODULE;
        return abi.encodeWithSelector(
            Safe.setup.selector,
            ownerArr,
            uint256(1),
            ADD_MODULES_LIB,
            abi.encodeWithSelector(AddModulesLib.enableModules.selector, moduleArr),
            SAFE_4337_MODULE,
            address(0),
            uint256(0),
            address(0)
        );
    }
}
