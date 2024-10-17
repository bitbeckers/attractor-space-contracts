// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import {SplitV2Lib} from "../libraries/SplitV2.sol";

interface IBaalSummoner {
    function summonBaalAndSafe(
        bytes calldata initializationParams,
        bytes[] calldata initializationActions,
        uint256 _saltNonce
    ) external returns (address);
}

interface ISplitFactory {
    function createSplitDeterministic(
        SplitV2Lib.Split calldata _splitParams,
        address _owner,
        address _creator,
        bytes32 _salt
    )
    external
    returns (address split);
}

contract MolochV3Splits {
    struct MolochV3InitParams {
        bytes initializationParams;
        bytes[] initializationActions;
        uint256 _saltNonce;
    }

    struct SplitsInitParams {
        address[] recipients;
        uint256[] allocations;
        uint256 totalAllocation;
        uint16 distributionIncentive;
    }

    IBaalSummoner public molochSummoner;
    ISplitFactory public splitFactory;

    constructor(address _molochSummoner, address _splitFactory) {
        molochSummoner = IBaalSummoner(_molochSummoner);
        splitFactory = ISplitFactory(_splitFactory);
    }

    function createAttractorSpace(bytes calldata initializationParams) public returns (address dao, address splits) {
        (MolochV3InitParams memory molochInitParams, SplitV2Lib.Split memory splitInitParams) = abi.decode(initializationParams, (MolochV3InitParams, SplitV2Lib.Split));

        dao = _createMolochV3(molochInitParams);
        splits = _createSplit(dao, splitInitParams);
    }

    function _createSplit(
        address dao,
        SplitV2Lib.Split memory splitParams
    ) internal returns (address split) {

        split = splitFactory.createSplitDeterministic(
            splitParams,
            dao,
            address(this),
            keccak256(abi.encode(msg.sender, splitParams))
        );
    }

    function _createMolochV3(
        MolochV3InitParams memory initParams
    ) internal returns (address dao) {
        (bytes memory initializationParams, bytes[] memory initializationActions, uint256 _saltNonce) = abi.decode(initParams.initializationParams, (bytes, bytes[], uint256));

        dao = address(IBaalSummoner(molochSummoner).summonBaalAndSafe(
            initializationParams,
            initializationActions,
            _saltNonce
        ));
    }
}
