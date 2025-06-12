pragma solidity ^0.8.0;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {IEntryPointSimulations} from "account-abstraction/interfaces/IEntryPointSimulations.sol";
import {PackedUserOperation, IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {IVerifyingPaymaster} from "src/interfaces/IVerifyingPaymaster.sol";
import {ENTRYPOINT_0_7_INITCODE, ENTRYPOINT_0_7_ADDR} from "src/artifacts/EntrypointArtifacts.sol";
import {ENTRYPOINT_SIMULATION_0_7_INITCODE, ENTRYPOINT_SIMULATION_0_7_ADDR} from "src/artifacts/EntrypointArtifacts.sol";
import {ArtifactsLib, DeployArtifact} from "src/artifacts/ArtifactsLib.sol";
import {LibBytes} from "solady/utils/LibBytes.sol";
import "solady/utils/ECDSA.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/MockERC20.sol";

interface VmModified {
    function cool(address _target) external;
    function keyExists(string calldata, string calldata) external returns (bool);
    function parseJsonKeys(string calldata json, string calldata key) external pure returns (string[] memory keys);
}

uint256 constant OV_FIXED = 21000;
uint256 constant OV_PER_USEROP = 18300;
uint256 constant OV_PER_WORD = 4;
uint256 constant OV_PER_ZERO_BYTE = 4;
uint256 constant OV_PER_NONZERO_BYTE = 16;


abstract contract AAGasProfileBase07 is Test {
    error Gas(uint256);
    string public name;
    string public scenarioName;
    uint256 sum;
    string jsonObj;
    IEntryPoint public entryPoint;
    IEntryPointSimulations public simulation;
    address payable public beneficiary;
    IAccount public account;
    address public owner;
    uint256 public key;
    IVerifyingPaymaster public paymaster; // skipping this for now
    address public verifier;
    uint256 public verifierKey;
    bool public writeGasProfile = false;


    function setUp() public virtual {
        writeGasProfile = vm.envOr("WRITE_GAS_PROFILE", false);
        entryPoint = IEntryPoint(ArtifactsLib.deploy(DeployArtifact({
            initCode : ENTRYPOINT_0_7_INITCODE,
            addr : ENTRYPOINT_0_7_ADDR
        })));

        simulation = IEntryPointSimulations(ArtifactsLib.deploy(DeployArtifact({
            initCode : ENTRYPOINT_SIMULATION_0_7_INITCODE,
            addr :  ENTRYPOINT_SIMULATION_0_7_ADDR
        })));
        (owner, key) = makeAddrAndKey("owner");
        beneficiary = payable(makeAddr("beneficiary"));
        _initializeTest();

        account = IAccount(_getAccount());
        vm.deal(address(account), 1e18);
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
    }

    function pack(PackedUserOperation memory _op) internal pure returns (bytes memory) {
        bytes memory packed = abi.encode(
            _op.sender,
            _op.nonce,
            _op.initCode,
            _op.callData,
            _op.accountGasLimits,
            _op.preVerificationGas,
            _op.gasFees,
            _op.paymasterAndData,
            _op.signature
        );
        return packed;
    }

    function calldataCost(bytes memory _packed) internal pure returns (uint256) {
       uint256 cost = 0;
        for (uint256 i = 0; i < _packed.length; i++) {
            if (_packed[i] == 0) {
                cost += OV_PER_ZERO_BYTE;
            } else {
                cost += OV_PER_NONZERO_BYTE;
            }
        }
        return cost;
    }

    function _initializeTest() internal virtual;

    function _createAccount() internal virtual returns (address);

    function _fillData(address _recipient, uint256 _amount, bytes memory _data) internal virtual returns (bytes memory);

    function _getNonce(PackedUserOperation memory _op) internal virtual returns (uint256);

    function _getAccount() internal virtual returns (address);

    function _getInitCode() internal virtual returns (bytes memory);

    function _getCreationGasLimit() internal virtual returns (uint256);

    function _getSignature(PackedUserOperation memory _op) internal virtual returns (bytes memory);

    function executeUserOp(PackedUserOperation memory _op, string memory _test, uint256 _value) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = _op;
        uint256 eth_before;
        if (_op.paymasterAndData.length > 0) {
            eth_before = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_before = entryPoint.balanceOf(address(account)) + address(account).balance;
        }
        entryPoint.handleOps(ops, beneficiary);
        uint256 eth_after;
        if (_op.paymasterAndData.length > 0) {
            eth_after = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_after = entryPoint.balanceOf(address(account)) + address(account).balance;
        }
        uint256 eth_used = eth_before - eth_after - _value;
        if (!writeGasProfile) {
            console.log("case - %s", _test);
            console.log("  gasUsed       : ", eth_before - eth_after - _value);
            console.log("  calldatacost  : ", calldataCost(pack(_op)));
        }
        if (writeGasProfile && bytes(scenarioName).length > 0) {
            uint256 gasUsed = eth_before - eth_after - _value;
            vm.serializeUint(jsonObj, _test, gasUsed);
            sum += gasUsed;
        }
    }

    function fillUserOp(bytes memory _data) internal virtual returns (PackedUserOperation memory op) {
        op.sender = address(account);
        if (address(account).code.length == 0) {
            op.initCode = _getInitCode();
        }
        op.callData = _data;
        op.accountGasLimits = bytes32(abi.encodePacked(uint128(100000), uint128(100000)));
        op.preVerificationGas = 21000;
        op.gasFees = bytes32(abi.encodePacked(uint128(1), uint128(1)));
        op.nonce = _getNonce(op);
        op.paymasterAndData = "";
        op.signature = _getSignature(op);
        op.accountGasLimits = calculateUserOpGasLimits(op);
        op.signature = _getSignature(op);
    }

    function calculateUserOpGasLimits(PackedUserOperation memory _op) internal returns(bytes32 res) {
        uint128 validationGasLimit = 50000; // offset
        try this.getVerificationGasLimit(_op) {} catch (bytes memory reason) {
            require(reason.length == 36, "Not proper error");
            uint256 validation = uint256(bytes32(LibBytes.slice(reason, 4, 36)));
            validationGasLimit += uint128(validation);
        }

        uint128 executionGasLimit = 5000;
        try this.getExecutionGasLimit(_op.callData) {} catch (bytes memory reason) {
            require(reason.length == 36, "Not proper error");
            executionGasLimit += uint128(uint256(bytes32(LibBytes.slice(reason, 4, 36))));
        }

        return bytes32(abi.encodePacked(validationGasLimit, executionGasLimit));
    }

    function getVerificationGasLimit(PackedUserOperation calldata op) external {
        vm.startPrank(address(entryPoint));
        uint256 used = gasleft();
        if(op.initCode.length > 0) {
            address factory = address(bytes20(op.initCode));
            (bool success, ) = factory.call{gas: 1000000}(op.initCode[20:]);
            require(success);
        }
        uint256 res = account.validateUserOp{gas: 1000000}(op, bytes32(0), op.paymasterAndData.length);
        used -= gasleft();
        vm.stopPrank();
        require(uint160(res) == 1);
        revert Gas(used);
    }
    
    function getExecutionGasLimit(bytes calldata callData) external {
        vm.startPrank(address(entryPoint));
        uint256 used = gasleft();
        (bool success, ) = address(account).call{gas: 1000000}(callData);
        used -= gasleft();
        vm.stopPrank();
        require(success);
        revert Gas(used);
    }

    function testCreation() public {
        PackedUserOperation memory op = fillUserOp(_fillData(address(0), 0, ""));
        executeUserOp(op, "creation", 0);
    }

    function testTransferNative() public {
        _createAccount();
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        PackedUserOperation memory op = fillUserOp(_fillData(recipient, amount, ""));
        executeUserOp(op, "native", amount);
    }

    function testTransferERC20(address _recipient, uint256 _amount) public {
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(account), 1e18);
        _createAccount();
        _amount = bound(_amount, 1, mockERC20.balanceOf(address(account)));
        PackedUserOperation memory op = fillUserOp(_fillData(address(mockERC20), 0, abi.encodeWithSelector(mockERC20.transfer.selector, _recipient, _amount)));
        executeUserOp(op, "erc20", 0);
    }

    function testBenchmark1Vanila() external {
        address recipient = makeAddr("Recipient");
        uint256 amount = 1000;
        scenarioName = "vanila";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        testCreation();
        testTransferNative();
        testTransferERC20(recipient, amount);
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }
}
