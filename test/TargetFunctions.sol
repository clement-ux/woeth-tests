// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Contracts
import {Properties} from "./Properties.sol";

/// @title TargetFunctions contract
/// @notice Use to handle all calls to the tested contract.
abstract contract TargetFunctions is Properties {
    //////////////////////////////////////////////////////
    /// --- HANDLERS
    //////////////////////////////////////////////////////
    /// @notice Handle deposit in WOETH.
    /// @param _userId User id to deposit WOETH.
    /// @param _amountToMint Maximum amount of OETH that can be minted in a single transaction will be limited
    ///        to type(uint88).max. This is a bit less than 310M. In comparison with biggest holders:
    ///        - OUSD: approx 1.2M
    ///        - OETH: approx 18k
    ///        - OS  : negligible
    /// _amountToMint = type(uint88).max;
    function handler_deposit(uint8 _userId, uint88 _amountToMint) public {
        // Find a random user amongst the users.
        address user = users[_userId % users.length];

        // Bound amout to mint.
        _amountToMint = uint88(clamp(uint256(_amountToMint), 0, _mintableAmount(), USE_LOGS));
        if (_amountToMint == 0) return; // Todo: Log return reason

        // Mint OETH to the user.
        _mintOETHTo(user, _amountToMint);
        uint256 amountToMint = oeth.balanceOf(user);

        // Deposit OETH.
        hevm.prank(user);
        woeth.deposit(amountToMint, user);
    }

    /// @notice Handle redeem in WOETH.
    /// @param _userId User id to redeem WOETH.
    /// @param _amountToRedeem Amount of WOETH to redeem.
    ///        Maximum will be limited to type(uint96).max. This is a bit less than 80B.
    ///        As the max OETH total supply is set to type(uint96).max, even with 100% of the OETH supply is
    ///        deposited in the vault, the max amount of WOETH that can be redeemed is type(uint96).max as the
    ///        price cannot be go below 1.
    /// _amountToMint = type(uint96).max;
    function handler_redeem(uint8 _userId, uint96 _amountToRedeem) public {
        // Find an user with WOETH shares.
        address user;
        uint256 balance;
        uint256 len = users.length;
        for (uint256 i = _userId; i < len + _userId; i++) {
            uint256 woethBalance = woeth.balanceOf(users[i % len]);
            if (woethBalance > 0) {
                user = users[i % len];
                balance = woethBalance;
                break;
            }
        }
        if (user == address(0)) return; // Todo: Log return reason

        // Bound amout to redeem.
        _amountToRedeem = uint96(clamp(uint256(_amountToRedeem), 0, balance, USE_LOGS));

        // Redeem WOETH.
        hevm.prank(user);
        woeth.redeem(_amountToRedeem, user, user);

        // Burn OETH from user.
        _burnOETHFrom(user, oeth.balanceOf(user));
    }

    function handler_changeSupply(uint16 _pctIncrease) public {
        uint256 oethTotalSupply = oeth.totalSupply();

        // Bound pct increase.
        _pctIncrease = uint16(clamp(uint256(_pctIncrease), 1, MAX_PCT_CHANGE_TOTAL_SUPPLY, USE_LOGS));

        // Calculate new total supply
        uint256 newTotalSupply = oethTotalSupply + (oethTotalSupply * _pctIncrease) / BASE_PCT;

        hevm.prank(vault);
        oeth.changeSupply(newTotalSupply);
    }

    //////////////////////////////////////////////////////
    /// --- INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////
    /// @notice Helper function to mint OETH to a user.
    /// @param _user User to mint OETH to.
    /// @param _amountToMint Amount of OETH to mint.
    function _mintOETHTo(address _user, uint88 _amountToMint) internal {
        hevm.prank(vault);
        oeth.mint(_user, _amountToMint);
        // This should never happen, but just in case.
        require(oeth.totalSupply() <= MAX_OETH_TOTAL_SUPPLY, "OETH: total supply exceeds max");
    }

    /// @notice Helper function to burn OETH from a user.
    /// @param _user User to burn OETH from.
    /// @param _amountToBurn Amount of OETH to burn.
    function _burnOETHFrom(address _user, uint256 _amountToBurn) internal {
        hevm.prank(vault);
        oeth.burn(_user, _amountToBurn);
    }

    /// @notice Helper that return max amount mintable, based on the total supply of OETH.
    /// @return Amount of OETH that can be minted.
    function _mintableAmount() internal view returns (uint256) {
        uint256 oethTotalSupply = oeth.totalSupply();
        return (oethTotalSupply >= MAX_OETH_TOTAL_SUPPLY) ? 0 : (MAX_OETH_TOTAL_SUPPLY - oethTotalSupply);
    }
}
