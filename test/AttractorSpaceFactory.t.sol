// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";

import {AttractorSpaceFactory} from "../src/AttractorSpaceFactory.sol";
import {IAttractorSpaceStrategyRegistry} from "../src/interfaces/IAttractorSpaceStrategyRegistry.sol";
import {IAttractorSpaceStrategy} from "../src/interfaces/IAttractorSpaceStrategy.sol";

contract MockStrategyRegistry is IAttractorSpaceStrategyRegistry {
    mapping(bytes32 => IAttractorSpaceStrategyRegistry.Strategy) public _strategies;
    mapping(bytes32 => bool) public _activeStrategies;

    function setStrategy(bytes32 id, address strategyAddress, bool active) public {
        _strategies[id] = IAttractorSpaceStrategyRegistry.Strategy(strategyAddress, active);
        _activeStrategies[id] = active;
    }

    function getStrategy(bytes32 id) public view returns (IAttractorSpaceStrategyRegistry.Strategy memory) {
        return _strategies[id];
    }

    function addStrategy(address strategy) public returns (bytes32 strategyId) {
        strategyId = keccak256(abi.encode(strategy));
        _strategies[strategyId] = IAttractorSpaceStrategyRegistry.Strategy(strategy, true);
        _activeStrategies[strategyId] = true;
        return strategyId;
    }

    function disableStrategy(bytes32 strategyId) public {
        _activeStrategies[strategyId] = false;
    }

    function isActiveStrategy(bytes32 strategyId) public view returns (bool) {
        return _activeStrategies[strategyId];
    }

    function strategies(bytes32 id) external view returns (IAttractorSpaceStrategyRegistry.Strategy memory) {
        return _strategies[id];
    }
}

contract MockAttractorSpaceStrategy is IAttractorSpaceStrategy {
    address public governanceStrategy;
    address public distributionStrategy;

    function setStrategies(address _governanceStrategy, address _distributionStrategy) external {
        governanceStrategy = _governanceStrategy;
        distributionStrategy = _distributionStrategy;
    }

    function createAttractorSpace(bytes calldata data) public returns (address, address) {
        return (governanceStrategy, distributionStrategy);
    }
}

contract AttractorSpaceFactoryTest is Test {
    AttractorSpaceFactory internal factory;
    MockStrategyRegistry internal strategyRegistry;
    MockAttractorSpaceStrategy internal mockStrategy;

    address internal owner = address(0x1);
    address internal sustainabilityFund = address(0x2);
    address internal admin = address(0x3);
    bytes32 internal strategyId = keccak256("TEST_STRATEGY");

    function setUp() public {
        strategyRegistry = new MockStrategyRegistry();
        mockStrategy = new MockAttractorSpaceStrategy();

        factory = new AttractorSpaceFactory(owner, address(strategyRegistry), sustainabilityFund);

        // Set up mock strategy
        mockStrategy.setStrategies(address(0x4), address(0x5));
        strategyRegistry.setStrategy(strategyId, address(mockStrategy), true);
    }

    function test_CreateAttractorSpace() public {
        vm.prank(admin);
        AttractorSpaceFactory.AttractorSpaceInstance memory instance = factory.createAttractorSpace(admin, strategyId);

        assertEq(instance.creator, admin);
        assertEq(instance.governance, address(0x4));
        assertEq(instance.distribution, address(0x5));
        assertEq(factory.nextAttractorId(), 1);
    }

    function test_CreateAttractorSpace_InactiveStrategy() public {
        bytes32 inactiveStrategyId = keccak256("INACTIVE_STRATEGY");
        strategyRegistry.setStrategy(inactiveStrategyId, address(0x6), false);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(AttractorSpaceFactory.AttractorSpaceStrategyNotActive.selector));
        factory.createAttractorSpace(admin, inactiveStrategyId);
    }

    function test_CreateMultipleAttractorSpaces() public {
        vm.startPrank(admin);

        factory.createAttractorSpace(admin, strategyId);
        factory.createAttractorSpace(admin, strategyId);
        factory.createAttractorSpace(admin, strategyId);

        vm.stopPrank();

        assertEq(factory.nextAttractorId(), 3);
    }

    function testFuzz_CreateAttractorSpace(address randomAdmin) public {
        vm.assume(randomAdmin != address(0));

        vm.prank(randomAdmin);
        AttractorSpaceFactory.AttractorSpaceInstance memory instance = factory.createAttractorSpace(randomAdmin, strategyId);

        assertEq(instance.creator, randomAdmin);
        assertEq(instance.governance, address(0x4));
        assertEq(instance.distribution, address(0x5));
    }
}
