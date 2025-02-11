import { useEffect, useState } from "react";
import { useContract } from "../hooks/useContract";
import { CampaignData } from "../sdk/types/contract.types";
import { useAptosWallet } from "@razorlabs/wallet-kit";

const CampaignsGrid = () => {
  const { loading, error, getCampaign } = useContract();
  const { connected } = useAptosWallet();
  const [campaigns, setCampaigns] = useState<CampaignData[]>([]);
  const [loadingCampaigns, setLoadingCampaigns] = useState(true);

  useEffect(() => {
    const fetchCampaigns = async () => {
      try {
        setLoadingCampaigns(true);
        // For now, we'll fetch a single campaign as example
        const campaign = await getCampaign("1");
        if (campaign) {
          setCampaigns([campaign]);
        }
      } catch (err) {
        console.error("Error fetching campaigns:", err);
      } finally {
        setLoadingCampaigns(false);
      }
    };

    if (connected) {
      fetchCampaigns();
    }
  }, [connected, getCampaign]);

  if (loadingCampaigns) {
    return (
      <div className="py-16 sm:py-20 px-4 bg-dark-200">
        <div className="max-w-7xl mx-auto text-center">
          Loading campaigns...
        </div>
      </div>
    );
  }

  return (
    <div className="py-16 sm:py-20 px-4 bg-dark-200">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-2xl sm:text-3xl font-display font-bold mb-8 sm:mb-12 px-4">
          Active Campaigns
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {campaigns.map((campaign) => (
            <div
              key={campaign.id}
              className="bg-dark-100 rounded-xl p-4 sm:p-6 border border-white/10 hover:border-primary-500/50 transition-colors"
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="w-8 sm:w-10 h-8 sm:h-10 rounded-lg bg-blue-500/10 flex items-center justify-center">
                  📊
                </div>
                <div className="font-medium text-sm sm:text-base">
                  {campaign.data_type}
                </div>
              </div>

              <div className="flex items-center justify-between text-xs sm:text-sm mb-4">
                <span className="text-gray-400">Reward Pool</span>
                <span className="font-medium text-primary-400">
                  {campaign.total_reward_pool} APT
                </span>
              </div>

              <div className="flex items-center justify-between text-xs sm:text-sm mb-6">
                <span className="text-gray-400">Quality Threshold</span>
                <span className="font-medium text-secondary-400">
                  {campaign.quality_threshold}%
                </span>
              </div>

              <button
                className="w-full py-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors text-sm sm:text-base"
                onClick={() => {
                  /* TODO: Open campaign details */
                }}
              >
                View Details
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default CampaignsGrid;
