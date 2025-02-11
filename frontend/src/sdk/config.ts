import { Aptos, Network, AptosConfig } from "@aptos-labs/ts-sdk";

export const NETWORKS = {
  mainnet: {
    network: Network.MAINNET,
    nodeUrl: "https://fullnode.mainnet.aptoslabs.com/v1",
    name: "Mainnet",
    chainId: "1",
  },
  testnet: {
    network: Network.TESTNET,
    nodeUrl: "https://fullnode.testnet.aptoslabs.com/v1",
    name: "Testnet",
    chainId: "2",
  },
  devnet: {
    network: Network.DEVNET,
    nodeUrl: "https://fullnode.devnet.aptoslabs.com/v1",
    name: "Devnet",
    chainId: "3",
  },
} as const;

export const ACTIVE_NETWORK = NETWORKS.testnet;

export const provider = new Aptos(
  new AptosConfig({ network: ACTIVE_NETWORK.network })
);

// Your deployed module address from Move.toml
export const MODULE_ADDRESS =
  "0x3fec05744f9ae0b353bd3daa46bdaa16811aea3bd8688f0ca9ac2137308b2d8f";
