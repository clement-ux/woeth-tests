// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Foundry
import {StdInvariant} from "forge-std/StdInvariant.sol";

// Contracts
import {TargetFunctions} from "./TargetFunctions.sol";

/// @title FuzzerFoundry contract
/// @notice Foundry interface for the fuzzer.
contract FuzzerFoundry is StdInvariant, TargetFunctions {
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
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = this.handler_deposit.selector;
        selectors[1] = this.handler_redeem.selector;

        // Target selectors
        targetSelector(FuzzSelector({addr: address(this), selectors: selectors}));
    }

    function invariant_A() public {}
}
