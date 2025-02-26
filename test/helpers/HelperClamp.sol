// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Librairies
import {LibString} from "@solady/utils/LibString.sol";

abstract contract HelperClamp {
    using LibString for uint256;

    event Clamped(string message);

    /// @notice Clamp a value to a range [min, max].
    /// @dev Higly inspired by PerimeterSec: https://github.com/perimetersec/fuzzlib/blob/main/src/helpers/HelperClamp.sol
    /// @param x The value to bound.
    /// @param min The minimum value.
    /// @param max The maximum value.
    /// @param enableLogs Whether to emit logs.
    /// @return ans The bounded value.
    function clamp(uint256 x, uint256 min, uint256 max, bool enableLogs) public returns (uint256) {
        uint256 ans = _bound_(x, min, max);
        if (ans != x && enableLogs) {
            string memory valueStr = x.toString();
            string memory ansStr = ans.toString();
            bytes memory message = abi.encodePacked("Clamped value ", valueStr, " to ", ansStr);
            emit Clamped(string(message));
        }
        return ans;
    }

    /// @notice Bound a value to a range [min, max].
    /// @dev Copied from ForgeStd: https://github.com/foundry-rs/forge-std/blob/bf909b22fa55e244796dfa920c9639fdffa1c545/src/StdUtils.sol#L31
    /// @param x The value to bound.
    /// @param min The minimum value.
    /// @param max The maximum value.
    /// @return result The bounded value.
    function _bound_(uint256 x, uint256 min, uint256 max) private pure returns (uint256 result) {
        require(min <= max, "StdUtils bound(uint256,uint256,uint256): Max is less than min.");
        // If x is between min and max, return x directly. This is to ensure that dictionary values
        // do not get shifted if the min is nonzero. More info: https://github.com/foundry-rs/forge-std/issues/188
        if (x >= min && x <= max) return x;

        uint256 size = max - min + 1;

        uint256 UINT256_MAX = type(uint256).max;
        // If the value is 0, 1, 2, 3, wrap that to min, min+1, min+2, min+3. Similarly for the UINT256_MAX side.
        // This helps ensure coverage of the min/max values.
        if (x <= 3 && size > x) return min + x;
        if (x >= UINT256_MAX - 3 && size > UINT256_MAX - x) return max - (UINT256_MAX - x);

        // Otherwise, wrap x into the range [min, max], i.e. the range is inclusive.
        if (x > max) {
            uint256 diff = x - max;
            uint256 rem = diff % size;
            if (rem == 0) return max;
            result = min + rem - 1;
        } else if (x < min) {
            uint256 diff = min - x;
            uint256 rem = diff % size;
            if (rem == 0) return min;
            result = max - rem + 1;
        }
    }
}
