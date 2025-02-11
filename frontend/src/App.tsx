import { useState } from "react";
import { AptosWalletProvider, AptosConnectButton } from "@razorlabs/wallet-kit";
import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import CampaignsGrid from "./components/CampaignsGrid";
import Dashboard from "./components/Dashboard";

function App() {
  return (
    <AptosWalletProvider>
      <AppContent />
    </AptosWalletProvider>
  );
}

function AppContent() {
  const [connected, setConnected] = useState(false);
  const [address, setAddress] = useState("");

  return (
    <div className="min-h-screen bg-dark-300">
      <Navbar>
        <AptosConnectButton
          onConnectSuccess={() => {
            setConnected(true);
            // Get address from wallet state
          }}
          onDisconnectSuccess={() => {
            setConnected(false);
            setAddress("");
          }}
        />
      </Navbar>
      {/* <AptosConnectButton /> */}
      <main>
        <Hero />
        <CampaignsGrid />
        {connected && <Dashboard />}
      </main>
    </div>
  );
}

export default App;
