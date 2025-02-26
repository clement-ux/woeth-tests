// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Contracts
import {Setup} from "./Setup.sol";

import {Log} from "./helpers/HelperLog.sol";

/// @title Properties contract
/// @notice Use to store all the properties (invariants) of the system.
abstract contract Properties is Setup {
    enum LastAction {
        NONE,
        DEPOSIT,
        MINT,
        REDEEM,
        WITHDRAW,
        CHANGE_SUPPLY,
        DONATE,
        MINT_OR_BURN_EXTRA_OETH
    }

    LastAction public last_action = LastAction.NONE;

    // --- Data ---
    mapping(address => uint256) public __deposited;
    mapping(address => uint256) public __minted;
    mapping(address => uint256) public __redeemed;
    mapping(address => uint256) public __withdrawn;
    uint256 public __sum_donation;
    uint256 public __totalAssetBefore;
    uint256 public __totalAssetAfter;
    uint256 public __sum_deposited;
    uint256 public __sum_minted;
    uint256 public __sum_redeemed;
    uint256 public __sum_withdrawn;
    uint256 public __sum_donated_credits;
    uint256 public __user_woeth_balance_before;
    uint256 public __user_oeth_balance_before;
    uint256 public __user_woeth_balance_after;
    uint256 public __user_oeth_balance_after;
    bool public __user_deposit_mint_zero;
    bool public __user_withdraw_redeem_zero;
    bool public __convertToAssets_success = true;
    bool public __convertToShares_success = true;
    bool public __totalAssets_success = true;
    bool public __maxDeposit_success = true;
    bool public __maxMint_success = true;
    bool public __maxRedeem_success = true;
    bool public __maxWithdraw_success = true;

    // --- Tolerances ---
    uint256 public t_A = 0;
    uint256 public t_B = 1e2;
    uint256 public t_C = 1e2;
    uint256 public t_D = 1e11;
    uint256 public t_4626_A = 0;

    //////////////////////////////////////////////////////
    /// --- DEFINITIONS
    //////////////////////////////////////////////////////
    /// - If totalAsset is different than before the call, then last action shouldn't be [DONATE, MINT_OR_BURN_EXTRA_OETH]
    /// - At then end with empty the vault, all user should have more oeth than at the beginning
    /// - The sum of all deposited and minted should be greater than or equal to the sum of all redeemed and withdrawn
    /// - The amount of credit in woeth should be equal to oethCreditsHighres - donation
    /// --- ERC4626
    /// - The views functions should never revert
    /// - If a user deposit more than 1wei of OETH, he should receive at least 1wei of WOETH.
    ///     If he doesn't receive any WOETH, then he should have deposited exclusively 1 wei of OETH.
    ///     If he deposit 0 OETH he should have the same amount of WOETH before and after the deposit.
    /// - If a user withdraw or redeem 1 wei or more of WOETH, he should have less WOETH after the operation and more OETH.
    ///     If he withdraw 0 WOETH, he should have the same amount of WOETH before and after the withdraw.

    function property_A() public view returns (bool) {
        if (__totalAssetBefore != __totalAssetAfter) {
            return last_action != LastAction.DONATE && last_action != LastAction.MINT_OR_BURN_EXTRA_OETH;
        }
        return true;
    }

    /// @dev Tested in the "afterInvariant" function
    function __property_B() internal returns (bool) {
        for (uint256 i = 0; i < users.length; i++) {
            uint256 a = __deposited[users[i]] + __minted[users[i]];
            uint256 b = __redeemed[users[i]] + __withdrawn[users[i]];
            if (a > b + t_B) {
                emit Log.log_named_uint("deposited + minted", a);
                emit Log.log_named_uint("redeemed + withdrawn", b);
                emit Log.log_named_uint("delta", delta(a, b));
                return false;
            }
        }
        return true;
    }

    /// @dev Tested in the "afterInvariant" function
    function __property_C() internal returns (bool) {
        uint256 a = __sum_deposited + __sum_minted;
        uint256 b = __sum_redeemed + __sum_withdrawn;
        if (a > b + t_C) {
            emit Log.log_named_uint("sum_deposited + sum_minted", a);
            emit Log.log_named_uint("sum_redeemed + sum_withdrawn", b);
            emit Log.log_named_uint("delta", delta(a, b));
            return false;
        }
        return true;
    }

    function property_D() public returns (bool) {
        (uint256 totalCreditWoeth,,) = oeth.creditsBalanceOfHighres(address(woeth));
        uint256 localCreditWoeth = (woeth.oethCreditsHighres());
        uint256 targetCreditWoeth = totalCreditWoeth - __sum_donated_credits;
        if (!approxEqAbs(localCreditWoeth, targetCreditWoeth, t_D)) {
            emit Log.log_named_uint("localCreditWoeth   ", localCreditWoeth);
            emit Log.log_named_uint("totalCreditWoeth   ", totalCreditWoeth);
            emit Log.log_named_uint("sum_donated_credits", __sum_donated_credits);
            emit Log.log_named_uint("diff: ", delta(localCreditWoeth, targetCreditWoeth));
            return false;
        }
        return true;
    }

    function property_4626_views() public view returns (bool) {
        return __convertToAssets_success && __convertToShares_success && __totalAssets_success && __maxDeposit_success
            && __maxMint_success && __maxRedeem_success && __maxWithdraw_success;
    }

    function property_4626_deposit_mint() public returns (bool) {
        if (last_action == LastAction.DEPOSIT || last_action == LastAction.MINT) {
            // If the user mint or deposit 0, then the woeth balance should be the same.
            if (__user_deposit_mint_zero) {
                if (__user_woeth_balance_after != __user_woeth_balance_before) {
                    _logOETHAndWOETHBalances("A");
                    return false;
                }
                return true;
            }
            // If the user woeth balance is the same after mint or deposit, this means that user deposited only 1wei
            else if (__user_woeth_balance_after == __user_woeth_balance_before) {
                uint256 totalAssets = woeth.totalAssets();
                uint256 totalSupply = woeth.totalSupply();
                if (__user_oeth_balance_before > (totalAssets / totalSupply)) {
                    _logOETHAndWOETHBalances("B");
                    return false;
                }
            }
            // Else the user should have deposited more than 1wei of OETH and received 1wei or more of WOETH
            else {
                if (
                    __user_oeth_balance_before <= __user_oeth_balance_after
                        || (__user_woeth_balance_after) <= __user_woeth_balance_before
                ) {
                    _logOETHAndWOETHBalances("C");
                    return false;
                }
            }
        }
        return true;
    }

    function property_4626_withdraw_redeem() public returns (bool) {
        if (last_action == LastAction.WITHDRAW || last_action == LastAction.REDEEM) {
            // If a user redeem or withdraw 0, then the oeth and woeth balance should be the same.
            if (__user_withdraw_redeem_zero) {
                if (
                    __user_oeth_balance_after != __user_oeth_balance_before
                        || __user_woeth_balance_after != __user_woeth_balance_before
                ) {
                    _logOETHAndWOETHBalances("A");
                    return false;
                }
                return true;
            }
            // If a user have same woeth balance after redeem or withdraw, then he should have the same oeth balance
            else if (__user_woeth_balance_after == __user_woeth_balance_before) {
                if (__user_oeth_balance_after != __user_oeth_balance_before) {
                    _logOETHAndWOETHBalances("B");
                    return false;
                }
            }
            // If a user have less woeth balance after redeem or withdraw, then he should have more oeth balance
            else if (__user_woeth_balance_before > __user_woeth_balance_after) {
                if (__user_oeth_balance_before >= __user_oeth_balance_after) {
                    _logOETHAndWOETHBalances("C");
                    return false;
                }
            }
        }
        return true;
    }

    function approxEqAbs(uint256 a, uint256 b, uint256 tolerance) internal pure returns (bool) {
        if (a > b) {
            return (a - b) <= tolerance;
        } else {
            return (b - a) <= tolerance;
        }
    }

    function _logOETHAndWOETHBalances() internal {
        emit Log.log_named_uint("user_oeth_balance_before", __user_oeth_balance_before);
        emit Log.log_named_uint("user_oeth_balance_after", __user_oeth_balance_after);
        emit Log.log_named_uint("user_woeth_balance_before", __user_woeth_balance_before);
        emit Log.log_named_uint("user_woeth_balance_after", __user_woeth_balance_after);
    }

    function _logOETHAndWOETHBalances(string memory message) internal {
        emit Log.log(message);
        _logOETHAndWOETHBalances();
    }
}
