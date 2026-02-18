import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { analyticsAPI } from '../services/api';
import { formatCurrency } from '../utils/helpers';
import StatCard from '../components/StatCard';
import HealthScoreCard from '../components/HealthScoreCard';
import {
    HiCurrencyRupee,
    HiShoppingCart,
    HiTrendingUp,
    HiCube,
    HiUsers,
    HiPlus,
    HiDocumentAdd,
    HiChartBar,
    HiExclamation,
    HiHand
} from 'react-icons/hi';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';

const Dashboard = () => {
    const { business, user } = useAuth();
    const [stats, setStats] = useState(null);
    const [revenueData, setRevenueData] = useState([]);
    const [topProducts, setTopProducts] = useState([]);
    const [healthScore, setHealthScore] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDashboardData();
    }, []);

    const fetchDashboardData = async () => {
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
            console.error('Failed to fetch dashboard data:', error);
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
            <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                <div>
                    <h1 className="text-xl md:text-2xl font-bold text-gray-900 flex items-center gap-2">
                        Welcome back, {user?.name?.split(' ')[0]}!
                        <HiHand className="w-5 h-5 md:w-6 md:h-6 text-yellow-500" />
                    </h1>
                    <p className="text-gray-600 mt-1 text-sm md:text-base">{business?.name} Dashboard</p>
                </div>
                <div className="flex flex-col sm:flex-row gap-2 md:gap-3">
                    <Link to="/products" className="btn-secondary flex items-center justify-center gap-2 text-sm md:text-base px-3 md:px-4 py-2 md:py-2.5">
                        <HiPlus className="w-4 h-4 md:w-5 md:h-5" />
                        Add Product
                    </Link>
                    <Link to="/orders" className="btn-primary flex items-center justify-center gap-2 text-sm md:text-base px-3 md:px-4 py-2 md:py-2.5">
                        <HiDocumentAdd className="w-4 h-4 md:w-5 md:h-5" />
                        New Order
                    </Link>
                </div>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard
                    title="Total Revenue"
                    value={formatCurrency(stats?.revenue?.total || 0)}
                    icon={HiCurrencyRupee}
                    color="green"
                    subtitle={`${formatCurrency(stats?.revenue?.monthly || 0)} this month`}
                    trend={stats?.revenue?.growth > 0 ? 'up' : 'down'}
                    trendValue={`${Math.abs(stats?.revenue?.growth || 0)}%`}
                />
                <StatCard
                    title="Total Orders"
                    value={stats?.orders?.total || 0}
                    icon={HiShoppingCart}
                    color="blue"
                    subtitle={`${stats?.orders?.monthly || 0} this month`}
                />
                <StatCard
                    title="Net Profit"
                    value={formatCurrency(stats?.profit?.net || 0)}
                    icon={HiTrendingUp}
                    color="purple"
                    subtitle="This month"
                />
                <StatCard
                    title="Total Customers"
                    value={stats?.customers?.total || 0}
                    icon={HiUsers}
                    color="orange"
                    subtitle={`${stats?.customers?.repeatRate || 0}% repeat rate`}
                />
            </div>

            {/* Alerts */}
            {(stats?.orders?.pending > 0 || stats?.products?.lowStock > 0) && (
                <div className="grid md:grid-cols-2 gap-4">
                    {stats?.orders?.pending > 0 && (
                        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 flex items-center gap-4">
                            <div className="p-3 bg-yellow-100 rounded-xl">
                                <HiExclamation className="w-6 h-6 text-yellow-600" />
                            </div>
                            <div>
                                <p className="font-medium text-yellow-800">Pending Orders</p>
                                <p className="text-sm text-yellow-600">{stats.orders.pending} orders awaiting action</p>
                            </div>
                            <Link to="/orders?status=pending" className="ml-auto text-yellow-700 font-medium hover:underline">
                                View →
                            </Link>
                        </div>
                    )}
                    {stats?.products?.lowStock > 0 && (
                        <div className="bg-red-50 border border-red-200 rounded-xl p-4 flex items-center gap-4">
                            <div className="p-3 bg-red-100 rounded-xl">
                                <HiCube className="w-6 h-6 text-red-600" />
                            </div>
                            <div>
                                <p className="font-medium text-red-800">Low Stock Alert</p>
                                <p className="text-sm text-red-600">{stats.products.lowStock} products running low</p>
                            </div>
                            <Link to="/products" className="ml-auto text-red-700 font-medium hover:underline">
                                View →
                            </Link>
                        </div>
                    )}
                </div>
            )}

            {/* Charts & Health Score */}
            <div className="grid lg:grid-cols-3 gap-6">
                {/* Revenue Chart */}
                <div className="lg:col-span-2 card">
                    <div className="flex items-center justify-between mb-6">
                        <h2 className="text-lg font-semibold text-gray-900">Revenue Overview</h2>
                        <Link to="/analytics" className="text-primary-600 text-sm font-medium hover:underline">
                            View Details →
                        </Link>
                    </div>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <AreaChart data={revenueData}>
                                <defs>
                                    <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="5%" stopColor="#50C878" stopOpacity={0.3} />
                                        <stop offset="95%" stopColor="#50C878" stopOpacity={0} />
                                    </linearGradient>
                                </defs>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                                <XAxis dataKey="month" stroke="#94a3b8" fontSize={12} />
                                <YAxis stroke="#94a3b8" fontSize={12} tickFormatter={(value) => `₹${value / 1000}k`} />
                                <Tooltip
                                    formatter={(value) => [formatCurrency(value), 'Revenue']}
                                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                                />
                                <Area type="monotone" dataKey="revenue" stroke="#0B6E4F" fill="url(#colorRevenue)" strokeWidth={2} />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
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

            {/* Top Products & Quick Actions */}
            <div className="grid lg:grid-cols-2 gap-6">
                {/* Top Products */}
                <div className="card">
                    <div className="flex items-center justify-between mb-6">
                        <h2 className="text-lg font-semibold text-gray-900">Top Selling Products</h2>
                        <Link to="/analytics" className="text-primary-600 text-sm font-medium hover:underline">
                            View All →
                        </Link>
                    </div>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={topProducts} layout="vertical">
                                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" horizontal={false} />
                                <XAxis type="number" stroke="#94a3b8" fontSize={12} />
                                <YAxis dataKey="name" type="category" stroke="#94a3b8" fontSize={12} width={100} />
                                <Tooltip
                                    formatter={(value, name) => [value, name === 'totalQuantity' ? 'Units Sold' : 'Revenue']}
                                    contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
                                />
                                <Bar dataKey="totalQuantity" fill="#50C878" radius={[0, 4, 4, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* Quick Actions */}
                <div className="card">
                    <h2 className="text-lg font-semibold text-gray-900 mb-6">Quick Actions</h2>
                    <div className="grid grid-cols-2 gap-4">
                        <Link to="/products" className="p-4 bg-blue-50 hover:bg-blue-100 rounded-xl transition-colors group">
                            <HiCube className="w-8 h-8 text-blue-600 mb-2" />
                            <p className="font-medium text-gray-900">Add Product</p>
                            <p className="text-sm text-gray-500">Create new product</p>
                        </Link>
                        <Link to="/orders" className="p-4 bg-green-50 hover:bg-green-100 rounded-xl transition-colors group">
                            <HiShoppingCart className="w-8 h-8 text-green-600 mb-2" />
                            <p className="font-medium text-gray-900">New Order</p>
                            <p className="text-sm text-gray-500">Create order</p>
                        </Link>
                        <Link to="/customers" className="p-4 bg-purple-50 hover:bg-purple-100 rounded-xl transition-colors group">
                            <HiUsers className="w-8 h-8 text-purple-600 mb-2" />
                            <p className="font-medium text-gray-900">Add Customer</p>
                            <p className="text-sm text-gray-500">New customer</p>
                        </Link>
                        <Link to="/analytics" className="p-4 bg-orange-50 hover:bg-orange-100 rounded-xl transition-colors group">
                            <HiChartBar className="w-8 h-8 text-orange-600 mb-2" />
                            <p className="font-medium text-gray-900">View Analytics</p>
                            <p className="text-sm text-gray-500">Business insights</p>
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Dashboard;
