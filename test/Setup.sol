// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

// Contracts
import {Helper} from "./helpers/Helper.sol";

// Contracts - Origin Dollar
import {OETH} from "@origin-dollar/token/OETH.sol";
import {WOETH} from "@origin-dollar/token/WOETH.sol";
import {OETHProxy} from "@origin-dollar/proxies/Proxies.sol";
import {WOETHProxy} from "@origin-dollar/proxies/Proxies.sol";

// Interfaces
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Setup contract
/// @notice Use to store all the global variable and deploy contracts.
abstract contract Setup is Helper {
    /// @notice hevm.label() only exist with Foundry. Need to be set to false we using Medusa.
    bool public constant USE_LABELS = true;
    bool public constant USE_LOGS = true;

    //////////////////////////////////////////////////////
    /// --- EOAS
    //////////////////////////////////////////////////////
    address[] public users;
    mapping(address user => string name) public userNames;

    //////////////////////////////////////////////////////
    /// --- CONTRACTS
    //////////////////////////////////////////////////////
    OETH public oeth;
    WOETH public woeth;
    address public vault;

    //////////////////////////////////////////////////////
    /// --- SETUP
    //////////////////////////////////////////////////////
    function setup() internal virtual {
        // 1. Setup a realistic test environnement.
        _setUpRealisticEnvironnement();

        // 2. Create user.
        _createUsers();

        // 3. Deploy mocks
        _deployMocks();

        // 4. Deploy contracts.
        _deployContracts();

        // 5. Ignite contracts
        _igniteContracts();

        // 6. Approvals
        _approvals();
    }

    //////////////////////////////////////////////////////
    /// --- INTERNAL LOGIC
    //////////////////////////////////////////////////////
    /// @notice Set realistic block.number and block.timestamp for testing.
    function _setUpRealisticEnvironnement() internal virtual {
        hevm.roll(21000000); // Block number
        hevm.warp(1700000000); // Timestamp
    }

    /// @notice Create users for testing.
    function _createUsers() internal {
        // Generate real user with name
        string[] memory names = generateUserNameList();
        alice = _generatelUser(names[0], users, userNames);
        bobby = _generatelUser(names[1], users, userNames);
        cathy = _generatelUser(names[2], users, userNames);
        david = _generatelUser(names[3], users, userNames);

        // Generate dead addresses
        dead = _generateAddress("Dead");

        // Generate fake vault
        vault = _generateAddress("Vault");
    }

    /// @notice Generate user with name and store them.
    function _generatelUser(string memory _name, address[] storage _users, mapping(address => string) storage m)
        internal
        returns (address generatedUser)
    {
        generatedUser = _generateAddress(_name);
        _users.push(generatedUser);
        m[generatedUser] = _name;
    }

    /// @notice Generate address with name.
    function _generateAddress(string memory _name) internal returns (address generatedAddress) {
        generatedAddress = _makeAddr(_name);
        if (USE_LABELS) hevm.label(generatedAddress, _name);
    }

    /// @notice Deploy mocks for testing.
    function _deployMocks() internal virtual {}

    /// @notice Deploy contracts for testing.
    function _deployContracts() internal virtual {
        // Deploy proxies
        OETHProxy oethProxy = new OETHProxy();
        WOETHProxy woethProxy = new WOETHProxy();

        // Deploy implementations
        oeth = new OETH();
        woeth = new WOETH(ERC20(address(oethProxy)));

        // Initialize proxies
        oethProxy.initialize(
            address(oeth),
            address(this),
            abi.encodeWithSignature("initialize(string,string,address,uint256)", "Origin Ether", "OETH", vault, 1e27)
        );
        woethProxy.initialize(address(woeth), address(this), "");

        // Update address
        oeth = OETH(address(oethProxy));
        woeth = WOETH(address(woethProxy));

        // Initilize2 WOETH
        woeth.initialize2();

        if (USE_LABELS) {
            hevm.label(address(oeth), "OETH");
            hevm.label(address(woeth), "WOETH");
        }
    }

    /// @notice Ignite contracts for testing.
    function _igniteContracts() internal virtual {
        hevm.prank(vault);
        oeth.mint(dead, 10 ** 12);
    }

    /// @notice Approve all users for testing.
    function _approvals() internal virtual {
        for (uint256 i; i < users.length; i++) {
            hevm.prank(users[i]);
            oeth.approve(address(woeth), type(uint256).max);
        }
    }
}
