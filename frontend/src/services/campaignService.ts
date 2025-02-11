import { Provider, Network } from "@aptos-labs/ts-sdk";
import { PetraWallet } from "petra-plugin-wallet-adapter";

const NETWORK = Network.TESTNET; // or Network.MAINNET for production
const provider = new Provider(NETWORK);
const moduleAddress = "YOUR_CONTRACT_ADDRESS"; // Replace with your deployed contract address

export class CampaignService {
  static async createCampaign(
    wallet: PetraWallet,
    totalRewardPool: number,
    dataType: string,
    qualityThreshold: number,
    deadline: number,
    minContributions: number,
    maxContributions: number,
    serviceFeePercentage: number
  ) {
    const payload = {
      function: `${moduleAddress}::campaign::create_campaign`,
      type_arguments: ["0x1::aptos_coin::AptosCoin"],
      arguments: [
        totalRewardPool,
        Array.from(new TextEncoder().encode(dataType)),
        qualityThreshold,
        deadline,
        minContributions,
        maxContributions,
        serviceFeePercentage
      ]
    };

    try {
      const transaction = await wallet.signAndSubmitTransaction(payload);
      return transaction;
    } catch (error) {
      console.error("Transaction failed:", error);
      throw error;
    }
  }

  static async getCampaignDetails(creatorAddress: string) {
    const resources = await provider.getAccountResources(creatorAddress);
    const campaignResource = resources.find(
      (r) => r.type === `${moduleAddress}::campaign::Campaign`
    );
    return campaignResource?.data;
  }

  static async getCampaignStatus(creatorAddress: string) {
    try {
      const response = await provider.view({
        function: `${moduleAddress}::campaign::get_campaign_status`,
        type_arguments: [],
        arguments: [creatorAddress]
      });
      return response[0] as number;
    } catch (error) {
      console.error("Error fetching campaign status:", error);
      throw error;
    }
  }
} 