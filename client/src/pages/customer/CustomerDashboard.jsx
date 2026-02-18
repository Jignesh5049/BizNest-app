import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import {
    HiShoppingBag,
    HiTruck,
    HiCheck,
    HiCurrencyRupee,
    HiArrowRight,
    HiClock
} from 'react-icons/hi';

const CustomerDashboard = () => {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchDashboard();
    }, []);

    const fetchDashboard = async () => {
        try {
            const { data } = await storeAPI.getDashboard();
            setData(data);
        } catch (error) {
            console.error('Failed to fetch dashboard:', error);
        } finally {
            setLoading(false);
        }
    };

    const statusConfig = {
        pending: { color: 'bg-yellow-100 text-yellow-700' },
        confirmed: { color: 'bg-blue-100 text-blue-700' },
        completed: { color: 'bg-green-100 text-green-700' },
        cancelled: { color: 'bg-red-100 text-red-700' }
    };

    if (loading) {
        return (
            <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    const stats = data?.stats || {};
    const recentOrders = data?.recentOrders || [];

    return (
        <div className="space-y-6">
            <h1 className="text-2xl font-bold text-gray-800">Dashboard</h1>

            {/* Stats Cards */}
            <div className="grid grid-cols-3 gap-4">
                <div className="stat-card bg-gradient-to-br from-primary-500 to-primary-600">
                    <div className="flex items-center justify-between mb-4">
                        <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
                            <HiShoppingBag className="w-6 h-6" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold mb-1">{stats.totalOrders || 0}</p>
                    <p className="text-primary-100">Total Orders</p>
                </div>

                <div className="stat-card bg-gradient-to-br from-accent-500 to-accent-600">
                    <div className="flex items-center justify-between mb-4">
                        <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
                            <HiTruck className="w-6 h-6" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold mb-1">{stats.activeOrders || 0}</p>
                    <p className="text-accent-100">Active Orders</p>
                </div>

                <div className="stat-card bg-gradient-to-br from-green-500 to-green-600">
                    <div className="flex items-center justify-between mb-4">
                        <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
                            <HiCheck className="w-6 h-6" />
                        </div>
                    </div>
                    <p className="text-3xl font-bold mb-1">{stats.completedOrders || 0}</p>
                    <p className="text-green-100">Completed</p>
                </div>
            </div>

            {/* Recent Orders */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-semibold text-gray-800">Recent Orders</h2>
                    <Link to="/store/orders" className="text-primary-600 hover:text-primary-700 font-medium text-sm flex items-center gap-1">
                        View All
                        <HiArrowRight className="w-4 h-4" />
                    </Link>
                </div>

                {recentOrders.length === 0 ? (
                    <div className="text-center py-8">
                        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <HiShoppingBag className="w-8 h-8 text-gray-400" />
                        </div>
                        <p className="text-gray-500 mb-4">No orders yet</p>
                        <Link to="/store" className="btn-primary">
                            Start Shopping
                        </Link>
                    </div>
                ) : (
                    <div className="space-y-3">
                        {recentOrders.map(order => {
                            const status = statusConfig[order.status] || statusConfig.pending;
                            return (
                                <Link
                                    key={order._id}
                                    to={`/store/orders/${order._id}`}
                                    className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                                >
                                    <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
                                        {order.businessId?.logo ? (
                                            <img src={order.businessId.logo} alt="" className="w-10 h-10 rounded-lg object-cover" />
                                        ) : (
                                            <span className="text-sm font-bold text-primary-600">
                                                {order.businessId?.name?.charAt(0) || 'B'}
                                            </span>
                                        )}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <p className="font-medium text-gray-800 truncate">
                                            {order.businessId?.name || 'Business'}
                                        </p>
                                        <p className="text-sm text-gray-500 flex items-center gap-1">
                                            <HiClock className="w-4 h-4" />
                                            {new Date(order.createdAt).toLocaleDateString('en-IN', {
                                                day: 'numeric',
                                                month: 'short'
                                            })}
                                        </p>
                                    </div>
                                    <div className="text-right">
                                        <p className="font-semibold text-gray-800">₹{order.total?.toLocaleString()}</p>
                                        <span className={`text-xs px-2 py-1 rounded-full ${status.color}`}>
                                            {order.status?.charAt(0).toUpperCase() + order.status?.slice(1)}
                                        </span>
                                    </div>
                                </Link>
                            );
                        })}
                    </div>
                )}
            </div>

            {/* Quick Actions */}
            <div className="grid grid-cols-2 gap-4">
                <Link to="/store" className="card hover:shadow-lg transition-shadow text-center py-8">
                    <div className="w-14 h-14 bg-primary-100 rounded-2xl flex items-center justify-center mx-auto mb-3">
                        <HiShoppingBag className="w-7 h-7 text-primary-600" />
                    </div>
                    <h3 className="font-semibold text-gray-800">Browse Stores</h3>
                    <p className="text-sm text-gray-500">Discover local businesses</p>
                </Link>
                <Link to="/store/favorites" className="card hover:shadow-lg transition-shadow text-center py-8">
                    <div className="w-14 h-14 bg-red-100 rounded-2xl flex items-center justify-center mx-auto mb-3">
                        <svg className="w-7 h-7 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clipRule="evenodd" />
                        </svg>
                    </div>
                    <h3 className="font-semibold text-gray-800">Favorites</h3>
                    <p className="text-sm text-gray-500">Your saved products</p>
                </Link>
            </div>
        </div>
    );
};

export default CustomerDashboard;
