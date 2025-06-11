pragma solidity ^0.8.0;

import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {PackedUserOperation, IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {IVerifyingPaymaster} from "src/interfaces/IVerifyingPaymaster.sol";
import {ENTRYPOINT_0_7_INITCODE, ENTRYPOINT_0_7_ADDR} from "src/artifacts/EntrypointArtifacts.sol";
import {ArtifactsLib, DeployArtifact} from "src/artifacts/ArtifactsLib.sol";
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
    string public name;
    string public scenarioName;
    uint256 sum;
    string jsonObj;
    IEntryPoint public entryPoint;
    address payable public beneficiary;
    IAccount public account;
    address public owner;
    uint256 public key;
    IVerifyingPaymaster public paymaster; // skipping this for now
    address public verifier;
    uint256 public verifierKey;
    bool public writeGasProfile = false;


    function setUp() public virtual {
        entryPoint = IEntryPoint(ArtifactsLib.deploy(DeployArtifact({
            initCode : ENTRYPOINT_0_7_INITCODE,
            addr : ENTRYPOINT_0_7_ADDR
        })));
        (owner, key) = makeAddrAndKey("owner");
        beneficiary = payable(makeAddr("beneficiary"));
        _initializeTest();

        account = IAccount(_getAccount());
        vm.deal(address(account), 1e18);
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
            uint256 gasUsed = eth_before - eth_after;
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
        op.accountGasLimits = bytes32(abi.encodePacked(uint128(1000000), uint128(1000000)));
        op.preVerificationGas = 1000000;
        op.gasFees = bytes32(abi.encodePacked(uint128(1), uint128(1)));
        op.nonce = _getNonce(op);
        op.paymasterAndData = "";
        op.signature = _getSignature(op);
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
}