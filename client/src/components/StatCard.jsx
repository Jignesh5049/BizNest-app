const StatCard = ({ title, value, icon: Icon, trend, trendValue, color = 'primary', subtitle }) => {
    const colorClasses = {
        primary: 'from-primary-500 to-primary-600',
        green: 'from-green-500 to-green-600',
        purple: 'from-purple-500 to-purple-600',
        orange: 'from-orange-500 to-orange-600',
        blue: 'from-blue-500 to-blue-600',
        pink: 'from-pink-500 to-pink-600'
    };

    const bgGradient = colorClasses[color] || colorClasses.primary;

    return (
        <div className={`stat-card bg-gradient-to-br ${bgGradient}`}>
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-white/80 text-sm font-medium">{title}</p>
                    <h3 className="text-2xl font-bold text-white mt-1">{value}</h3>
                    {subtitle && (
                        <p className="text-white/70 text-sm mt-1">{subtitle}</p>
                    )}
                </div>
                {Icon && (
                    <div className="p-3 bg-white/20 rounded-xl">
                        <Icon className="w-6 h-6 text-white" />
                    </div>
                )}
            </div>

            {trend && (
                <div className="mt-4 flex items-center gap-2">
                    <span className={`text-sm font-medium ${trend === 'up' ? 'text-green-200' : 'text-red-200'}`}>
                        {trend === 'up' ? '↑' : '↓'} {trendValue}
                    </span>
                    <span className="text-white/60 text-sm">vs last month</span>
                </div>
            )}
        </div>
    );
};

export default StatCard;
