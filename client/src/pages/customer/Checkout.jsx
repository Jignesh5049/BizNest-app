import { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useCart } from '../../components/customer/CustomerLayout';
import { storeAPI } from '../../services/api';
import {
    HiLocationMarker,
    HiPlus,
    HiCheck,
    HiCreditCard,
    HiCash,
    HiDeviceMobile
} from 'react-icons/hi';

const paymentMethods = [
    { id: 'cash', label: 'Cash on Delivery', icon: HiCash, description: 'Pay when you receive' },
    { id: 'upi', label: 'UPI Payment', icon: HiDeviceMobile, description: 'GPay, PhonePe, Paytm' },
    { id: 'card', label: 'Card Payment', icon: HiCreditCard, description: 'Credit/Debit Card' },
];

const Checkout = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { cart, cartTotal, clearCart } = useCart();
    const [addresses, setAddresses] = useState([]);
    const [selectedAddress, setSelectedAddress] = useState(null);
    const [paymentMethod, setPaymentMethod] = useState('cash');
    const [loading, setLoading] = useState(false);
    const [showAddressForm, setShowAddressForm] = useState(false);
    const [newAddress, setNewAddress] = useState({
        label: 'Home',
        street: '',
        city: '',
        state: '',
        pincode: '',
        isDefault: false
    });

    const deliveryNotes = location.state?.deliveryNotes || '';

    useEffect(() => {
        if (cart.length === 0) {
            navigate('/store/cart');
            return;
        }
        fetchAddresses();
    }, []);

    const fetchAddresses = async () => {
        try {
            const { data } = await storeAPI.getAddresses();
            setAddresses(data);
            const defaultAddr = data.find(a => a.isDefault) || data[0];
            if (defaultAddr) {
                setSelectedAddress(defaultAddr._id);
            }
        } catch (error) {
            console.error('Failed to fetch addresses:', error);
        }
    };

    const handleAddAddress = async (e) => {
        e.preventDefault();
        try {
            const { data } = await storeAPI.addAddress(newAddress);
            setAddresses(data);
            const newest = data[data.length - 1];
            setSelectedAddress(newest._id);
            setShowAddressForm(false);
            setNewAddress({
                label: 'Home',
                street: '',
                city: '',
                state: '',
                pincode: '',
                isDefault: false
            });
        } catch (error) {
            console.error('Failed to add address:', error);
        }
    };

    const handlePlaceOrder = async () => {
        if (!selectedAddress && addresses.length > 0) {
            alert('Please select a delivery address');
            return;
        }

        setLoading(true);
        try {
            // Group cart items by business and create separate orders
            const groupedCart = cart.reduce((acc, item) => {
                if (!acc[item.businessId]) {
                    acc[item.businessId] = [];
                }
                acc[item.businessId].push(item);
                return acc;
            }, {});

            const selectedAddr = addresses.find(a => a._id === selectedAddress);
            const deliveryAddress = selectedAddr ? {
                street: selectedAddr.street,
                city: selectedAddr.city,
                state: selectedAddr.state,
                pincode: selectedAddr.pincode
            } : {};

            // Create orders for each business
            for (const [businessId, items] of Object.entries(groupedCart)) {
                await storeAPI.createOrder({
                    businessId,
                    items: items.map(item => ({
                        productId: item.productId,
                        quantity: item.quantity
                    })),
                    deliveryAddress,
                    notes: deliveryNotes,
                    paymentMethod
                });
            }

            clearCart();
            navigate('/store/orders', {
                state: { orderPlaced: true }
            });
        } catch (error) {
            console.error('Failed to place order:', error);
            alert(error.response?.data?.message || 'Failed to place order');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="max-w-4xl mx-auto">
            <h1 className="text-2xl font-bold text-gray-800 mb-6">Checkout</h1>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 space-y-6">
                    {/* Delivery Address */}
                    <div className="card">
                        <div className="flex items-center justify-between mb-4">
                            <h3 className="font-semibold text-gray-800 flex items-center gap-2">
                                <HiLocationMarker className="w-5 h-5 text-primary-600" />
                                Delivery Address
                            </h3>
                            <button
                                onClick={() => setShowAddressForm(!showAddressForm)}
                                className="text-primary-600 hover:text-primary-700 text-sm font-medium flex items-center gap-1"
                            >
                                <HiPlus className="w-4 h-4" />
                                Add New
                            </button>
                        </div>

                        {/* Address Form */}
                        {showAddressForm && (
                            <form onSubmit={handleAddAddress} className="bg-gray-50 rounded-xl p-4 mb-4 space-y-3">
                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="label">Label</label>
                                        <select
                                            value={newAddress.label}
                                            onChange={(e) => setNewAddress({ ...newAddress, label: e.target.value })}
                                            className="input"
                                        >
                                            <option value="Home">Home</option>
                                            <option value="Work">Work</option>
                                            <option value="Other">Other</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className="label">Pincode</label>
                                        <input
                                            type="text"
                                            value={newAddress.pincode}
                                            onChange={(e) => setNewAddress({ ...newAddress, pincode: e.target.value })}
                                            className="input"
                                            required
                                        />
                                    </div>
                                </div>
                                <div>
                                    <label className="label">Street Address</label>
                                    <input
                                        type="text"
                                        value={newAddress.street}
                                        onChange={(e) => setNewAddress({ ...newAddress, street: e.target.value })}
                                        className="input"
                                        required
                                    />
                                </div>
                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="label">City</label>
                                        <input
                                            type="text"
                                            value={newAddress.city}
                                            onChange={(e) => setNewAddress({ ...newAddress, city: e.target.value })}
                                            className="input"
                                            required
                                        />
                                    </div>
                                    <div>
                                        <label className="label">State</label>
                                        <input
                                            type="text"
                                            value={newAddress.state}
                                            onChange={(e) => setNewAddress({ ...newAddress, state: e.target.value })}
                                            className="input"
                                            required
                                        />
                                    </div>
                                </div>
                                <div className="flex gap-3">
                                    <button type="submit" className="btn-primary py-2">
                                        Save Address
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => setShowAddressForm(false)}
                                        className="btn-secondary py-2"
                                    >
                                        Cancel
                                    </button>
                                </div>
                            </form>
                        )}

                        {/* Address List */}
                        {addresses.length === 0 && !showAddressForm ? (
                            <p className="text-gray-500 text-center py-4">
                                No saved addresses. Add one to continue.
                            </p>
                        ) : (
                            <div className="space-y-3">
                                {addresses.map(address => (
                                    <label
                                        key={address._id}
                                        className={`flex items-start gap-3 p-4 rounded-xl border-2 cursor-pointer transition-colors ${selectedAddress === address._id
                                                ? 'border-primary-500 bg-primary-50'
                                                : 'border-gray-200 hover:border-gray-300'
                                            }`}
                                    >
                                        <input
                                            type="radio"
                                            name="address"
                                            value={address._id}
                                            checked={selectedAddress === address._id}
                                            onChange={() => setSelectedAddress(address._id)}
                                            className="mt-1"
                                        />
                                        <div className="flex-1">
                                            <div className="flex items-center gap-2 mb-1">
                                                <span className="font-semibold text-gray-800">{address.label}</span>
                                                {address.isDefault && (
                                                    <span className="text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full">
                                                        Default
                                                    </span>
                                                )}
                                            </div>
                                            <p className="text-gray-600 text-sm">
                                                {[address.street, address.city, address.state, address.pincode]
                                                    .filter(Boolean).join(', ')}
                                            </p>
                                        </div>
                                    </label>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Payment Method */}
                    <div className="card">
                        <h3 className="font-semibold text-gray-800 mb-4 flex items-center gap-2">
                            <HiCreditCard className="w-5 h-5 text-primary-600" />
                            Payment Method
                        </h3>
                        <div className="space-y-3">
                            {paymentMethods.map(method => (
                                <label
                                    key={method.id}
                                    className={`flex items-center gap-4 p-4 rounded-xl border-2 cursor-pointer transition-colors ${paymentMethod === method.id
                                            ? 'border-primary-500 bg-primary-50'
                                            : 'border-gray-200 hover:border-gray-300'
                                        }`}
                                >
                                    <input
                                        type="radio"
                                        name="payment"
                                        value={method.id}
                                        checked={paymentMethod === method.id}
                                        onChange={() => setPaymentMethod(method.id)}
                                    />
                                    <method.icon className="w-6 h-6 text-gray-600" />
                                    <div>
                                        <p className="font-medium text-gray-800">{method.label}</p>
                                        <p className="text-sm text-gray-500">{method.description}</p>
                                    </div>
                                </label>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Order Summary */}
                <div className="lg:col-span-1">
                    <div className="card sticky top-24">
                        <h3 className="font-semibold text-gray-800 mb-4">Order Summary</h3>

                        {/* Items */}
                        <div className="max-h-48 overflow-y-auto mb-4 space-y-3">
                            {cart.map(item => (
                                <div key={item.productId} className="flex gap-3">
                                    <div className="w-12 h-12 bg-gray-100 rounded-lg overflow-hidden flex-shrink-0">
                                        {item.image ? (
                                            <img src={item.image} alt="" className="w-full h-full object-cover" />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center text-gray-400 text-sm">📦</div>
                                        )}
                                    </div>
                                    <div className="flex-1 min-w-0">
                                        <p className="text-sm font-medium text-gray-800 truncate">{item.name}</p>
                                        <p className="text-sm text-gray-500">Qty: {item.quantity}</p>
                                    </div>
                                    <p className="text-sm font-medium text-gray-800">
                                        ₹{(item.price * item.quantity).toLocaleString()}
                                    </p>
                                </div>
                            ))}
                        </div>

                        <div className="border-t pt-4 space-y-2 mb-4">
                            <div className="flex justify-between text-gray-600">
                                <span>Subtotal</span>
                                <span>₹{cartTotal.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between text-gray-600">
                                <span>Delivery</span>
                                <span className="text-green-600">Free</span>
                            </div>
                        </div>

                        <div className="border-t pt-4 mb-6">
                            <div className="flex justify-between text-lg font-bold">
                                <span>Total</span>
                                <span className="text-primary-600">₹{cartTotal.toLocaleString()}</span>
                            </div>
                        </div>

                        <button
                            onClick={handlePlaceOrder}
                            disabled={loading || (addresses.length === 0)}
                            className="btn-primary w-full py-3 flex items-center justify-center gap-2 disabled:opacity-50"
                        >
                            {loading ? (
                                'Placing Order...'
                            ) : (
                                <>
                                    <HiCheck className="w-5 h-5" />
                                    Place Order
                                </>
                            )}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Checkout;
