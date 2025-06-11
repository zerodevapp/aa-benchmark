pragma solidity ^0.8.12;

import {UserOperation06 as UserOperation} from "account-abstraction/legacy/v06/IAccount06.sol";
//0xe1Fb85Ec54767ED89252751F6667CF566b16f1F0

interface IVerifyingPaymaster {
    function owner() external view returns (address);
    function getHash(UserOperation calldata userOp, uint48 validUntil, uint48 validAfter)
        external
        view
        returns (bytes32);
}
