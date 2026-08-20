// SPDX-License-Identifier: MIT
pragma solidity =0.8.34;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId(uint256 invalidChainId);

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    address public constant DEFAULT_ANVIL_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    struct NetworkConfig {
        address initialOwner;
    }

    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == ETH_SEPOLIA_CHAIN_ID) {
            return getEthConfig();
        }

        if (chainId == ETH_MAINNET_CHAIN_ID) {
            return getEthConfig();
        }

        if (chainId == LOCAL_CHAIN_ID) {
            return getLocalConfig();
        }

        revert HelperConfig__InvalidChainId(chainId);
    }

    function getEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({initialOwner: vm.envAddress("INITIAL_OWNER")});
    }

    function getLocalConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({initialOwner: vm.envOr("INITIAL_OWNER", DEFAULT_ANVIL_ACCOUNT)});
    }
}
