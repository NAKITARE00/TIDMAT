import Navbar from './components/Navbar';
import Hero from './components/Hero';
import CampaignsGrid from './components/CampaignsGrid';
import Dashboard from './components/Dashboard';

function App() {
  return (
    <div className="min-h-screen bg-dark-300">
      <Navbar />
      <main>
        <Hero />
        <CampaignsGrid />
        <Dashboard />
      </main>
    </div>
  );
}

export default App;
