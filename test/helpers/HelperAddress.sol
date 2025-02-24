// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

abstract contract HelperAddress {
    // --- EOAs ---
    address public alice;
    address public bobby;
    address public cathy;
    address public david;
    address public emily;
    address public frank;
    address public grace;
    address public henry;
    address public irene;
    address public jacky;
    address public kenny;
    address public laura;
    address public mason;
    address public nancy;
    address public oscar;
    address public penny;
    address public quinn;
    address public ricky;
    address public sally;
    address public tommy;

    address public dead;
    address public dead2;
    address public dead3;

    function _makeAddr(string memory _name) internal pure returns (address) {
        address _address = address(uint160(uint256(keccak256(abi.encodePacked(_name)))));
        require(_address != address(0), "Setup: invalid address");
        return _address;
    }

    function generateUserNameList() internal virtual returns (string[] memory names) {
        string[20] memory userNames = [
            "Alice",
            "Bobby",
            "Cathy",
            "David",
            "Emily",
            "Frank",
            "Grace",
            "Henry",
            "Irene",
            "Jacky",
            "Kenny",
            "Laura",
            "Mason",
            "Nancy",
            "Oscar",
            "Penny",
            "Quinn",
            "Ricky",
            "Sally",
            "Tommy"
        ];

        names = new string[](20);
        for (uint256 i = 0; i < 20; i++) {
            names[i] = userNames[i];
        }
        return names;
    }
}
