// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IAttractorSpaceStrategyRegistry} from "./interfaces/IAttractorSpaceStrategyRegistry.sol";

contract AttractorSpaceStrategyRegistry is IAttractorSpaceStrategyRegistry, Ownable {

    // state
    mapping(bytes32 => Strategy) public strategies;

    // events
    event StrategyAdded(bytes32 indexed strategyId, address indexed strategy);
    event StrategyDisabled(bytes32 indexed strategyId);

    // errors

    // constructor
    constructor(address initialOwner) Ownable(initialOwner) {
    }

    // function
    // receive function (if exists)

    // fallback function (if exists)

    // external

    // public

    function getStrategy(bytes32 strategyId) public view returns (Strategy memory) {
        return strategies[strategyId];
    }

    function addStrategy(address strategy) public onlyOwner returns (bytes32 strategyId) {
        strategyId = keccak256(abi.encode(strategy));
        strategies[strategyId] = Strategy({
            strategyAddress: strategy,
            active: true
        });
        emit StrategyAdded(strategyId, strategy);
    }

    function isActiveStrategy(bytes32 strategyId) public view returns (bool isActive) {
        return strategies[strategyId].active;
    }

    function disableStrategy(bytes32 strategyId) public onlyOwner {
        strategies[strategyId].active = false;
        emit StrategyDisabled(strategyId);
    }

    // internal

    // private
}
