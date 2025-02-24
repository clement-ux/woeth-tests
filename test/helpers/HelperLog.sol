// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

abstract contract HelperLog {
    event log(string message);
    event log(uint256 number);
    event log(address addr);
    event log(bool boolean);
    event log(bytes32 data);
    event log(bytes data);

    event log_named_uint(string name, uint256 number);
    event log_named_address(string name, address addr);
    event log_named_bool(string name, bool boolean);
    event log_named_bytes32(string name, bytes32 data);
    event log_named_bytes(string name, bytes data);
}
