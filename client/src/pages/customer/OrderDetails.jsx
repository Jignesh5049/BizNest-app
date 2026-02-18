import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import {
    HiArrowLeft,
    HiLocationMarker,
    HiCheck,
    HiX,
    HiRefresh,
    HiCube,
    HiShoppingCart,
    HiChatAlt2,
    HiStar
} from 'react-icons/hi';
import { FaWhatsapp } from 'react-icons/fa';

const statusConfig = {
    pending: { label: 'Pending', color: 'text-yellow-600 bg-yellow-100', step: 1 },
    confirmed: { label: 'Confirmed', color: 'text-blue-600 bg-blue-100', step: 2 },
    completed: { label: 'Completed', color: 'text-green-600 bg-green-100', step: 3 },
    cancelled: { label: 'Cancelled', color: 'text-red-600 bg-red-100', step: 0 }
};

const paymentStatusConfig = {
    unpaid: { label: 'Unpaid', color: 'bg-red-100 text-red-700' },
    partial: { label: 'Partial', color: 'bg-yellow-100 text-yellow-700' },
    paid: { label: 'Paid', color: 'bg-green-100 text-green-700' }
};

const OrderDetails = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [order, setOrder] = useState(null);
    const [loading, setLoading] = useState(true);
    const [cancelling, setCancelling] = useState(false);
    const [supportSending, setSupportSending] = useState(false);
    const [supportMessage, setSupportMessage] = useState('');
    const [supportForm, setSupportForm] = useState({
        issueType: 'complaint',
        productId: '',
        message: ''
    });
    const [reviewEligibility, setReviewEligibility] = useState({});
    const [reviewDrafts, setReviewDrafts] = useState({});
    const [reviewMessages, setReviewMessages] = useState({});
    const { addItemsForReorder } = useCart();

    useEffect(() => {
        fetchOrder();
    }, [id]);

    useEffect(() => {
        if (order?.status === 'completed') {
            const drafts = {};
            order.items?.forEach(item => {
                drafts[item.productId] = { rating: 0, comment: '' };
            });
            setReviewDrafts(drafts);
            fetchReviewEligibility(order.items || []);
        }
    }, [order?.status]);

    const fetchOrder = async () => {
        try {
            const { data } = await storeAPI.getOrder(id);
            setOrder(data);
        } catch (error) {
            console.error('Failed to fetch order:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleCancel = async () => {
        if (!window.confirm('Are you sure you want to cancel this order?')) return;

        setCancelling(true);
        try {
            await storeAPI.cancelOrder(id);
            fetchOrder();
        } catch (error) {
            alert(error.response?.data?.message || 'Failed to cancel order');
        } finally {
            setCancelling(false);
        }
    };

    const handleReorder = () => {
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

    const fetchReviewEligibility = async (items) => {
        try {
            const results = await Promise.all(items.map(item =>
                storeAPI.getReviewEligibility(item.productId)
                    .then(({ data }) => ({ productId: item.productId, data }))
                    .catch(() => ({ productId: item.productId, data: { canReview: false, reason: 'Unavailable' } }))
            ));

            const eligibilityMap = {};
            results.forEach(result => {
                eligibilityMap[result.productId] = result.data;
            });
            setReviewEligibility(eligibilityMap);
        } catch (error) {
            console.error('Failed to fetch review eligibility:', error);
        }
    };

    const handleReviewSubmit = async (productId) => {
        const draft = reviewDrafts[productId] || { rating: 0, comment: '' };
        if (!draft.rating) {
            setReviewMessages(prev => ({ ...prev, [productId]: 'Please select a rating.' }));
            return;
        }

        try {
            await storeAPI.createReview(productId, {
                rating: draft.rating,
                comment: draft.comment
            });
            setReviewMessages(prev => ({ ...prev, [productId]: 'Thanks for your rating!' }));
            setReviewEligibility(prev => ({
                ...prev,
                [productId]: { canReview: false, reason: 'Already reviewed' }
            }));
        } catch (error) {
            setReviewMessages(prev => ({
                ...prev,
                [productId]: error.response?.data?.message || 'Failed to submit rating'
            }));
        }
    };

    const handleSupportSubmit = async (e) => {
        e.preventDefault();
        setSupportMessage('');

        if (!supportForm.message.trim()) {
            setSupportMessage('Please describe the issue.');
            return;
        }

        setSupportSending(true);
        try {
            await storeAPI.createSupportTicket({
                type: 'support',
                orderId: order._id,
                issueType: supportForm.issueType,
                productId: supportForm.productId || undefined,
                subject: `Order ${order.orderNumber} - ${supportForm.issueType}`,
                message: supportForm.message
            });
            setSupportMessage('Your request has been submitted.');
            setSupportForm({ issueType: 'complaint', productId: '', message: '' });
        } catch (error) {
            setSupportMessage(error.response?.data?.message || 'Failed to submit request');
        } finally {
            setSupportSending(false);
        }
    };

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center py-16">
                <div className="w-12 h-12 border-4 border-primary-200 rounded-full animate-spin border-t-primary-600"></div>
                <p className="mt-4 text-gray-500">Loading order details...</p>
            </div>
        );
    }

    if (!order) {
        return (
            <div className="text-center py-12">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Order Not Found</h3>
                <Link to="/store/orders" className="text-primary-600 hover:underline">Go back to orders</Link>
            </div>
        );
    }

    const status = statusConfig[order.status] || statusConfig.pending;
    const paymentStatus = paymentStatusConfig[order.paymentStatus] || paymentStatusConfig.unpaid;

    return (
        <div className="max-w-3xl mx-auto">
            {/* Back Button */}
            <Link to="/store/orders" className="inline-flex items-center gap-2 text-gray-600 hover:text-primary-600 transition-colors mb-6">
                <HiArrowLeft className="w-5 h-5" />
                Back to Orders
            </Link>

            {/* Order Header */}
            <div className="card mb-6">
                <div className="flex flex-col sm:flex-row justify-between gap-4 mb-6">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-1">
                            Order #{order.orderNumber}
                        </h1>
                        <p className="text-gray-500">
                            Placed on {new Date(order.createdAt).toLocaleDateString('en-IN', {
                                day: 'numeric',
                                month: 'long',
                                year: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                            })}
                        </p>
                    </div>
                    <div className="flex gap-2">
                        <span className={`px-4 py-2 rounded-xl text-sm font-medium ${status.color}`}>
                            {status.label}
                        </span>
                        <span className={`px-4 py-2 rounded-xl text-sm font-medium ${paymentStatus.color}`}>
                            {paymentStatus.label}
                        </span>
                    </div>
                </div>

                {/* Order Timeline */}
                {order.status !== 'cancelled' && (
                    <div className="mb-6">
                        <div className="flex justify-between items-center">
                            {['Pending', 'Confirmed', 'Completed'].map((step, index) => (
                                <div key={step} className="flex flex-col items-center flex-1">
                                    <div className={`w-10 h-10 rounded-full flex items-center justify-center ${status.step > index
                                        ? 'bg-green-500 text-white'
                                        : status.step === index + 1
                                            ? 'bg-primary-500 text-white'
                                            : 'bg-gray-200 text-gray-500'
                                        }`}>
                                        {status.step > index ? (
                                            <HiCheck className="w-5 h-5" />
                                        ) : (
                                            <span className="text-sm font-medium">{index + 1}</span>
                                        )}
                                    </div>
                                    <span className="text-xs text-gray-500 mt-2">{step}</span>
                                </div>
                            ))}
                        </div>
                        <div className="flex mt-2">
                            <div className={`flex-1 h-1 ${status.step >= 2 ? 'bg-green-500' : 'bg-gray-200'}`} />
                            <div className={`flex-1 h-1 ${status.step >= 3 ? 'bg-green-500' : 'bg-gray-200'}`} />
                        </div>
                    </div>
                )}

                {/* Business Info */}
                {order.businessId && (
                    <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                        <div className="flex items-center gap-3">
                            <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
                                {order.businessId.logo ? (
                                    <img src={order.businessId.logo} alt="" className="w-10 h-10 rounded-lg object-cover" />
                                ) : (
                                    <span className="text-lg font-bold text-primary-600">
                                        {order.businessId.name?.charAt(0)}
                                    </span>
                                )}
                            </div>
                            <div>
                                <p className="font-semibold text-gray-800">{order.businessId.name}</p>
                                {order.businessId.contact?.phone && (
                                    <p className="text-sm text-gray-500">{order.businessId.contact.phone}</p>
                                )}
                            </div>
                        </div>
                        {order.businessId.contact?.whatsapp && (
                            <a
                                href={`https://wa.me/${order.businessId.contact.whatsapp.replace(/\D/g, '')}?text=Hi! I have a question about my order ${order.orderNumber}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-2 px-4 py-2 bg-green-500 text-white rounded-xl hover:bg-green-600 transition-colors"
                            >
                                <FaWhatsapp className="w-5 h-5" />
                                Contact
                            </a>
                        )}
                    </div>
                )}
            </div>

            {/* Order Items */}
            <div className="card mb-6">
                <h3 className="font-semibold text-gray-800 mb-4">Order Items</h3>
                <div className="space-y-4">
                    {order.items?.map((item, index) => (
                        <div key={index} className="flex items-center gap-4 py-3 border-b last:border-b-0">
                            <div className="w-16 h-16 bg-gray-100 rounded-xl flex items-center justify-center">
                                {item.image ? (
                                    <img src={item.image} alt={item.name} className="w-full h-full object-cover rounded-xl" />
                                ) : (
                                    <HiCube className="w-8 h-8 text-gray-300" />
                                )}
                            </div>
                            <div className="flex-1">
                                <p className="font-medium text-gray-800">{item.name}</p>
                                <p className="text-sm text-gray-500">
                                    Qty: {item.quantity} × ₹{item.price?.toLocaleString()}
                                </p>
                            </div>
                            <p className="font-semibold text-gray-800">
                                ₹{item.total?.toLocaleString()}
                            </p>
                        </div>
                    ))}
                </div>

                {/* Order Summary */}
                <div className="border-t mt-4 pt-4 space-y-2">
                    <div className="flex justify-between text-gray-600">
                        <span>Subtotal</span>
                        <span>₹{order.subtotal?.toLocaleString()}</span>
                    </div>
                    {order.discount > 0 && (
                        <div className="flex justify-between text-green-600">
                            <span>Discount</span>
                            <span>-₹{order.discount?.toLocaleString()}</span>
                        </div>
                    )}
                    <div className="flex justify-between text-gray-600">
                        <span>Delivery</span>
                        <span className="text-green-600">Free</span>
                    </div>
                    <div className="flex justify-between text-lg font-bold pt-2 border-t">
                        <span>Total</span>
                        <span className="text-primary-600">₹{order.total?.toLocaleString()}</span>
                    </div>
                </div>
            </div>

            {/* Delivery Address */}
            {order.deliveryAddress && (
                <div className="card mb-6">
                    <h3 className="font-semibold text-gray-800 mb-3 flex items-center gap-2">
                        <HiLocationMarker className="w-5 h-5 text-primary-600" />
                        Delivery Address
                    </h3>
                    <p className="text-gray-600">
                        {[order.deliveryAddress.street, order.deliveryAddress.city,
                        order.deliveryAddress.state, order.deliveryAddress.pincode]
                            .filter(Boolean).join(', ')}
                    </p>
                </div>
            )}

            {/* Notes */}
            {order.notes && (
                <div className="card mb-6">
                    <h3 className="font-semibold text-gray-800 mb-3">Delivery Notes</h3>
                    <p className="text-gray-600">{order.notes}</p>
                </div>
            )}

            {/* Rate Items */}
            {order.status === 'completed' && (
                <div className="card mb-6">
                    <h3 className="font-semibold text-gray-800 mb-4">Rate your items</h3>
                    <div className="space-y-4">
                        {order.items?.map((item) => {
                            const eligibility = reviewEligibility[item.productId];
                            const draft = reviewDrafts[item.productId] || { rating: 0, comment: '' };
                            const message = reviewMessages[item.productId];
                            const canReview = eligibility?.canReview;

                            return (
                                <div key={item.productId} className="p-4 bg-gray-50 rounded-xl">
                                    <div className="flex items-center justify-between mb-3">
                                        <div>
                                            <p className="font-semibold text-gray-800">{item.name}</p>
                                            <p className="text-xs text-gray-500">Qty: {item.quantity}</p>
                                        </div>
                                        {canReview === false && (
                                            <span className="text-xs text-gray-500">
                                                {eligibility?.reason === 'Already reviewed'
                                                    ? 'Already rated'
                                                    : 'Not eligible'}
                                            </span>
                                        )}
                                    </div>

                                    {canReview ? (
                                        <div className="space-y-3">
                                            <div className="flex items-center gap-2">
                                                {[1, 2, 3, 4, 5].map((star) => (
                                                    <button
                                                        key={star}
                                                        type="button"
                                                        onClick={() => setReviewDrafts(prev => ({
                                                            ...prev,
                                                            [item.productId]: { ...draft, rating: star }
                                                        }))}
                                                        className="p-1"
                                                    >
                                                        <HiStar className={`w-6 h-6 ${draft.rating >= star ? 'text-yellow-400' : 'text-gray-300'}`} />
                                                    </button>
                                                ))}
                                            </div>
                                            <textarea
                                                value={draft.comment}
                                                onChange={(e) => setReviewDrafts(prev => ({
                                                    ...prev,
                                                    [item.productId]: { ...draft, comment: e.target.value }
                                                }))}
                                                className="input min-h-[100px]"
                                                placeholder="Share your experience..."
                                                maxLength={1000}
                                            />
                                            {message && (
                                                <div className={`text-sm ${message.includes('Thanks') ? 'text-green-600' : 'text-red-600'}`}>
                                                    {message}
                                                </div>
                                            )}
                                            <button
                                                type="button"
                                                onClick={() => handleReviewSubmit(item.productId)}
                                                className="btn-primary"
                                            >
                                                Submit Rating
                                            </button>
                                        </div>
                                    ) : (
                                        message && (
                                            <div className={`text-sm ${message.includes('Thanks') ? 'text-green-600' : 'text-red-600'}`}>
                                                {message}
                                            </div>
                                        )
                                    )}
                                </div>
                            );
                        })}
                    </div>
                </div>
            )}

            {/* Support / Return / Replace */}
            {order.status === 'completed' && (
                <div className="card mb-6">
                    <div className="flex items-center gap-2 mb-4">
                        <HiChatAlt2 className="w-5 h-5 text-primary-600" />
                        <h3 className="font-semibold text-gray-800">Need help with this order?</h3>
                    </div>
                    <p className="text-sm text-gray-600 mb-4">
                        Report a damaged item, request a return or replacement, or report a wrong item.
                    </p>
                    <form onSubmit={handleSupportSubmit} className="space-y-4">
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div>
                                <label className="label">Issue Type</label>
                                <select
                                    value={supportForm.issueType}
                                    onChange={(e) => setSupportForm({ ...supportForm, issueType: e.target.value })}
                                    className="input"
                                >
                                    <option value="return">Return</option>
                                    <option value="replace">Replace</option>
                                    <option value="damaged">Damaged item</option>
                                    <option value="wrong_item">Wrong item delivered</option>
                                    <option value="complaint">Other complaint</option>
                                </select>
                            </div>
                            <div>
                                <label className="label">Product (optional)</label>
                                <select
                                    value={supportForm.productId}
                                    onChange={(e) => setSupportForm({ ...supportForm, productId: e.target.value })}
                                    className="input"
                                >
                                    <option value="">All items in this order</option>
                                    {order.items?.map((item) => (
                                        <option key={item.productId} value={item.productId}>
                                            {item.name}
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>
                        <div>
                            <label className="label">Details *</label>
                            <textarea
                                value={supportForm.message}
                                onChange={(e) => setSupportForm({ ...supportForm, message: e.target.value })}
                                className="input min-h-[120px]"
                                placeholder="Explain the issue and what you want (return, replace, refund, etc.)"
                                required
                            />
                        </div>
                        {supportMessage && (
                            <div className={`text-sm ${supportMessage.includes('submitted') ? 'text-green-600' : 'text-red-600'}`}>
                                {supportMessage}
                            </div>
                        )}
                        <button type="submit" className="btn-primary" disabled={supportSending}>
                            {supportSending ? 'Submitting...' : 'Submit Request'}
                        </button>
                    </form>
                </div>
            )}

            {/* Actions */}
            <div className="flex gap-3">
                {order.status === 'pending' && (
                    <button
                        onClick={handleCancel}
                        disabled={cancelling}
                        className="btn-danger py-3 px-6 flex items-center gap-2"
                    >
                        <HiX className="w-5 h-5" />
                        {cancelling ? 'Cancelling...' : 'Cancel Order'}
                    </button>
                )}
                {order.status === 'completed' && (
                    <button
                        onClick={handleReorder}
                        className="btn-primary py-3 px-6 flex items-center gap-2"
                    >
                        <HiShoppingCart className="w-5 h-5" />
                        Add to Cart & Reorder
                    </button>
                )}
            </div>

            {/* Reorder Info */}
            {order.status === 'completed' && (
                <p className="text-sm text-gray-500 mt-3">
                    Click "Add to Cart & Reorder" to add items to your cart. You can modify quantities and payment method before checkout.
                </p>
            )}
        </div>
    );
};

export default OrderDetails;
