// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

interface IAttractorSpaceStrategy {
    function createAttractorSpace(bytes calldata initializationParams) external returns (address governance, address distribution);
}
