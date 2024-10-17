// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import {Test} from "forge-std/src/Test.sol";
import {console2} from "forge-std/src/console2.sol";
import {MolochV3Splits} from "../../src/strategies/MolochV3Splits.sol";
import {SplitV2Lib} from "../../src/libraries/SplitV2.sol";

contract MockBaalSummoner {
    address public lastCreatedDAO;

    function summonBaalAndSafe(
        bytes calldata initializationParams,
        bytes[] calldata initializationActions,
        uint256 _saltNonce
    ) external returns (address) {
        lastCreatedDAO = address(uint160(uint256(keccak256(abi.encode(
            initializationParams,
            initializationActions,
            _saltNonce
        )))));
        return lastCreatedDAO;
    }
}

contract MockSplitFactory {
    address public lastCreatedSplit;

    function createSplitDeterministic(
        SplitV2Lib.Split calldata _splitParams,
        address _owner,
        address _creator,
        bytes32 _salt
    ) external returns (address split) {
        lastCreatedSplit = address(uint160(uint256(keccak256(abi.encodePacked(
            _splitParams.recipients,
            _splitParams.allocations,
            _owner,
            _creator,
            _salt
        )))));
        return lastCreatedSplit;
    }
}

contract MolochV3SplitsTest is Test {
    MolochV3Splits internal strategy;
    MockBaalSummoner internal mockSummoner;
    MockSplitFactory internal mockSplitFactory;

    function setUp() public {
        mockSummoner = new MockBaalSummoner();
        mockSplitFactory = new MockSplitFactory();
        strategy = new MolochV3Splits(address(mockSummoner), address(mockSplitFactory));
    }

    function test_Constructor() public view {
        assertEq(address(strategy.molochSummoner()), address(mockSummoner));
        assertEq(address(strategy.splitFactory()), address(mockSplitFactory));
    }

    function test_CreateAttractorSpace() public {
        // Prepare MolochV3InitParams
        bytes memory molochInitParams = abi.encode(
            bytes("moloch init"),
            new bytes[](0),
            uint256(1)
        );

        // Prepare SplitV2Lib.Split
        address[] memory recipients = new address[](2);
        recipients[0] = address(0x1);
        recipients[1] = address(0x2);
        uint256[] memory percentAllocations = new uint256[](2);
        percentAllocations[0] = 5000;
        percentAllocations[1] = 5000;

        uint256 totalAllocation = 10000;

        SplitV2Lib.Split memory splitParams = SplitV2Lib.Split({
            recipients: recipients,
            allocations: percentAllocations,
            totalAllocation: totalAllocation,
            distributionIncentive: uint16(0)
        });

        // Encode initialization params
        bytes memory initParams = abi.encode(
            MolochV3Splits.MolochV3InitParams({
                initializationParams: molochInitParams,
                initializationActions: new bytes[](0),
                _saltNonce: 1
            }),
            splitParams
        );

        (address dao, address splits) = strategy.createAttractorSpace(initParams);

        assertEq(dao, mockSummoner.lastCreatedDAO());
        assertEq(splits, mockSplitFactory.lastCreatedSplit());
    }

}
