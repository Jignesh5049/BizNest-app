import { HiLightBulb } from 'react-icons/hi';

const HealthScoreCard = ({ score, status, tips, breakdown }) => {
    const getColor = () => {
        if (score >= 70) return { ring: 'text-green-500', bg: 'bg-green-500', label: 'Healthy' };
        if (score >= 40) return { ring: 'text-yellow-500', bg: 'bg-yellow-500', label: 'Moderate' };
        return { ring: 'text-red-500', bg: 'bg-red-500', label: 'Needs Attention' };
    };

    const colors = getColor();
    const circumference = 2 * Math.PI * 45;
    const progress = (score / 100) * circumference;

    return (
        <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Business Health Score</h3>
            <div className="flex flex-col lg:flex-row items-center gap-6">
                {/* Score Circle */}
                <div className="relative flex-shrink-0">
                    <svg className="w-28 h-28 -rotate-90">
                        <circle
                            cx="56"
                            cy="56"
                            r="45"
                            stroke="currentColor"
                            strokeWidth="8"
                            fill="transparent"
                            className="text-gray-100"
                        />
                        <circle
                            cx="56"
                            cy="56"
                            r="45"
                            stroke="currentColor"
                            strokeWidth="8"
                            fill="transparent"
                            strokeDasharray={circumference}
                            strokeDashoffset={circumference - progress}
                            strokeLinecap="round"
                            className={colors.ring}
                        />
                    </svg>
                    <div className="absolute inset-0 flex items-center justify-center">
                        <div className="text-center">
                            <span className="text-2xl font-bold text-gray-900">{score}</span>
                            <span className="text-gray-500 text-xs block">/ 100</span>
                        </div>
                    </div>
                </div>

                {/* Info */}
                <div className="flex-1 w-full">
                    <div className="flex items-center gap-2 mb-3">
                        <div className={`w-3 h-3 rounded-full ${colors.bg}`}></div>
                        <span className="font-semibold text-gray-900">{colors.label}</span>
                    </div>

                    {breakdown && (
                        <div className="space-y-2 text-sm mb-4">
                            <div className="flex items-center justify-between">
                                <span className="text-gray-500">Orders</span>
                                <span className="font-medium text-gray-900">{breakdown.orderFrequency}/25</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-gray-500">Margin</span>
                                <span className="font-medium text-gray-900">{breakdown.profitMargin}/25</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-gray-500">Inventory</span>
                                <span className="font-medium text-gray-900">{breakdown.inventoryHealth}/25</span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-gray-500">Customers</span>
                                <span className="font-medium text-gray-900">{breakdown.customerRetention}/25</span>
                            </div>
                        </div>
                    )}

                    {tips && tips.length > 0 && (
                        <div className="space-y-1.5 border-t border-gray-100 pt-3">
                            <p className="text-xs font-medium text-gray-700 uppercase tracking-wider">Tips</p>
                            {tips.map((tip, index) => (
                                <p key={index} className="text-sm text-gray-600 flex items-start gap-2">
                                    <HiLightBulb className="w-4 h-4 text-primary-500 flex-shrink-0 mt-0.5" />
                                    <span>{tip}</span>
                                </p>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default HealthScoreCard;
