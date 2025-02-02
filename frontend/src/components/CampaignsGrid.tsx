const CampaignsGrid = () => {
  return (
    <div className="py-16 sm:py-20 px-4 bg-dark-200">
      <div className="max-w-7xl mx-auto">
        <h2 className="text-2xl sm:text-3xl font-display font-bold mb-8 sm:mb-12 px-4">Active Campaigns</h2>
        
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          {campaigns.map((campaign) => (
            <div key={campaign.id} className="bg-dark-100 rounded-xl p-4 sm:p-6 border border-white/10 hover:border-primary-500/50 transition-colors">
              <div className="flex items-center gap-3 mb-4">
                <div className={`w-8 sm:w-10 h-8 sm:h-10 rounded-lg ${campaign.bgColor} flex items-center justify-center`}>
                  {campaign.icon}
                </div>
                <div className="font-medium text-sm sm:text-base">{campaign.name}</div>
              </div>
              
              <p className="text-xs sm:text-sm text-gray-400 mb-4">{campaign.description}</p>
              
              <div className="flex items-center justify-between text-xs sm:text-sm mb-4">
                <span className="text-gray-400">Reward</span>
                <span className="font-medium text-primary-400">{campaign.reward} Tokens</span>
              </div>
              
              <div className="flex items-center justify-between text-xs sm:text-sm mb-6">
                <span className="text-gray-400">Time Left</span>
                <span className="font-medium text-secondary-400">{campaign.timeLeft}</span>
              </div>
              
              <button className="w-full py-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors text-sm sm:text-base">
                View Details
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const campaigns = [
  {
    id: 1,
    name: 'Sleep Data Collection',
    description: 'Share your sleep patterns data from wearable devices for AI research.',
    reward: '50',
    timeLeft: '5 days',
    bgColor: 'bg-blue-500/10',
    icon: '😴'
  },
  {
    id: 2,
    name: 'Fitness Activity Data',
    description: 'Contribute your workout and activity data for health research.',
    reward: '75',
    timeLeft: '3 days',
    bgColor: 'bg-green-500/10',
    icon: '🏃‍♂️'
  },
  {
    id: 3,
    name: 'Heart Rate Monitoring',
    description: 'Share heart rate data from your smartwatch for medical research.',
    reward: '100',
    timeLeft: '7 days',
    bgColor: 'bg-red-500/10',
    icon: '❤️'
  },
];

export default CampaignsGrid; 