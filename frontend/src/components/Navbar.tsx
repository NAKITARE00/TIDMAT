import { useState } from 'react';

const Navbar = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <nav className="fixed top-0 w-full bg-dark-100/80 backdrop-blur-lg border-b border-white/10 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center">
            <span className="text-xl sm:text-2xl font-display font-bold bg-gradient-to-r from-primary-400 to-secondary-400 text-transparent bg-clip-text">
              DataMarket
            </span>
          </div>
          
          {/* Mobile menu button */}
          <div className="md:hidden">
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="text-gray-300 hover:text-white p-2"
            >
              <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                {isMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>
          </div>
          
          {/* Desktop menu */}
          <div className="hidden md:flex items-center gap-6">
            <a href="#campaigns" className="text-gray-300 hover:text-white transition-colors">
              Campaigns
            </a>
            <a href="#how-it-works" className="text-gray-300 hover:text-white transition-colors">
              How it Works
            </a>
            <button
              onClick={() => setIsConnected(!isConnected)}
              className={`px-4 py-2 rounded-lg font-medium transition-all ${
                isConnected
                ? 'bg-green-500/10 text-green-500 hover:bg-green-500/20'
                : 'bg-primary-500 hover:bg-primary-600 text-white'
              }`}
            >
              {isConnected ? '0x1234...5678' : 'Connect Wallet'}
            </button>
          </div>
        </div>
      </div>
      
      {/* Mobile menu */}
      <div className={`md:hidden ${isMenuOpen ? 'block' : 'hidden'}`}>
        <div className="px-2 pt-2 pb-3 space-y-1 bg-dark-100/95 border-b border-white/10">
          <a href="#campaigns" className="block px-3 py-2 text-gray-300 hover:text-white transition-colors">
            Campaigns
          </a>
          <a href="#how-it-works" className="block px-3 py-2 text-gray-300 hover:text-white transition-colors">
            How it Works
          </a>
          <button
            onClick={() => setIsConnected(!isConnected)}
            className={`w-full text-left px-3 py-2 rounded-lg font-medium transition-all ${
              isConnected
              ? 'bg-green-500/10 text-green-500 hover:bg-green-500/20'
              : 'bg-primary-500 hover:bg-primary-600 text-white'
            }`}
          >
            {isConnected ? '0x1234...5678' : 'Connect Wallet'}
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navbar; 