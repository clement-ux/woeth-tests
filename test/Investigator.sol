// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Setup} from "./Setup.sol";
import {Properties} from "./Properties.sol";

contract Investigator is Properties {
    function setUp() public {
        setup();
    }

    function test_unit() public {
        // 1. Increase totalSupply by 0.01%
        uint256 oethTotalSupply = oeth.totalSupply();
        // Calculate new total supply
        uint256 newTotalSupply = oethTotalSupply + (oethTotalSupply * 1) / BASE_PCT;
        hevm.prank(vault);
        oeth.changeSupply(newTotalSupply);

        // 2. Mint
        uint256 amount = 15000;
        // Mint OETH to user
        hevm.prank(vault);
        oeth.mint(alice, amount);
        uint256 sharesToMint = woeth.convertToShares(amount);
        // User deposit
        hevm.prank(alice);
        woeth.mint(sharesToMint, alice);

        require(property_D(), "Invariant D failed");
    }
}
