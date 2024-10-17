// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";
import {AttractorSpaceStrategyRegistry} from "../src/AttractorSpaceStrategyRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AttractorSpaceStrategyRegistryTest is Test {
    AttractorSpaceStrategyRegistry internal registry;
    address internal owner = address(0x1);
    address internal nonOwner = address(0x2);
    address internal mockStrategy = address(0x3);

    event StrategyAdded(bytes32 indexed strategyId, address indexed strategy);
    event StrategyDisabled(bytes32 indexed strategyId);

    function setUp() public {
        registry = new AttractorSpaceStrategyRegistry(owner);
    }

    function test_InitialState() public {
        assertEq(registry.owner(), owner);
    }

    function test_AddStrategy() public {
        vm.prank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);

        AttractorSpaceStrategyRegistry.Strategy memory strategy = registry.getStrategy(strategyId);
        assertEq(strategy.strategyAddress, mockStrategy);
        assertTrue(strategy.active);
    }

    function test_AddStrategy_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        bytes32 expectedStrategyId = keccak256(abi.encode(mockStrategy));
        emit StrategyAdded(expectedStrategyId, mockStrategy);
        registry.addStrategy(mockStrategy);
    }

    function test_AddStrategy_OnlyOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        registry.addStrategy(mockStrategy);
    }

    function test_IsActiveStrategy() public {
        vm.startPrank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);
        assertTrue(registry.isActiveStrategy(strategyId));
        vm.stopPrank();
    }

    function test_DisableStrategy() public {
        vm.startPrank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);
        registry.disableStrategy(strategyId);
        assertFalse(registry.isActiveStrategy(strategyId));
        vm.stopPrank();
    }

    function test_DisableStrategy_EmitsEvent() public {
        vm.startPrank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);
        vm.expectEmit(true, false, false, true);
        emit StrategyDisabled(strategyId);
        registry.disableStrategy(strategyId);
        vm.stopPrank();
    }

    function test_DisableStrategy_OnlyOwner() public {
        vm.prank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        registry.disableStrategy(strategyId);
    }

    function test_GetStrategy() public {
        vm.prank(owner);
        bytes32 strategyId = registry.addStrategy(mockStrategy);

        AttractorSpaceStrategyRegistry.Strategy memory strategy = registry.getStrategy(strategyId);
        assertEq(strategy.strategyAddress, mockStrategy);
        assertTrue(strategy.active);
    }

    function test_GetStrategy_Nonexistent() public {
        bytes32 nonexistentId = keccak256("nonexistent");
        AttractorSpaceStrategyRegistry.Strategy memory strategy = registry.getStrategy(nonexistentId);
        assertEq(strategy.strategyAddress, address(0));
        assertFalse(strategy.active);
    }

    function testFuzz_AddMultipleStrategies(address[5] memory strategies) public {
        vm.startPrank(owner);
        for (uint i = 0; i < strategies.length; i++) {
            if (strategies[i] != address(0)) {
                bytes32 strategyId = registry.addStrategy(strategies[i]);
                assertTrue(registry.isActiveStrategy(strategyId));
            }
        }
        vm.stopPrank();
    }
}
