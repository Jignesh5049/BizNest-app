import { useState, useEffect } from 'react';
import { analyticsAPI } from '../services/api';
import { formatCurrency } from '../utils/helpers';
import HealthScoreCard from '../components/HealthScoreCard';
import {
    HiTrendingUp,
    HiTrendingDown,
    HiChartBar
} from 'react-icons/hi';
import {
    AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
    BarChart, Bar, LineChart, Line, ComposedChart, Legend
} from 'recharts';

const Analytics = () => {
    const [stats, setStats] = useState(null);
    const [revenueData, setRevenueData] = useState([]);
    const [topProducts, setTopProducts] = useState([]);
    const [healthScore, setHealthScore] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchAnalytics();
    }, []);

    const fetchAnalytics = async () => {
        try {
            const [statsRes, revenueRes, productsRes, healthRes] = await Promise.all([
                analyticsAPI.getDashboard(),
                analyticsAPI.getRevenueChart(),
                analyticsAPI.getTopProducts(),
                analyticsAPI.getHealthScore()
            ]);
            setStats(statsRes.data);
            setRevenueData(revenueRes.data);
            setTopProducts(productsRes.data);
            setHealthScore(healthRes.data);
        } catch (error) {
            console.error('Failed to fetch analytics:', error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="space-y-8 animate-fadeIn">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Business Analytics</h1>
                <p className="text-gray-600">Deep insights into your business performance</p>
            </div>

            {/* KPI Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="card">
                    <p className="text-sm text-gray-500 mb-1">Monthly Revenue</p>
                    <p className="text-2xl font-bold text-gray-900">{formatCurrency(stats?.revenue?.monthly || 0)}</p>
                    <div className="flex items-center gap-1 mt-2">
                        {stats?.revenue?.growth > 0 ? (
                            <HiTrendingUp className="w-4 h-4 text-green-500" />
                        ) : (
                            <HiTrendingDown className="w-4 h-4 text-red-500" />
                        )}
                        <span className={`text-sm ${stats?.revenue?.growth > 0 ? 'text-green-600' : 'text-red-600'}`}>
                            {Math.abs(stats?.revenue?.growth || 0)}% vs last month
                        </span>
                    </div>
                </div>

                <div className="card">
                    <p className="text-sm text-gray-500 mb-1">Monthly Profit</p>
                    <p className="text-2xl font-bold text-green-600">{formatCurrency(stats?.profit?.net || 0)}</p>
                    <p className="text-sm text-gray-500 mt-2">After expenses</p>
                </div>

                <div className="card">
                    <p className="text-sm text-gray-500 mb-1">Monthly Expenses</p>
                    <p className="text-2xl font-bold text-red-600">{formatCurrency(stats?.expenses?.monthly || 0)}</p>
                    <p className="text-sm text-gray-500 mt-2">This month</p>
                </div>

                <div className="card">
                    <p className="text-sm text-gray-500 mb-1">Repeat Customer Rate</p>
                    <p className="text-2xl font-bold text-purple-600">{stats?.customers?.repeatRate || 0}%</p>
                    <p className="text-sm text-gray-500 mt-2">{stats?.customers?.repeat || 0} repeat customers</p>
                </div>
            </div>

            {/* Revenue vs Expenses Chart */}
            <div className="card">
                <h2 className="text-lg font-semibold text-gray-900 mb-6">Revenue vs Expenses</h2>
                <div className="h-80">
                    <ResponsiveContainer width="100%" height="100%">
                        <ComposedChart data={revenueData}>
                            <defs>
                                <linearGradient id="colorRevenue2" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#22c55e" stopOpacity={0.3} />
                                    <stop offset="95%" stopColor="#22c55e" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                            <XAxis dataKey="month" stroke="#94a3b8" fontSize={12} />
                            <YAxis stroke="#94a3b8" fontSize={12} tickFormatter={(v) => `₹${v / 1000}k`} />
                            <Tooltip
                                formatter={(value, name) => [formatCurrency(value), name]}
                                contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                            />
                            <Legend />
                            <Area
                                type="monotone"
                                dataKey="revenue"
                                stroke="#22c55e"
                                fill="url(#colorRevenue2)"
                                strokeWidth={2}
                                name="Revenue"
                            />
                            <Line
                                type="monotone"
                                dataKey="expenses"
                                stroke="#ef4444"
                                strokeWidth={2}
                                dot={{ fill: '#ef4444', strokeWidth: 2 }}
                                name="Expenses"
                            />
                            <Bar
                                dataKey="profit"
                                fill="#0ea5e9"
                                radius={[4, 4, 0, 0]}
                                name="Profit"
                            />
                        </ComposedChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Bottom Row */}
            <div className="grid lg:grid-cols-2 gap-6">
                {/* Top Selling Products */}
                <div className="card">
                    <h2 className="text-lg font-semibold text-gray-900 mb-6">Top Selling Products</h2>
                    {topProducts.length > 0 ? (
                        <div className="space-y-4">
                            {topProducts.map((product, index) => (
                                <div key={product._id} className="flex items-center gap-4">
                                    <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center">
                                        <span className="font-bold text-primary-600">{index + 1}</span>
                                    </div>
                                    <div className="flex-1">
                                        <p className="font-medium text-gray-900">{product.name}</p>
                                        <div className="w-full bg-gray-100 rounded-full h-2 mt-1">
                                            <div
                                                className="bg-primary-500 h-2 rounded-full"
                                                style={{ width: `${(product.totalQuantity / topProducts[0].totalQuantity) * 100}%` }}
                                            ></div>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-medium">{product.totalQuantity} sold</p>
                                        <p className="text-sm text-gray-500">{formatCurrency(product.totalRevenue)}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <div className="text-center py-8 text-gray-500">
                            <HiChartBar className="w-12 h-12 mx-auto mb-2 text-gray-300" />
                            <p>No sales data yet</p>
                        </div>
                    )}
                </div>

                {/* Health Score */}
                {healthScore && (
                    <HealthScoreCard
                        score={healthScore.score}
                        status={healthScore.status}
                        tips={healthScore.tips}
                        breakdown={healthScore.breakdown}
                    />
                )}
            </div>
        </div>
    );
};

export default Analytics;
