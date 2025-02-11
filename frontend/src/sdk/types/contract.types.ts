export interface CampaignData {
  id: string;
  creator: string;
  total_reward_pool: string;
  data_type: string;
  quality_threshold: number;
  deadline: number;
  min_contributions: number;
  max_contributions: number;
  service_fee_percentage: number;
  status: number;
}

export interface ContributionData {
  id: string;
  campaign_id: string;
  contributor: string;
  data_hash: string;
  quality_score: number;
  is_verified: boolean;
  submission_time: number;
  verification_proof: {
    contribution_id: string;
    campaign_id: string;
    verifier: string;
    verification_method: string;
    authenticity_score: number;
    proof_timestamp: number;
    additional_metadata: string;
  };
}

export interface EscrowData {
  creator: string;
  contributor: string;
  amount: string;
  state: {
    is_active: boolean;
    is_funded: boolean;
    is_released: boolean;
    is_refunded: boolean;
  };
  creation_time: number;
}

export enum ContractError {
  CAMPAIGN_NOT_FOUND = "CAMPAIGN_NOT_FOUND",
  ESCROW_NOT_FOUND = "ESCROW_NOT_FOUND",
  INVALID_CONTRIBUTION = "INVALID_CONTRIBUTION",
  TRANSACTION_FAILED = "TRANSACTION_FAILED"
}

export type TransactionResult = {
  success: boolean;
  hash?: string;
  error?: ContractError | string;
}; 