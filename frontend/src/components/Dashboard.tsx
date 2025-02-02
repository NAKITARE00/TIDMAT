const Dashboard = () => {
  return (
    <div className="min-h-screen bg-dark-200 pt-16 sm:pt-20">
      <div className="max-w-7xl mx-auto px-4 py-6 sm:py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-8">
          {/* Profile Section */}
          <div className="bg-dark-100 rounded-xl p-4 sm:p-6 border border-white/10 h-fit">
            <div className="text-center mb-6">
              <div className="w-16 sm:w-20 h-16 sm:h-20 bg-primary-500/10 rounded-full flex items-center justify-center mx-auto mb-4">
                <span className="text-xl sm:text-2xl">👤</span>
              </div>
              <h3 className="font-medium text-sm sm:text-base">0x1234...5678</h3>
              <p className="text-gray-400 text-xs sm:text-sm">Joined Dec 2023</p>
            </div>
            
            <div className="space-y-4">
              <div className="bg-dark-200 rounded-lg p-4">
                <div className="text-gray-400 text-xs sm:text-sm mb-1">Total Earnings</div>
                <div className="text-xl sm:text-2xl font-bold text-primary-400">250 Tokens</div>
              </div>
              
              <div className="bg-dark-200 rounded-lg p-4">
                <div className="text-gray-400 text-xs sm:text-sm mb-1">Campaigns Joined</div>
                <div className="text-xl sm:text-2xl font-bold text-secondary-400">5</div>
              </div>
            </div>
          </div>

          {/* Main Content */}
          <div className="lg:col-span-2 space-y-4 sm:space-y-8">
            <div className="bg-dark-100 rounded-xl p-4 sm:p-6 border border-white/10">
              <h2 className="text-lg sm:text-xl font-bold mb-4">Active Participations</h2>
              {participations.map((item) => (
                <div key={item.id} className="border-b border-white/10 last:border-0 py-4">
                  <div className="flex justify-between items-start mb-2">
                    <div>
                      <h3 className="font-medium text-sm sm:text-base">{item.campaign}</h3>
                      <p className="text-gray-400 text-xs sm:text-sm">{item.status}</p>
                    </div>
                    <span className="text-primary-400 font-medium text-sm sm:text-base">{item.reward} Tokens</span>
                  </div>
                  <div className="w-full bg-dark-200 rounded-full h-2 mt-2">
                    <div 
                      className="bg-primary-500 h-2 rounded-full" 
                      style={{ width: `${item.progress}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

const participations = [
  {
    id: 1,
    campaign: 'Sleep Data Collection',
    status: 'In Progress',
    reward: '50',
    progress: 75
  },
  {
    id: 2,
    campaign: 'Fitness Activity Data',
    status: 'Pending Verification',
    reward: '75',
    progress: 90
  },
];

export default Dashboard; 