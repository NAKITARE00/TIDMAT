import { provider, MODULE_ADDRESS } from "./config";
import type {
  CampaignData,
  ContributionData,
  EscrowData,
  TransactionResult,
} from "./types/contract.types";
import { TransactionPayload } from "@aptos-labs/ts-sdk";

export class TidmatSDK {
  constructor(private readonly moduleAddress: string = MODULE_ADDRESS) {}

  // Campaign View Functions
  async getCampaignDetails(campaignId: string): Promise<CampaignData | null> {
    try {
      const resource = await provider.getAccountResource({
        accountAddress: this.moduleAddress,
        resourceType: `${this.moduleAddress}::campaign::Campaign`,
      });
      return this.parseCampaignData(resource.data);
    } catch (error) {
      console.error("Error fetching campaign:", error);
      return null;
    }
  }

  // Contribution Functions
  async submitContribution(
    sender: string,
    campaignId: string,
    dataHash: string
  ): Promise<TransactionResult> {
    try {
    //   const payload: TransactionPayload = {
    //     type: "entry_function_payload",
    //     function: `${this.moduleAddress}::contribution::submit_contribution`,
    //     type_arguments: [],
    //     arguments: [campaignId, dataHash],
    //   };

      // This will be handled by the wallet
      return {
        success: true,
        hash: "transaction_hash", // This will be the actual hash from the transaction
      };
    } catch (error) {
      return {
        success: false,
        error:
          error instanceof Error ? error.message : "Unknown error occurred",
      };
    }
  }

  // Escrow View Functions
  async getEscrowState(creator: string): Promise<EscrowData | null> {
    try {
      const resource = await provider.getAccountResource({
        accountAddress: creator,
        resourceType: `${this.moduleAddress}::escrow::Escrow`,
      });
      return this.parseEscrowData(resource.data);
    } catch (error) {
      console.error("Error fetching escrow:", error);
      return null;
    }
  }

  // Helper functions to parse contract data
  private parseCampaignData(data: any): CampaignData {
    // Implementation depends on exact contract structure
    return data as CampaignData;
  }

  private parseEscrowData(data: any): EscrowData {
    // Implementation depends on exact contract structure
    return data as EscrowData;
  }
}

// Export singleton instance
export const tidmatSDK = new TidmatSDK();
