// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IAttractorSpaceStrategyRegistry.sol";
import "./interfaces/IAttractorSpaceStrategy.sol";

/// @title Deploy your attractor space in an instant
/// @author bitbeckers
/// @notice This contract coordinates the deployment and initialization of attractor spaces
contract AttractorSpaceFactory is Ownable {

    // type
    struct AttractorSpaceInstance {
        address creator;
        address governance;
        address distribution;
    }

    // state
    uint256 public nextAttractorId;
    address public sustainabilityFund;
    address public strategyRegistry;
    mapping(uint256 => AttractorSpaceInstance) public attractorSpaces;

    // events
    event AttractorSpaceCreated(uint256 id, address indexed creator, address indexed owner, address spaceAddress);

    // errors
    error AttractorSpaceAlreadyExists(uint256 attractorId);
    error AttractorSpaceStrategyNotActive();

    // constructor
    constructor(address _initialOwner, address _initialStrategyRegistry, address _sustainabilityFund) Ownable(_initialOwner) {
        strategyRegistry = _initialStrategyRegistry;
        sustainabilityFund = _sustainabilityFund;
    }

    // function
    // receive function (if exists)

    // fallback function (if exists)

    // external

    // public
    function createAttractorSpace(address admin, bytes32 strategyId) public returns (AttractorSpaceInstance memory attractorSpace) {
        if (!_isActiveStrategy(strategyId)) {
            revert AttractorSpaceStrategyNotActive();
        }

        address strategy = IAttractorSpaceStrategyRegistry(strategyRegistry).getStrategy(strategyId).strategyAddress;

        (address governanceStrategy, address distributionStrategy) = IAttractorSpaceStrategy(strategy).createAttractorSpace(abi.encode(admin));

        uint256 attractorId = nextAttractorId;
        nextAttractorId++;

        attractorSpace = AttractorSpaceInstance({
            creator: msg.sender,
            governance: governanceStrategy,
            distribution: distributionStrategy
        });

        attractorSpaces[attractorId] = attractorSpace;

        emit AttractorSpaceCreated(attractorId, msg.sender, governanceStrategy, distributionStrategy);
    }

    // internal
    function _isActiveStrategy(bytes32 strategyId) internal view returns (bool) {
        return IAttractorSpaceStrategyRegistry(strategyRegistry).isActiveStrategy(strategyId);
    }

    // private

}
