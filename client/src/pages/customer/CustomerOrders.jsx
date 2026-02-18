import { useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import {
    HiShoppingBag,
    HiClock,
    HiCheck,
    HiX,
    HiEye,
    HiRefresh,
    HiShoppingCart,
    HiCube
} from 'react-icons/hi';

const statusConfig = {
    pending: { label: 'Pending', color: 'bg-yellow-100 text-yellow-800', icon: HiClock },
    confirmed: { label: 'Confirmed', color: 'bg-blue-100 text-blue-800', icon: HiCheck },
    completed: { label: 'Completed', color: 'bg-green-100 text-green-800', icon: HiCheck },
    cancelled: { label: 'Cancelled', color: 'bg-red-100 text-red-800', icon: HiX }
};

const CustomerOrders = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('all');
    const [showSuccess, setShowSuccess] = useState(location.state?.orderPlaced);
    const { addItemsForReorder } = useCart();

    useEffect(() => {
        fetchOrders();
        if (showSuccess) {
            const timer = setTimeout(() => setShowSuccess(false), 5000);
            return () => clearTimeout(timer);
        }
    }, [statusFilter]);

    const fetchOrders = async () => {
        try {
            setLoading(true);
            const params = statusFilter !== 'all' ? { status: statusFilter } : {};
            const { data } = await storeAPI.getOrders(params);
            setOrders(data);
        } catch (error) {
            console.error('Failed to fetch orders:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleReorder = (order) => {
        // Add items to cart instead of directly creating order
        const items = order.items.map(item => ({
            productId: item.productId,
            name: item.name,
            price: item.price,
            image: item.image,
            quantity: item.quantity,
            businessId: order.businessId?._id
        }));
        addItemsForReorder(items);
        navigate('/store/cart');
    };

    const filters = [
        { value: 'all', label: 'All Orders' },
        { value: 'pending', label: 'Pending' },
        { value: 'confirmed', label: 'Confirmed' },
        { value: 'completed', label: 'Completed' },
        { value: 'cancelled', label: 'Cancelled' }
    ];

    return (
        <div className="max-w-4xl mx-auto">
            {/* Success Message */}
            {showSuccess && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-xl mb-6 flex items-center gap-3">
                    <HiCheck className="w-6 h-6" />
                    <span className="font-medium">Order placed successfully! You can track your order here.</span>
                </div>
            )}

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-3">
                    <HiShoppingBag className="w-7 h-7 text-primary-600" />
                    My Orders
                </h1>

                {/* Status Filter */}
                <div className="flex gap-2 overflow-x-auto">
                    {filters.map(filter => (
                        <button
                            key={filter.value}
                            onClick={() => setStatusFilter(filter.value)}
                            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${statusFilter === filter.value
                                ? 'bg-primary-600 text-white'
                                : 'bg-white text-gray-600 border border-gray-200 hover:border-gray-300'
                                }`}
                        >
                            {filter.label}
                        </button>
                    ))}
                </div>
            </div>

            {loading ? (
                <div className="flex flex-col items-center justify-center py-16">
                    <div className="w-12 h-12 border-4 border-primary-200 rounded-full animate-spin border-t-primary-600"></div>
                    <p className="mt-4 text-gray-500">Loading orders...</p>
                </div>
            ) : orders.length === 0 ? (
                <div className="text-center py-16 bg-white rounded-2xl border border-gray-100">
                    <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <HiShoppingBag className="w-10 h-10 text-gray-400" />
                    </div>
                    <h3 className="text-xl font-semibold text-gray-800 mb-2">No Orders Found</h3>
                    <p className="text-gray-500 mb-6">
                        {statusFilter !== 'all'
                            ? `You don't have any ${statusFilter} orders.`
                            : "You haven't placed any orders yet."}
                    </p>
                    <Link to="/store" className="btn-primary inline-flex items-center gap-2">
                        <HiShoppingCart className="w-5 h-5" />
                        Start Shopping
                    </Link>
                </div>
            ) : (
                <div className="space-y-4">
                    {orders.map(order => {
                        const status = statusConfig[order.status] || statusConfig.pending;
                        const StatusIcon = status.icon;

                        return (
                            <div key={order._id} className="card hover:shadow-lg transition-shadow">
                                {/* Order Header */}
                                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-4 pb-4 border-b">
                                    <div>
                                        <div className="flex items-center gap-3 mb-1">
                                            <h3 className="font-semibold text-gray-800">
                                                Order #{order.orderNumber}
                                            </h3>
                                            <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium ${status.color}`}>
                                                <StatusIcon className="w-3 h-3" />
                                                {status.label}
                                            </span>
                                        </div>
                                        <p className="text-sm text-gray-500">
                                            {new Date(order.createdAt).toLocaleDateString('en-IN', {
                                                day: 'numeric',
                                                month: 'long',
                                                year: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </p>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-lg font-bold text-primary-600">
                                            ₹{order.total?.toLocaleString()}
                                        </p>
                                        <p className="text-sm text-gray-500">
                                            {order.items?.length} item{order.items?.length !== 1 ? 's' : ''}
                                        </p>
                                    </div>
                                </div>

                                {/* Business Info */}
                                {order.businessId && (
                                    <div className="flex items-center gap-3 mb-4">
                                        <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                                            {order.businessId.logo ? (
                                                <img src={order.businessId.logo} alt="" className="w-8 h-8 rounded-lg object-cover" />
                                            ) : (
                                                <span className="text-sm font-bold text-primary-600">
                                                    {order.businessId.name?.charAt(0)}
                                                </span>
                                            )}
                                        </div>
                                        <span className="font-medium text-gray-700">{order.businessId.name}</span>
                                    </div>
                                )}

                                {/* Order Items Preview */}
                                <div className="flex gap-2 overflow-x-auto mb-4">
                                    {order.items?.slice(0, 4).map((item, index) => (
                                        <div key={index} className="flex-shrink-0 w-16 h-16 bg-gray-100 rounded-lg overflow-hidden flex items-center justify-center">
                                            {item.image ? (
                                                <img src={item.image} alt={item.name} className="w-full h-full object-cover" />
                                            ) : (
                                                <HiCube className="w-8 h-8 text-gray-300" />
                                            )}
                                        </div>
                                    ))}
                                    {order.items?.length > 4 && (
                                        <div className="flex-shrink-0 w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center text-gray-500 font-medium">
                                            +{order.items.length - 4}
                                        </div>
                                    )}
                                </div>

                                {/* Actions */}
                                <div className="flex gap-3">
                                    <Link
                                        to={`/store/orders/${order._id}`}
                                        className="btn-secondary py-2 px-4 flex items-center gap-2"
                                    >
                                        <HiEye className="w-4 h-4" />
                                        View Details
                                    </Link>
                                    {order.status === 'completed' && (
                                        <button
                                            onClick={() => handleReorder(order)}
                                            className="btn-primary py-2 px-4 flex items-center gap-2"
                                        >
                                            <HiRefresh className="w-4 h-4" />
                                            Reorder
                                        </button>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default CustomerOrders;
