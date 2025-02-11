import { PetraWallet } from "petra-plugin-wallet-adapter";

declare global {
  interface Window {
    aptos?: PetraWallet;
  }
}

export {}; 