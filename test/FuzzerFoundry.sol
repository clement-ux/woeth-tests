// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Foundry
import {Test} from "forge-std/Test.sol";

// Utils
import {TargetFunctions} from "./TargetFunctions.sol";

/// @title FuzzerFoundry contract
/// @notice Foundry interface for the fuzzer.
contract FuzzerFoundry is Test, TargetFunctions {
    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    /// @notice Setup the contract
    function setUp() public {
        setup();

        // Foundry doesn't use config files but does the setup programmatically here

        // target the fuzzer on this contract as it will contain the handler functions
        targetContract(address(this));

        // Add selectors
        bytes4[] memory selectors = new bytes4[](0);

        // Target selectors
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
    }

    function test_empty() public {}
}
