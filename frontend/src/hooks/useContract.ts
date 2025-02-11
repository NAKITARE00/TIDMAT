import { useAptosWallet } from "@razorlabs/wallet-kit";
import { tidmatSDK } from "../sdk/contract";
import { useState, useCallback } from "react";
import { CampaignData, ContractError } from "../sdk/types/contract.types";

export function useContract() {
  const { account } = useAptosWallet();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<ContractError | null>(null);

  const getCampaign = useCallback(async (campaignId: string) => {
    try {
      setLoading(true);
      setError(null);
      return await tidmatSDK.getCampaignDetails(campaignId);
    } catch (err) {
      setError(ContractError.CAMPAIGN_NOT_FOUND);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const submitContribution = useCallback(
    async (campaignId: string, dataHash: string) => {
      if (!account?.address) return;
      try {
        setLoading(true);
        setError(null);
        return await tidmatSDK.submitContribution(
          account.address,
          campaignId,
          dataHash
        );
      } catch (err) {
        setError(ContractError.INVALID_CONTRIBUTION);
        return null;
      } finally {
        setLoading(false);
      }
    },
    [account]
  );

  return {
    getCampaign,
    submitContribution,
    loading,
    error,
  };
}
