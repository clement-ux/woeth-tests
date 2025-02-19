// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Interfaces
import {IHevm} from "../interfaces/IHevm.sol";

// Contracts
import {HelperMath} from "./HelperMath.sol";
import {HelperClamp} from "./HelperClamp.sol";
import {HelperAddress} from "./HelperAddress.sol";

abstract contract Helper is HelperMath, HelperClamp, HelperAddress {
    IHevm internal constant hevm = IHevm(address(uint160(uint256(keccak256("hevm cheat code")))));
}
