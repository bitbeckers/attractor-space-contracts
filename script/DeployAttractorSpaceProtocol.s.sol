// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import {AttractorSpaceFactory} from "../src/AttractorSpaceFactory.sol";
import {AttractorSpaceStrategyRegistry} from "../src/AttractorSpaceStrategyRegistry.sol";

import {BaseScript} from "./Base.s.sol";
import "../src/strategies/MolochV3Splits.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployAttractorSpaceProtocol is BaseScript {
    function run() public broadcast returns (AttractorSpaceStrategyRegistry registry, AttractorSpaceFactory factory, MolochV3Splits molochV3Splits) {
        address ADMIN = 0xdf2C3dacE6F31e650FD03B8Ff72beE82Cb1C199A;

        registry = new AttractorSpaceStrategyRegistry(ADMIN);
        factory = new AttractorSpaceFactory(ADMIN, address(registry), ADMIN);

        // https://github.com/HausDAO/Baal/blob/feat/baalZodiac/deployments/sepolia/BaalAndVaultSummoner_Proxy.json
        address molochSummoner = 0x763f5c2E59f997A6cC48Bf1228aBf61325244702;

        // https://github.com/0xSplits/splits-contracts-monorepo/blob/main/packages/splits-v2/deployments/11155111.json
        address splitsPullFactory = 0x80f1B766817D04870f115fEBbcCADF8DBF75E017;
        molochV3Splits = new MolochV3Splits(molochSummoner, splitsPullFactory);
        registry.addStrategy(address(molochV3Splits));
    }
}
