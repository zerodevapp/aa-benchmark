pragma solidity ^0.8.0;

import "account-abstraction/core/EntryPoint.sol";
import "solady/utils/ECDSA.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import "src/MockERC20.sol";

abstract contract AAGasProfileBase is Test{
    EntryPoint public entryPoint;
    address payable public beneficiary;
    IAccount public account;
    address public owner;
    uint256 public key;

    function initializeTest() internal {
        entryPoint = new EntryPoint();
        beneficiary = payable(makeAddr("beneficiary"));
    }

    function setAccount() internal {
        (owner, key) = makeAddrAndKey("Owner");
        account = getAccountAddr(owner);
        vm.deal(address(account), 1e18);
    }

    function fillUserOp(bytes memory _data) internal view returns(UserOperation memory op) {
        op.sender = address(account);
        op.nonce = entryPoint.getNonce(address(account), 0);
        op.callData = _data;
        op.callGasLimit = 10000000;
        op.verificationGasLimit = 10000000;
        op.preVerificationGas = 50000;
        op.maxFeePerGas = 50000;
        op.maxPriorityFeePerGas = 1;
    }
    
    function signUserOpHash(uint256 _key, UserOperation memory _op)
        internal
        view
        returns (bytes memory signature)
    {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, ECDSA.toEthSignedMessageHash(hash));
        signature = abi.encodePacked(r, s, v);
    }

    function executeUserOp(UserOperation memory _op) internal {
        uint256 gas = gasleft();
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op;
        entryPoint.handleOps(ops, beneficiary);
        gas = gas - gasleft();
        console.log("Gas Used: ", gas);
    }

    function testCreation() external {
        UserOperation memory op = fillUserOp(fillData(address(0), 0, ""));
        op.initCode = getInitCode(owner);
        op.signature = getSignature(op);
        executeUserOp(op);
    }

    function testTransferNative(address _recipient, uint256 _amount) external {
        createAccount(owner);
        _amount = bound(_amount, 1, address(account).balance/2);
        UserOperation memory op = fillUserOp(fillData(_recipient, _amount, ""));
        op.signature = getSignature(op);
        executeUserOp(op);
    }
    
    function testTransferNative() external {
        createAccount(owner);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        UserOperation memory op = fillUserOp(fillData(recipient, amount, ""));
        op.signature = getSignature(op);
        executeUserOp(op);
    }

    function testTransferERC20() external {
        createAccount(owner);
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.mint(address(account), 1e18);
        uint256 amount = 5e17;
        address recipient = makeAddr("recipient");
        UserOperation memory op = fillUserOp(fillData(address(mockERC20), 0, abi.encodeWithSelector(mockERC20.transfer.selector, recipient, amount)));
        op.signature = getSignature(op);
        executeUserOp(op);
    }

    function getSignature(UserOperation memory _op) internal virtual returns(bytes memory);

    function fillData(address _to, uint256 _amount, bytes memory _data) internal virtual returns(bytes memory);

    function createAccount(address _owner) internal virtual;

    function getAccountAddr(address _owner) internal virtual returns(IAccount _account);

    function getInitCode(address _owner) internal virtual returns(bytes memory);
}
