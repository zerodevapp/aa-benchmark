pragma solidity ^0.8.0;

import {EntryPoint, UserOperation, IAccount} from "account-abstraction/core/EntryPoint.sol";
import {VerifyingPaymaster} from "account-abstraction/samples/VerifyingPaymaster.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ERC721} from "solady/tokens/ERC721.sol";
import {MockNFT} from "src/MockNFT.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

interface SafeMintNFT {
    function totalSupply() external view returns (uint256);
    function safeMint(address _to) external;
}

abstract contract AATestScriptBase is Script {
    EntryPoint entryPoint = EntryPoint(payable(address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789)));
    ERC20 chainlink = ERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    address mockNFT = 0xc78dF533Dd382567A3308dfa8c4B08F33A1A6014;

    address payable beneficiary = payable(address(0x9775137314fE595c943712B0b336327dfa80aE8A));
    address recipient = makeAddr("recipient");
    address owner;
    uint256 key;

    address verifier;
    uint256 verifierKey;
    IAccount account;
    VerifyingPaymaster paymaster = VerifyingPaymaster(0xe1Fb85Ec54767ED89252751F6667CF566b16f1F0);
    function (UserOperation memory) internal view returns(bytes memory) f;

    function deployPaymaster() external {
        (verifier, verifierKey) = makeAddrAndKey("VERIFIER");
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        paymaster = new VerifyingPaymaster(entryPoint, verifier);
        vm.stopBroadcast();
    }

    function runWithNoDeposit() external {
        f = emptyPaymasterAndData;
        (owner, key) = makeAddrAndKey("Owner-No-deposit");
        account = getAccountAddr(owner);
        // deposit some gas eth
        console.log("account address: %s", address(account));
        console.log("owner address: %s", owner);
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        //fundWallet();
        //createAndSend1Wei();
        send1Wei();
        sendToken();
        uint256 nft = mintNFT();
        mintNFTWithEOA();
        transferNFT(nft);
        vm.stopBroadcast();
    }

    function runWithLargeDeposit() external {
        f = emptyPaymasterAndData;
        (owner, key) = makeAddrAndKey("OWNER");
        account = getAccountAddr(owner);
        // deposit some gas eth
        entryPoint.depositTo{value: 1e16}(address(account));
        console.log("account address: %s", address(account));
        console.log("owner address: %s", owner);
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        fundWallet();
        createAndSend1Wei();
        send1Wei();
        sendToken();
        uint256 nft = mintNFT();
        mintNFTWithEOA();
        transferNFT(nft);
        vm.stopBroadcast();
    }

    function runPaymasterTest() external {
        (verifier, verifierKey) = makeAddrAndKey("VERIFIER");
        f = validatePaymasterAndData;
        (owner, key) = makeAddrAndKey("Owner-Paymaster");
        account = getAccountAddr(owner);
        // deposit some gas eth
        console.log("account address: %s", address(account));
        console.log("owner address: %s", owner);
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);
        entryPoint.depositTo{value: 1e16}(address(paymaster));
        fundWallet();
        createAndSend1Wei();
        send1Wei();
        sendToken();
        uint256 nft = mintNFT();
        mintNFTWithEOA();
        transferNFT(nft);
        vm.stopBroadcast();
    }

    function fundWallet() internal {
        // deposit some eth for sending
        address(account).call{value: 1e16}("");
        // depsoit some token for sending
        chainlink.transfer(address(account), 1e18);
        recipient.call{value: 1}("");
        chainlink.transfer(recipient, 1);
    }

    function createAndSend1Wei() internal {
        require(address(account).balance > 1, "not enough eth");
        require(recipient.balance > 0, "recipient should have eth");
        uint256 balance = recipient.balance;
        bytes memory data = fillData(recipient, 1, "");
        UserOperation memory op = fillUserOp(data);
        op.initCode = getInitCode(owner);
        op.verificationGasLimit = getCreationGasLimit();
        executeUserOp(op);
        assert(address(account).code.length > 0);
        assert(balance + 1 == recipient.balance);
    }

    function send1Wei() internal {
        require(address(account).balance > 1, "not enough eth");
        require(recipient.balance > 0, "recipient should have eth");
        uint256 balance = recipient.balance;
        bytes memory data = fillData(recipient, 1, "");
        UserOperation memory op = fillUserOp(data);
        executeUserOp(op);
        assert(balance + 1 == recipient.balance);
    }

    function sendToken() internal {
        require(chainlink.balanceOf(address(account)) > 1e17, "not enough token");
        require(chainlink.balanceOf(recipient) > 0, "recipient should have token");
        uint256 balance = chainlink.balanceOf(address(account));
        uint256 recipientBalance = chainlink.balanceOf(recipient);
        bytes memory data =
            fillData(address(chainlink), 0, abi.encodeWithSelector(ERC20.transfer.selector, address(recipient), 1));
        UserOperation memory op = fillUserOp(data);
        executeUserOp(op);
        assert(chainlink.balanceOf(address(account)) == balance - 1);
        assert(chainlink.balanceOf(recipient) == recipientBalance + 1);
    }

    function mintNFT() internal returns (uint256 nftId) {
        require(ERC721(mockNFT).balanceOf(address(account)) == 0, "should not have any nft for mint target");
        uint256 balance = ERC721(mockNFT).balanceOf(address(account));
        bytes memory data =
            fillData(address(mockNFT), 0, abi.encodeWithSelector(SafeMintNFT.safeMint.selector, address(account)));
        nftId = SafeMintNFT(mockNFT).totalSupply();
        UserOperation memory op = fillUserOp(data);
        executeUserOp(op);
        assert(ERC721(mockNFT).balanceOf(address(account)) == balance + 1);
    }

    function mintNFTWithEOA() internal {
        uint256 balance = ERC721(mockNFT).balanceOf(recipient);
        SafeMintNFT(mockNFT).safeMint(recipient);
        assert(ERC721(mockNFT).balanceOf(recipient) == balance + 1);
    }

    function transferNFT(uint256 _tokenId) internal {
        require(ERC721(mockNFT).ownerOf(_tokenId) == address(account), "should have nft to transfer");
        require(ERC721(mockNFT).balanceOf(address(recipient)) != 0, "recipient should have nft");
        bytes memory data = fillData(
            address(mockNFT),
            0,
            abi.encodeWithSelector(ERC721.transferFrom.selector, address(account), address(recipient), _tokenId)
        );
        UserOperation memory op = fillUserOp(data);
        executeUserOp(op);
        assert(ERC721(mockNFT).ownerOf(_tokenId) == recipient);
    }

    function fillUserOp(bytes memory _data) internal view returns (UserOperation memory op) {
        op.sender = address(account);
        op.nonce = entryPoint.getNonce(address(account), 0);
        op.callData = _data;
        op.callGasLimit = 100000;
        op.verificationGasLimit = getCreationGasLimit();
        op.preVerificationGas = 10;
        op.maxFeePerGas = 500;
        op.maxPriorityFeePerGas = 1;
    }

    function signUserOpHash(uint256 _key, UserOperation memory _op) internal view returns (bytes memory signature) {
        bytes32 hash = entryPoint.getUserOpHash(_op);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, ECDSA.toEthSignedMessageHash(hash));
        signature = abi.encodePacked(r, s, v);
    }

    function executeUserOp(UserOperation memory _op) internal {
        _op.paymasterAndData = f(_op);
        _op.signature = getSignature(_op);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = _op;
        entryPoint.handleOps(ops, beneficiary);
    }

    function emptyPaymasterAndData(UserOperation memory _op) internal pure returns (bytes memory ret) {}

    function validatePaymasterAndData(UserOperation memory _op) internal view returns (bytes memory ret) {
        bytes32 hash = paymaster.getHash(_op, 0, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierKey, ECDSA.toEthSignedMessageHash(hash));
        ret = abi.encodePacked(address(paymaster), uint256(0), uint256(0), r, s, uint8(v));
    }

    function getSignature(UserOperation memory _op) internal view virtual returns (bytes memory);

    function fillData(address _to, uint256 _value, bytes memory _data) internal virtual returns (bytes memory);

    function getAccountAddr(address _owner) internal view virtual returns (IAccount _account);

    function getInitCode(address _owner) internal view virtual returns (bytes memory);

    function getCreationGasLimit() internal view virtual returns (uint256);
}
