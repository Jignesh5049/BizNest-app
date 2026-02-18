import { useState, useEffect } from 'react';
import { ordersAPI, customersAPI, productsAPI } from '../services/api';
import { formatCurrency, formatDate, getStatusColor } from '../utils/helpers';
import Modal from '../components/Modal';
import {
    HiPlus,
    HiShoppingCart,
    HiSearch,
    HiCheck,
    HiClock,
    HiX,
    HiEye,
    HiDocumentText,
    HiCash,
    HiViewGrid,
    HiViewList
} from 'react-icons/hi';
import { Link } from 'react-router-dom';

const Orders = () => {
    const [orders, setOrders] = useState([]);
    const [customers, setCustomers] = useState([]);
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [selectedOrder, setSelectedOrder] = useState(null);
    const [filterStatus, setFilterStatus] = useState('');
    const [searchQuery, setSearchQuery] = useState('');
    const viewStorageKey = 'admin-orders-view';
    const [viewMode, setViewMode] = useState(() => localStorage.getItem(viewStorageKey) || 'grid');

    // Order form state
    const [formData, setFormData] = useState({
        customerId: '',
        items: [],
        discount: 0,
        notes: '',
        paymentMethod: 'cash'
    });
    const [selectedProduct, setSelectedProduct] = useState('');
    const [quantity, setQuantity] = useState(1);

    useEffect(() => {
        fetchData();
    }, [filterStatus]);

    useEffect(() => {
        localStorage.setItem(viewStorageKey, viewMode);
    }, [viewMode]);

    const fetchData = async () => {
        try {
            const [ordersRes, customersRes, productsRes] = await Promise.all([
                ordersAPI.getAll({ status: filterStatus || undefined }),
                customersAPI.getAll(),
                productsAPI.getAll()
            ]);
            setOrders(ordersRes.data);
            setCustomers(customersRes.data);
            setProducts(productsRes.data);
        } catch (error) {
            console.error('Failed to fetch data:', error);
        } finally {
            setLoading(false);
        }
    };

    const addItem = () => {
        if (!selectedProduct) return;
        const product = products.find(p => p._id === selectedProduct);
        if (!product) return;

        const existingIndex = formData.items.findIndex(i => i.productId === selectedProduct);
        if (existingIndex > -1) {
            const newItems = [...formData.items];
            newItems[existingIndex].quantity += quantity;
            setFormData({ ...formData, items: newItems });
        } else {
            setFormData({
                ...formData,
                items: [...formData.items, {
                    productId: product._id,
                    name: product.name,
                    price: product.sellingPrice,
                    quantity
                }]
            });
        }
        setSelectedProduct('');
        setQuantity(1);
    };

    const removeItem = (index) => {
        const newItems = [...formData.items];
        newItems.splice(index, 1);
        setFormData({ ...formData, items: newItems });
    };

    const calculateTotal = () => {
        const subtotal = formData.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
        return subtotal - (formData.discount || 0);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (formData.items.length === 0) {
            alert('Please add at least one item');
            return;
        }
        try {
            await ordersAPI.create({
                customerId: formData.customerId,
                items: formData.items.map(i => ({ productId: i.productId, quantity: i.quantity })),
                discount: parseFloat(formData.discount) || 0,
                notes: formData.notes,
                paymentMethod: formData.paymentMethod
            });
            fetchData();
            closeModal();
        } catch (error) {
            console.error('Failed to create order:', error);
            alert(error.response?.data?.message || 'Failed to create order');
        }
    };

    const updatePaymentStatus = async (orderId, paymentStatus) => {
        try {
            await ordersAPI.updatePayment(orderId, { paymentStatus });
            fetchData();
            // Auto-close modal after successful update
            if (showDetailModal) {
                setShowDetailModal(false);
                setSelectedOrder(null);
            }
        } catch (error) {
            console.error('Failed to update payment:', error);
        }
    };

    const updateOrderStatus = async (orderId, status) => {
        try {
            await ordersAPI.updateStatus(orderId, status);
            fetchData();
            // Auto-close modal after successful update
            if (showDetailModal) {
                setShowDetailModal(false);
                setSelectedOrder(null);
            }
        } catch (error) {
            console.error('Failed to update status:', error);
        }
    };

    const viewOrderDetails = async (order) => {
        try {
            const { data } = await ordersAPI.getOne(order._id);
            setSelectedOrder(data);
            setShowDetailModal(true);
        } catch (error) {
            console.error('Failed to fetch order:', error);
        }
    };

    const closeModal = () => {
        setShowModal(false);
        setFormData({ customerId: '', items: [], discount: 0, notes: '', paymentMethod: 'cash' });
    };

    const filteredOrders = orders.filter(o =>
        o.orderNumber?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.customerId?.name?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Header */}
            <div className="flex flex-col gap-4">
                {/* Title + View Toggle */}
                <div className="flex items-center justify-between gap-3">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-900">Orders</h1>
                        <p className="text-gray-600">{orders.length} total orders</p>
                    </div>
                    <div className="flex items-center bg-gray-100 rounded-xl p-1 w-fit">
                        <button
                            onClick={() => setViewMode('grid')}
                            className={`p-2 rounded-lg transition-colors ${viewMode === 'grid'
                                ? 'bg-white text-primary-600 shadow'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                            title="Card view"
                        >
                            <HiViewGrid className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => setViewMode('list')}
                            className={`p-2 rounded-lg transition-colors ${viewMode === 'list'
                                ? 'bg-white text-primary-600 shadow'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                            title="List view"
                        >
                            <HiViewList className="w-5 h-5" />
                        </button>
                    </div>
                </div>
                {/* Controls */}
                <div>
                    <div className="flex flex-col sm:flex-row sm:flex-wrap gap-3">
                        <div className="relative w-full sm:w-48">
                            <HiSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                placeholder="Search orders..."
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="input pl-10 w-full"
                            />
                        </div>
                        <select
                            value={filterStatus}
                            onChange={(e) => setFilterStatus(e.target.value)}
                            className="input w-full sm:w-40"
                        >
                            <option value="">All Status</option>
                            <option value="pending">Pending</option>
                            <option value="confirmed">Confirmed</option>
                            <option value="completed">Completed</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                        <button onClick={() => setShowModal(true)} className="btn-primary flex items-center justify-center gap-2 w-full sm:w-auto">
                            <HiPlus className="w-5 h-5" />
                            New Order
                        </button>
                    </div>
                </div>
            </div>

            {/* Orders List */}
            {filteredOrders.length === 0 ? (
                <div className="card text-center py-12">
                    <HiShoppingCart className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No orders yet</h3>
                    <p className="text-gray-500 mb-4">Create your first order</p>
                    <button onClick={() => setShowModal(true)} className="btn-primary">
                        Create Order
                    </button>
                </div>
            ) : (
                viewMode === 'grid' ? (
                    <div className="space-y-4">
                        {filteredOrders.map((order) => (
                            <div key={order._id} className="card hover:shadow-card-hover">
                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                                    <div className="flex items-center gap-4">
                                        <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                                            <HiShoppingCart className="w-6 h-6 text-blue-600" />
                                        </div>
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <h3 className="font-semibold text-gray-900">{order.orderNumber}</h3>
                                                <span className={`badge ${getStatusColor(order.status)}`}>{order.status}</span>
                                                <span className={`badge ${getStatusColor(order.paymentStatus)}`}>{order.paymentStatus}</span>
                                            </div>
                                            <p className="text-sm text-gray-500">
                                                {order.customerId?.name || 'Unknown Customer'} • {formatDate(order.createdAt)}
                                            </p>
                                        </div>
                                    </div>

                                    <div className="flex items-center gap-4">
                                        <div className="text-right">
                                            <p className="text-lg font-bold text-gray-900">{formatCurrency(order.total)}</p>
                                            <p className="text-sm text-gray-500">{order.items?.length || 0} items</p>
                                        </div>

                                        <div className="flex items-center gap-2">
                                            {order.paymentStatus !== 'paid' && order.status !== 'cancelled' && (
                                                <button
                                                    onClick={() => updatePaymentStatus(order._id, 'paid')}
                                                    className="btn-success py-2 px-4 flex items-center gap-2"
                                                    title="Mark as Paid"
                                                >
                                                    <HiCash className="w-4 h-4" />
                                                    Mark Paid
                                                </button>
                                            )}
                                            <button
                                                onClick={() => viewOrderDetails(order)}
                                                className="btn-secondary py-2 px-4"
                                            >
                                                <HiEye className="w-4 h-4" />
                                            </button>
                                            <Link
                                                to={`/invoices?order=${order._id}`}
                                                className="btn-secondary py-2 px-4"
                                                title="View Invoice"
                                            >
                                                <HiDocumentText className="w-4 h-4" />
                                            </Link>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="card p-0 overflow-x-auto">
                        <table className="min-w-full text-sm">
                            <thead className="bg-gray-50 text-gray-500">
                                <tr>
                                    <th className="text-left px-4 py-3 font-medium">Order</th>
                                    <th className="text-left px-4 py-3 font-medium">Customer</th>
                                    <th className="text-left px-4 py-3 font-medium">Date</th>
                                    <th className="text-left px-4 py-3 font-medium">Status</th>
                                    <th className="text-left px-4 py-3 font-medium">Total</th>
                                    <th className="text-right px-4 py-3 font-medium">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredOrders.map((order) => (
                                    <tr key={order._id} className="border-t">
                                        <td className="px-4 py-3 font-medium text-gray-900">{order.orderNumber}</td>
                                        <td className="px-4 py-3 text-gray-700">{order.customerId?.name || 'Unknown Customer'}</td>
                                        <td className="px-4 py-3 text-gray-700">{formatDate(order.createdAt)}</td>
                                        <td className="px-4 py-3">
                                            <div className="flex items-center gap-2">
                                                <span className={`badge ${getStatusColor(order.status)}`}>{order.status}</span>
                                                <span className={`badge ${getStatusColor(order.paymentStatus)}`}>{order.paymentStatus}</span>
                                            </div>
                                        </td>
                                        <td className="px-4 py-3 text-gray-700">{formatCurrency(order.total)}</td>
                                        <td className="px-4 py-3">
                                            <div className="flex items-center justify-end gap-2">
                                                {order.paymentStatus !== 'paid' && order.status !== 'cancelled' && (
                                                    <button
                                                        onClick={() => updatePaymentStatus(order._id, 'paid')}
                                                        className="btn-success py-2 px-3"
                                                        title="Mark as Paid"
                                                    >
                                                        <HiCash className="w-4 h-4" />
                                                    </button>
                                                )}
                                                <button
                                                    onClick={() => viewOrderDetails(order)}
                                                    className="btn-secondary py-2 px-3"
                                                >
                                                    <HiEye className="w-4 h-4" />
                                                </button>
                                                <Link
                                                    to={`/invoices?order=${order._id}`}
                                                    className="btn-secondary py-2 px-3"
                                                    title="View Invoice"
                                                >
                                                    <HiDocumentText className="w-4 h-4" />
                                                </Link>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )
            )}

            {/* Create Order Modal */}
            <Modal isOpen={showModal} onClose={closeModal} title="Create New Order" size="lg">
                <form onSubmit={handleSubmit} className="space-y-6">
                    {/* Customer Selection */}
                    <div>
                        <label className="label">Customer *</label>
                        <select
                            value={formData.customerId}
                            onChange={(e) => setFormData({ ...formData, customerId: e.target.value })}
                            className="input"
                            required
                        >
                            <option value="">Select a customer</option>
                            {customers.map((c) => (
                                <option key={c._id} value={c._id}>{c.name} {c.phone && `(${c.phone})`}</option>
                            ))}
                        </select>
                    </div>

                    {/* Add Products */}
                    <div>
                        <label className="label">Add Products</label>
                        <div className="flex gap-2">
                            <select
                                value={selectedProduct}
                                onChange={(e) => setSelectedProduct(e.target.value)}
                                className="input flex-1"
                            >
                                <option value="">Select product</option>
                                {products.filter(p => p.stock > 0).map((p) => (
                                    <option key={p._id} value={p._id}>
                                        {p.name} - {formatCurrency(p.sellingPrice)} ({p.stock} in stock)
                                    </option>
                                ))}
                            </select>
                            <input
                                type="number"
                                value={quantity}
                                onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                                className="input w-20"
                                min="1"
                            />
                            <button type="button" onClick={addItem} className="btn-secondary">
                                Add
                            </button>
                        </div>
                    </div>

                    {/* Order Items */}
                    {formData.items.length > 0 && (
                        <div className="bg-gray-50 rounded-xl p-4 space-y-3">
                            {formData.items.map((item, index) => (
                                <div key={index} className="flex items-center justify-between">
                                    <div>
                                        <span className="font-medium">{item.name}</span>
                                        <span className="text-gray-500 ml-2">× {item.quantity}</span>
                                    </div>
                                    <div className="flex items-center gap-3">
                                        <span>{formatCurrency(item.price * item.quantity)}</span>
                                        <button
                                            type="button"
                                            onClick={() => removeItem(index)}
                                            className="text-red-500 hover:text-red-700"
                                        >
                                            <HiX className="w-5 h-5" />
                                        </button>
                                    </div>
                                </div>
                            ))}

                            <div className="border-t pt-3 mt-3">
                                <div className="flex items-center justify-between mb-2">
                                    <label className="text-sm text-gray-600">Discount</label>
                                    <input
                                        type="number"
                                        value={formData.discount}
                                        onChange={(e) => setFormData({ ...formData, discount: e.target.value })}
                                        className="input w-32 text-right py-1"
                                        min="0"
                                    />
                                </div>
                                <div className="flex items-center justify-between font-bold text-lg">
                                    <span>Total</span>
                                    <span>{formatCurrency(calculateTotal())}</span>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Payment Method */}
                    <div>
                        <label className="label">Payment Method</label>
                        <select
                            value={formData.paymentMethod}
                            onChange={(e) => setFormData({ ...formData, paymentMethod: e.target.value })}
                            className="input"
                        >
                            <option value="cash">Cash</option>
                            <option value="upi">UPI</option>
                            <option value="card">Card</option>
                            <option value="bank">Bank Transfer</option>
                            <option value="other">Other</option>
                        </select>
                    </div>

                    {/* Notes */}
                    <div>
                        <label className="label">Notes</label>
                        <textarea
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                            className="input min-h-[60px]"
                            placeholder="Any special instructions..."
                        />
                    </div>

                    <div className="flex gap-3 pt-4">
                        <button type="button" onClick={closeModal} className="flex-1 btn-secondary">
                            Cancel
                        </button>
                        <button type="submit" className="flex-1 btn-primary">
                            Create Order
                        </button>
                    </div>
                </form>
            </Modal>

            {/* Order Detail Modal */}
            <Modal
                isOpen={showDetailModal}
                onClose={() => setShowDetailModal(false)}
                title={`Order ${selectedOrder?.orderNumber}`}
                size="lg"
            >
                {selectedOrder && (
                    <div className="space-y-6">
                        {/* Order Info */}
                        <div className="flex items-center justify-between">
                            <div>
                                <p className="text-sm text-gray-500">Customer</p>
                                <p className="font-medium">{selectedOrder.customerId?.name}</p>
                            </div>
                            <div className="flex gap-2">
                                <span className={`badge ${getStatusColor(selectedOrder.status)}`}>{selectedOrder.status}</span>
                                <span className={`badge ${getStatusColor(selectedOrder.paymentStatus)}`}>{selectedOrder.paymentStatus}</span>
                            </div>
                        </div>

                        {/* Items */}
                        <div className="bg-gray-50 rounded-xl p-4">
                            <h4 className="font-medium mb-3">Order Items</h4>
                            <div className="space-y-2">
                                {selectedOrder.items?.map((item, i) => (
                                    <div key={i} className="flex justify-between">
                                        <span>{item.name} × {item.quantity}</span>
                                        <span>{formatCurrency(item.total)}</span>
                                    </div>
                                ))}
                                <div className="border-t pt-2 mt-2 flex justify-between font-bold">
                                    <span>Total</span>
                                    <span>{formatCurrency(selectedOrder.total)}</span>
                                </div>
                            </div>
                        </div>

                        {/* Actions */}
                        <div className="flex gap-3">
                            {selectedOrder.paymentStatus !== 'paid' && selectedOrder.status !== 'cancelled' && (
                                <button
                                    onClick={() => updatePaymentStatus(selectedOrder._id, 'paid')}
                                    className="flex-1 btn-success"
                                >
                                    Mark as Paid
                                </button>
                            )}
                            {selectedOrder.status === 'pending' && (
                                <>
                                    <button
                                        onClick={() => updateOrderStatus(selectedOrder._id, 'confirmed')}
                                        className="flex-1 btn-primary"
                                    >
                                        Confirm Order
                                    </button>
                                    <button
                                        onClick={() => updateOrderStatus(selectedOrder._id, 'cancelled')}
                                        className="flex-1 btn-danger"
                                    >
                                        Cancel
                                    </button>
                                </>
                            )}
                            {selectedOrder.status === 'confirmed' && (
                                <button
                                    onClick={() => updateOrderStatus(selectedOrder._id, 'completed')}
                                    className="flex-1 btn-success"
                                >
                                    Mark Completed
                                </button>
                            )}
                        </div>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default Orders;
