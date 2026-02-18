import { useState, useEffect } from 'react';
import { customersAPI } from '../services/api';
import { formatCurrency, formatDate } from '../utils/helpers';
import Modal from '../components/Modal';
import {
    HiPlus,
    HiPencil,
    HiTrash,
    HiUsers,
    HiSearch,
    HiPhone,
    HiMail,
    HiStar,
    HiShoppingCart,
    HiViewGrid,
    HiViewList
} from 'react-icons/hi';

const Customers = () => {
    const [customers, setCustomers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [showDetailModal, setShowDetailModal] = useState(false);
    const [editingCustomer, setEditingCustomer] = useState(null);
    const [selectedCustomer, setSelectedCustomer] = useState(null);
    const [customerOrders, setCustomerOrders] = useState([]);
    const [searchQuery, setSearchQuery] = useState('');
    const viewStorageKey = 'admin-customers-view';
    const [viewMode, setViewMode] = useState(() => localStorage.getItem(viewStorageKey) || 'grid');
    const [formData, setFormData] = useState({
        name: '',
        phone: '',
        email: '',
        notes: '',
        address: { city: '', state: '' }
    });

    useEffect(() => {
        fetchCustomers();
    }, []);

    useEffect(() => {
        localStorage.setItem(viewStorageKey, viewMode);
    }, [viewMode]);

    const fetchCustomers = async () => {
        try {
            const { data } = await customersAPI.getAll();
            setCustomers(data);
        } catch (error) {
            console.error('Failed to fetch customers:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            if (editingCustomer) {
                await customersAPI.update(editingCustomer._id, formData);
            } else {
                await customersAPI.create(formData);
            }
            fetchCustomers();
            closeModal();
        } catch (error) {
            console.error('Failed to save customer:', error);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this customer?')) {
            try {
                await customersAPI.delete(id);
                fetchCustomers();
            } catch (error) {
                console.error('Failed to delete customer:', error);
            }
        }
    };

    const viewCustomerDetails = async (customer) => {
        try {
            const { data } = await customersAPI.getOne(customer._id);
            setSelectedCustomer(data.customer);
            setCustomerOrders(data.orders || []);
            setShowDetailModal(true);
        } catch (error) {
            console.error('Failed to fetch customer details:', error);
        }
    };

    const openEditModal = (customer) => {
        setEditingCustomer(customer);
        setFormData({
            name: customer.name,
            phone: customer.phone || '',
            email: customer.email || '',
            notes: customer.notes || '',
            address: customer.address || { city: '', state: '' }
        });
        setShowModal(true);
    };

    const closeModal = () => {
        setShowModal(false);
        setEditingCustomer(null);
        setFormData({ name: '', phone: '', email: '', notes: '', address: { city: '', state: '' } });
    };

    const filteredCustomers = customers.filter(c =>
        c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        c.phone?.includes(searchQuery) ||
        c.email?.toLowerCase().includes(searchQuery.toLowerCase())
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
                        <h1 className="text-2xl font-bold text-gray-900">Customers</h1>
                        <p className="text-gray-600">{customers.length} customers • {customers.filter(c => c.isRepeatCustomer).length} repeat customers</p>
                    </div>
                    <div className="flex items-center bg-gray-100 rounded-xl p-1 w-fit">
                        <button
                            onClick={() => setViewMode('grid')}
                            className={`p-2 rounded-lg transition-colors ${viewMode === 'grid'
                                ? 'bg-white text-primary-600 shadow'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                            title="Grid view"
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
                <div className="flex flex-col sm:flex-row sm:flex-wrap gap-3 w-full">
                    <div className="relative w-full sm:w-64">
                        <HiSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search customers..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="input pl-10 w-full"
                        />
                    </div>
                    <button onClick={() => setShowModal(true)} className="btn-primary flex items-center justify-center gap-2 w-full sm:w-auto">
                        <HiPlus className="w-5 h-5" />
                        Add Customer
                    </button>
                </div>
            </div>

            {/* Customers Grid */}
            {filteredCustomers.length === 0 ? (
                <div className="card text-center py-12">
                    <HiUsers className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No customers yet</h3>
                    <p className="text-gray-500 mb-4">Start by adding your first customer</p>
                    <button onClick={() => setShowModal(true)} className="btn-primary">
                        Add Customer
                    </button>
                </div>
            ) : (
                viewMode === 'grid' ? (
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filteredCustomers.map((customer) => (
                            <div key={customer._id} className="card hover:shadow-card-hover">
                                <div className="flex items-start justify-between mb-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-12 h-12 bg-purple-100 rounded-full flex items-center justify-center">
                                            <span className="text-purple-600 font-semibold text-lg">
                                                {customer.name.charAt(0).toUpperCase()}
                                            </span>
                                        </div>
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <h3 className="font-semibold text-gray-900">{customer.name}</h3>
                                                {customer.isRepeatCustomer && (
                                                    <HiStar className="w-4 h-4 text-yellow-500" title="Repeat Customer" />
                                                )}
                                            </div>
                                            {customer.address?.city && (
                                                <p className="text-sm text-gray-500">{customer.address.city}</p>
                                            )}
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-2 mb-4">
                                    {customer.phone && (
                                        <div className="flex items-center gap-2 text-sm text-gray-600">
                                            <HiPhone className="w-4 h-4" />
                                            <span>{customer.phone}</span>
                                        </div>
                                    )}
                                    {customer.email && (
                                        <div className="flex items-center gap-2 text-sm text-gray-600 min-w-0">
                                            <HiMail className="w-4 h-4" />
                                            <span className="truncate flex-1">{customer.email}</span>
                                        </div>
                                    )}
                                </div>

                                <div className="grid grid-cols-2 gap-4 p-3 bg-gray-50 rounded-xl mb-4">
                                    <div className="text-center">
                                        <p className="text-xs text-gray-500 uppercase">Orders</p>
                                        <p className="text-lg font-bold text-gray-900">{customer.orderCount || 0}</p>
                                    </div>
                                    <div className="text-center">
                                        <p className="text-xs text-gray-500 uppercase">Total Spent</p>
                                        <p className="text-lg font-bold text-gray-900">{formatCurrency(customer.totalSpent || 0)}</p>
                                    </div>
                                </div>

                                <div className="flex items-center gap-2">
                                    <button
                                        onClick={() => viewCustomerDetails(customer)}
                                        className="flex-1 btn-secondary py-2 flex items-center justify-center gap-2"
                                    >
                                        <HiShoppingCart className="w-4 h-4" />
                                        View Orders
                                    </button>
                                    <button
                                        onClick={() => openEditModal(customer)}
                                        className="p-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-colors"
                                    >
                                        <HiPencil className="w-5 h-5" />
                                    </button>
                                    <button
                                        onClick={() => handleDelete(customer._id)}
                                        className="p-2 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors"
                                    >
                                        <HiTrash className="w-5 h-5" />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                ) : (
                    <div className="card p-0 overflow-x-auto">
                        <table className="min-w-full text-sm">
                            <thead className="bg-gray-50 text-gray-500">
                                <tr>
                                    <th className="text-left px-4 py-3 font-medium">Customer</th>
                                    <th className="text-left px-4 py-3 font-medium">Contact</th>
                                    <th className="text-left px-4 py-3 font-medium">Orders</th>
                                    <th className="text-left px-4 py-3 font-medium">Total Spent</th>
                                    <th className="text-right px-4 py-3 font-medium">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredCustomers.map((customer) => (
                                    <tr key={customer._id} className="border-t">
                                        <td className="px-4 py-3">
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center">
                                                    <span className="text-purple-600 font-semibold">
                                                        {customer.name.charAt(0).toUpperCase()}
                                                    </span>
                                                </div>
                                                <div>
                                                    <div className="flex items-center gap-2">
                                                        <p className="font-medium text-gray-900">{customer.name}</p>
                                                        {customer.isRepeatCustomer && (
                                                            <HiStar className="w-4 h-4 text-yellow-500" title="Repeat Customer" />
                                                        )}
                                                    </div>
                                                    {customer.address?.city && (
                                                        <p className="text-xs text-gray-500">{customer.address.city}</p>
                                                    )}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-4 py-3 text-gray-700">
                                            <div className="space-y-1">
                                                {customer.phone && (
                                                    <div className="flex items-center gap-2">
                                                        <HiPhone className="w-4 h-4" />
                                                        <span>{customer.phone}</span>
                                                    </div>
                                                )}
                                                {customer.email && (
                                                    <div className="flex items-center gap-2">
                                                        <HiMail className="w-4 h-4" />
                                                        <span>{customer.email}</span>
                                                    </div>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-4 py-3 text-gray-700">{customer.orderCount || 0}</td>
                                        <td className="px-4 py-3 text-gray-700">{formatCurrency(customer.totalSpent || 0)}</td>
                                        <td className="px-4 py-3">
                                            <div className="flex items-center justify-end gap-2">
                                                <button
                                                    onClick={() => viewCustomerDetails(customer)}
                                                    className="btn-secondary py-2 px-3"
                                                >
                                                    <HiShoppingCart className="w-4 h-4" />
                                                </button>
                                                <button
                                                    onClick={() => openEditModal(customer)}
                                                    className="p-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-colors"
                                                >
                                                    <HiPencil className="w-5 h-5" />
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(customer._id)}
                                                    className="p-2 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors"
                                                >
                                                    <HiTrash className="w-5 h-5" />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )
            )}

            {/* Add/Edit Modal */}
            <Modal
                isOpen={showModal}
                onClose={closeModal}
                title={editingCustomer ? 'Edit Customer' : 'Add New Customer'}
            >
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="label">Name *</label>
                        <input
                            type="text"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            className="input"
                            placeholder="Customer name"
                            required
                        />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="label">Phone</label>
                            <input
                                type="tel"
                                value={formData.phone}
                                onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                                className="input"
                                placeholder="+91 98765 43210"
                            />
                        </div>
                        <div>
                            <label className="label">Email</label>
                            <input
                                type="email"
                                value={formData.email}
                                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                                className="input"
                                placeholder="customer@email.com"
                            />
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="label">City</label>
                            <input
                                type="text"
                                value={formData.address.city}
                                onChange={(e) => setFormData({ ...formData, address: { ...formData.address, city: e.target.value } })}
                                className="input"
                                placeholder="City"
                            />
                        </div>
                        <div>
                            <label className="label">State</label>
                            <input
                                type="text"
                                value={formData.address.state}
                                onChange={(e) => setFormData({ ...formData, address: { ...formData.address, state: e.target.value } })}
                                className="input"
                                placeholder="State"
                            />
                        </div>
                    </div>
                    <div>
                        <label className="label">Notes</label>
                        <textarea
                            value={formData.notes}
                            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                            className="input min-h-[80px]"
                            placeholder="Any notes about this customer..."
                        />
                    </div>
                    <div className="flex gap-3 pt-4">
                        <button type="button" onClick={closeModal} className="flex-1 btn-secondary">
                            Cancel
                        </button>
                        <button type="submit" className="flex-1 btn-primary">
                            {editingCustomer ? 'Update Customer' : 'Add Customer'}
                        </button>
                    </div>
                </form>
            </Modal>

            {/* Customer Orders Detail Modal */}
            <Modal
                isOpen={showDetailModal}
                onClose={() => setShowDetailModal(false)}
                title={`${selectedCustomer?.name}'s Orders`}
                size="lg"
            >
                {customerOrders.length === 0 ? (
                    <div className="text-center py-8">
                        <HiShoppingCart className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                        <p className="text-gray-500">No orders yet</p>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {customerOrders.map((order) => (
                            <div key={order._id} className="p-4 bg-gray-50 rounded-xl">
                                <div className="flex items-center justify-between mb-2">
                                    <span className="font-medium">{order.orderNumber}</span>
                                    <span className={`badge ${order.paymentStatus === 'paid' ? 'badge-success' : 'badge-warning'}`}>
                                        {order.paymentStatus}
                                    </span>
                                </div>
                                <div className="flex items-center justify-between text-sm text-gray-500">
                                    <span>{formatDate(order.createdAt)}</span>
                                    <span className="font-medium text-gray-900">{formatCurrency(order.total)}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default Customers;
