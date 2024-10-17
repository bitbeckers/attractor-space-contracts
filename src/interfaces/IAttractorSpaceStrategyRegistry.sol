// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

interface IAttractorSpaceStrategyRegistry {
    struct Strategy {
        address strategyAddress;
        bool active;
    }

    function getStrategy(bytes32 strategyId) external view returns (Strategy memory strategy);

    function addStrategy(address strategy) external returns (bytes32 strategyId);

    function isActiveStrategy(bytes32 strategyId) external view returns (bool isActive);

    function disableStrategy(bytes32 strategyId) external;
}
