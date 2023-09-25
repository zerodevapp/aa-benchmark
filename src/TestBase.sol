pragma solidity ^0.8.0;

import {IEntryPoint} from "I4337/IEntryPoint.sol";
import {UserOperation, IAccount} from "I4337/IAccount.sol";
import {IVerifyingPaymaster} from "src/interfaces/IVerifyingPaymaster.sol";
import {ENTRYPOINT_0_6_BYTECODE, CREATOR_0_6_BYTECODE} from "src/artifacts/EntrypointArtifacts.sol";
import {VERIFYINGPAYMASTER_BYTECODE, VERIFYINGPAYMASTER_ADDRESS} from "src/artifacts/VerifyingPaymasterArtifacts.sol";

import "solady/utils/ECDSA.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/MockERC20.sol";

interface VmModified {
    function cool(address _target) external;
    function keyExists(string calldata, string calldata) external returns (bool);
    function parseJsonKeys(string calldata json, string calldata key) external pure returns (string[] memory keys);
}

abstract contract AAGasProfileBase is Test {
    string public name;
    string public scenarioName;
    uint256 sum;
    string jsonObj;
    IEntryPoint public entryPoint;
    address payable public beneficiary;
    IAccount public account;
    address public owner;
    uint256 public key;
    IVerifyingPaymaster public paymaster;
    address public verifier;
    uint256 public verifierKey;
    bool public writeGasProfile = false;

    function (UserOperation memory) internal view returns(bytes memory) f;

    function initializeTest(string memory _name) internal {
        writeGasProfile = vm.envOr("WRITE_GAS_PROFILE", false);
        name = _name;
        entryPoint = IEntryPoint(payable(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)));
        vm.etch(address(entryPoint), ENTRYPOINT_0_6_BYTECODE);
        vm.etch(0x7fc98430eAEdbb6070B35B39D798725049088348, CREATOR_0_6_BYTECODE);
        beneficiary = payable(makeAddr("beneficiary"));
        vm.deal(beneficiary, 1e18);
        f = emptyPaymasterAndData;
        (verifier, verifierKey) = makeAddrAndKey("VERIFIER");
        paymaster = IVerifyingPaymaster(VERIFYINGPAYMASTER_ADDRESS);
        vm.etch(address(paymaster), VERIFYINGPAYMASTER_BYTECODE);
        vm.store(address(paymaster), bytes32(0), bytes32(uint256(uint160(verifier))));
    }

    function setAccount() internal {
        (owner, key) = makeAddrAndKey("Owner");
        account = getAccountAddr(owner);
        vm.deal(address(account), 1e18);
    }

    function fillUserOp(bytes memory _data) internal view returns (UserOperation memory op) {
        op.sender = address(account);
        op.nonce = entryPoint.getNonce(address(account), 0);
        op.callData = _data;
        op.callGasLimit = 1000000;
        op.verificationGasLimit = 1000000;
        op.preVerificationGas = 50000;
        op.maxFeePerGas = 1;
        op.maxPriorityFeePerGas = 1;
    }

    function signUserOpHash(uint256 _key, UserOperation memory _op) internal view returns (bytes memory signature) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, ECDSA.toEthSignedMessageHash(hash));
        signature = abi.encodePacked(r, s, v);
    }

    function executeUserOp(UserOperation memory _op, string memory _test, uint256 _value) internal {
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op;
        uint256 eth_before;
        if(_op.paymasterAndData.length > 0) {
            eth_before = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_before = entryPoint.balanceOf(address(account)) + address(account).balance;
        }
        //VmModified(address(vm)).cool(address(entryPoint));
        //VmModified(address(vm)).cool(address(account));
        entryPoint.handleOps(ops, beneficiary);
        uint256 eth_after;
        if(_op.paymasterAndData.length > 0) {
            eth_after = entryPoint.balanceOf(address(paymaster));
        } else {
            eth_after = entryPoint.balanceOf(address(account)) + address(account).balance + _value;
        }
        if (!writeGasProfile) {
            console.log("case - %s : ", _test, eth_before - eth_after);
        }
        if (writeGasProfile && bytes(scenarioName).length > 0) {
            uint256 gasUsed = eth_before - eth_after;
            vm.serializeUint(jsonObj, _test, gasUsed);
            sum += gasUsed;
        }
    }

    function testCreation() internal {
        UserOperation memory op = fillUserOp(fillData(address(0), 0, ""));
        op.initCode = getInitCode(owner);
        op.paymasterAndData = f(op);
        op.signature = getSignature(op);
        executeUserOp(op, "creation", 0);
    }

    function testTransferNative(address _recipient, uint256 _amount) internal {
        vm.skip(writeGasProfile);
        createAccount(owner);
        _amount = bound(_amount, 1, address(account).balance / 2);
        UserOperation memory op = fillUserOp(fillData(_recipient, _amount, ""));
        op.paymasterAndData = f(op);
        op.signature = getSignature(op);
        executeUserOp(op, "native", _amount);
    }

    function testTransferNative() internal {
        createAccount(owner);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        UserOperation memory op = fillUserOp(fillData(recipient, amount, ""));
        op.paymasterAndData = f(op);
        op.signature = getSignature(op);
        executeUserOp(op, "native", amount);
    }

    function testTransferERC20() internal {
        createAccount(owner);
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(account), 1e18);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        uint256 balance = mockERC20.balanceOf(recipient);
        UserOperation memory op = fillUserOp(
            fillData(address(mockERC20), 0, abi.encodeWithSelector(mockERC20.transfer.selector, recipient, amount))
        );
        op.paymasterAndData = f(op);
        op.signature = getSignature(op);
        executeUserOp(op, "erc20", 0);
        assertEq(mockERC20.balanceOf(recipient), balance + amount);
    }

    function testBenchmark1Vanila() external {
        scenarioName = "vanila";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function testBenchmark2Paymaster() external {
        scenarioName = "paymaster";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        entryPoint.depositTo{value: 100e18}(address(paymaster));
        f = validatePaymasterAndData;
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function testBenchmark3Deposit() external {
        scenarioName = "deposit";
        jsonObj = string(abi.encodePacked(scenarioName, " ", name));
        entryPoint.depositTo{value: 100e18}(address(account));
        testCreation();
        testTransferNative();
        testTransferERC20();
        if (writeGasProfile) {
            string memory res = vm.serializeUint(jsonObj, "sum", sum);
            console.log(res);
            vm.writeJson(res, string.concat("./results/", scenarioName, "_", name, ".json"));
        }
    }

    function emptyPaymasterAndData(UserOperation memory _op) internal pure returns (bytes memory ret) {}

    function validatePaymasterAndData(UserOperation memory _op) internal view returns (bytes memory ret) {
        bytes32 hash = paymaster.getHash(_op, 0, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierKey, ECDSA.toEthSignedMessageHash(hash));
        ret = abi.encodePacked(address(paymaster), uint256(0), uint256(0), r, s, uint8(v));
    }

    function getSignature(UserOperation memory _op) internal virtual returns (bytes memory);

    function fillData(address _to, uint256 _amount, bytes memory _data) internal virtual returns (bytes memory);

    function createAccount(address _owner) internal virtual;

    function getAccountAddr(address _owner) internal virtual returns (IAccount _account);

    function getInitCode(address _owner) internal virtual returns (bytes memory);
}
