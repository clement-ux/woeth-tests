// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Contracts
import {TargetFunctions} from "./TargetFunctions.sol";

// run from base project directory with:
// medusa fuzz
contract FuzzerMedusa is TargetFunctions {
    constructor() {
        setup();
    }
}
