const Hero = () => {
  return (
    <div className="pt-24 sm:pt-32 pb-16 sm:pb-20 px-4">
      <div className="max-w-7xl mx-auto text-center">
        <h1 className="text-4xl sm:text-5xl md:text-6xl font-display font-bold mb-6">
          <span className="bg-gradient-to-r from-primary-400 to-secondary-400 text-transparent bg-clip-text">
            Share Data.
          </span>{' '}
          <br className="sm:hidden" />
          Earn Tokens.
        </h1>
        <p className="text-lg sm:text-xl text-gray-400 max-w-2xl mx-auto mb-8 px-4">
          Join the decentralized marketplace where your data becomes valuable. 
          Participate in AI training campaigns and earn rewards securely.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center px-4">
          <button className="px-8 py-3 bg-primary-500 hover:bg-primary-600 rounded-lg font-medium transition-colors">
            Browse Campaigns
          </button>
          <button className="px-8 py-3 bg-white/10 hover:bg-white/20 rounded-lg font-medium transition-colors">
            Learn More
          </button>
        </div>
        
        <div className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-8 max-w-3xl mx-auto px-4">
          {stats.map((stat) => (
            <div key={stat.label} className="bg-dark-100/50 rounded-xl p-6 border border-white/10">
              <div className="text-2xl sm:text-3xl font-bold text-primary-400">{stat.value}</div>
              <div className="text-sm sm:text-base text-gray-400 mt-1">{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const stats = [
  { value: '50K+', label: 'Contributors' },
  { value: '$2M+', label: 'Rewards Paid' },
  { value: '100+', label: 'Active Campaigns' },
];

export default Hero; 