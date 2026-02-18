import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../../components/customer/CustomerLayout';
import { useAuth } from '../../context/AuthContext';
import {
    HiShoppingCart,
    HiTrash,
    HiPlus,
    HiMinus,
    HiArrowLeft,
    HiArrowRight,
    HiShoppingBag,
    HiSparkles,
    HiBookmark,
    HiOutlineBookmark,
    HiCube,
    HiLockClosed,
    HiTruck,
    HiBadgeCheck
} from 'react-icons/hi';

const Cart = () => {
    const {
        cart,
        removeFromCart,
        updateQuantity,
        cartTotal,
        clearCart,
        savedForLater,
        saveForLater,
        moveToCart,
        removeFromSaved
    } = useCart();
    const { isAuthenticated } = useAuth();
    const navigate = useNavigate();

    const handleCheckout = () => {
        if (!isAuthenticated) {
            navigate('/login');
            return;
        }
        navigate('/store/checkout');
    };

    const activeCartCount = cart.length;
    const savedCount = savedForLater?.length || 0;

    if (activeCartCount === 0 && savedCount === 0) {
        return (
            <div className="min-h-[60vh] flex flex-col items-center justify-center">
                <div className="text-center py-16 px-8 bg-gradient-to-br from-gray-50 to-white rounded-3xl border border-gray-100 max-w-lg mx-auto">
                    <div className="relative w-28 h-28 mx-auto mb-6">
                        <div className="absolute inset-0 bg-primary-100 rounded-full animate-pulse"></div>
                        <div className="relative w-28 h-28 bg-gradient-to-br from-primary-50 to-primary-100 rounded-full flex items-center justify-center">
                            <HiShoppingCart className="w-14 h-14 text-primary-400" />
                        </div>
                    </div>
                    <h2 className="text-2xl font-bold text-gray-800 mb-3">Your Cart is Empty</h2>
                    <p className="text-gray-500 mb-8 max-w-sm mx-auto">
                        Looks like you haven't added anything to your cart yet. Start exploring!
                    </p>
                    <Link
                        to="/store"
                        className="inline-flex items-center gap-2 bg-gradient-to-r from-primary-500 to-primary-600 text-white px-8 py-4 rounded-2xl font-semibold hover:shadow-lg hover:shadow-primary-500/30 transition-all hover:scale-105"
                    >
                        <HiShoppingBag className="w-5 h-5" />
                        Start Shopping
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                    <Link
                        to="/store"
                        className="p-2 hover:bg-gray-100 rounded-xl transition-colors"
                    >
                        <HiArrowLeft className="w-6 h-6 text-gray-600" />
                    </Link>
                    <div>
                        <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
                            <HiShoppingCart className="w-7 h-7 text-primary-600" />
                            Shopping Cart
                        </h1>
                        <p className="text-gray-500 text-sm">
                            {activeCartCount} {activeCartCount === 1 ? 'item' : 'items'} in your cart
                            {savedCount > 0 && ` • ${savedCount} saved for later`}
                        </p>
                    </div>
                </div>
                {activeCartCount > 0 && (
                    <button
                        onClick={clearCart}
                        className="text-red-500 hover:text-red-600 font-medium text-sm hover:bg-red-50 px-4 py-2 rounded-xl transition-colors"
                    >
                        Clear All
                    </button>
                )}
            </div>

            <div className="grid lg:grid-cols-3 gap-8">
                {/* Cart Items & Saved for Later */}
                <div className="lg:col-span-2 space-y-6">
                    {/* Active Cart Items */}
                    {activeCartCount > 0 && (
                        <div className="space-y-4">
                            <h2 className="font-semibold text-gray-700 flex items-center gap-2">
                                <HiShoppingBag className="w-5 h-5" />
                                Cart Items ({activeCartCount})
                            </h2>
                            {cart.map((item, index) => (
                                <div
                                    key={item.productId}
                                    className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-lg transition-all duration-300"
                                    style={{ animationDelay: `${index * 50}ms` }}
                                >
                                    <div className="flex gap-5">
                                        {/* Product Image */}
                                        <Link to={`/store/product/${item.productId}`} className="flex-shrink-0">
                                            <div className="w-28 h-28 bg-gradient-to-br from-gray-50 to-gray-100 rounded-2xl overflow-hidden group flex items-center justify-center">
                                                {item.image ? (
                                                    <img
                                                        src={item.image}
                                                        alt={item.name}
                                                        className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                                                    />
                                                ) : (
                                                    <HiCube className="w-12 h-12 text-gray-300" />
                                                )}
                                            </div>
                                        </Link>

                                        {/* Product Info */}
                                        <div className="flex-1 min-w-0">
                                            <Link to={`/store/product/${item.productId}`}>
                                                <h3 className="font-bold text-gray-800 text-lg hover:text-primary-600 transition-colors line-clamp-2 mb-2">
                                                    {item.name}
                                                </h3>
                                            </Link>

                                            <p className="text-2xl font-bold bg-gradient-to-r from-primary-600 to-accent-600 bg-clip-text text-transparent mb-4">
                                                ₹{item.price?.toLocaleString()}
                                            </p>

                                            <div className="flex items-center justify-between flex-wrap gap-3">
                                                {/* Quantity Controls */}
                                                <div className="flex items-center gap-3 bg-gray-100 rounded-xl p-1.5">
                                                    <button
                                                        onClick={() => updateQuantity(item.productId, item.quantity - 1)}
                                                        className="w-9 h-9 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-50 transition-colors"
                                                    >
                                                        <HiMinus className="w-4 h-4" />
                                                    </button>
                                                    <span className="font-bold w-10 text-center text-lg">{item.quantity}</span>
                                                    <button
                                                        onClick={() => updateQuantity(item.productId, item.quantity + 1)}
                                                        className="w-9 h-9 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-50 transition-colors"
                                                    >
                                                        <HiPlus className="w-4 h-4" />
                                                    </button>
                                                </div>

                                                {/* Actions */}
                                                <div className="flex items-center gap-2">
                                                    <span className="font-bold text-gray-800 text-lg">
                                                        ₹{(item.price * item.quantity).toLocaleString()}
                                                    </span>

                                                    {/* Save for Later */}
                                                    <button
                                                        onClick={() => saveForLater(item.productId)}
                                                        className="p-2.5 text-amber-500 hover:bg-amber-50 rounded-xl transition-colors"
                                                        title="Save for later"
                                                    >
                                                        <HiOutlineBookmark className="w-5 h-5" />
                                                    </button>

                                                    {/* Remove */}
                                                    <button
                                                        onClick={() => removeFromCart(item.productId)}
                                                        className="p-2.5 text-red-500 hover:bg-red-50 rounded-xl transition-colors"
                                                        title="Remove from cart"
                                                    >
                                                        <HiTrash className="w-5 h-5" />
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}

                    {/* Saved for Later Section */}
                    {savedCount > 0 && (
                        <div className="space-y-4 pt-4 border-t border-gray-200">
                            <h2 className="font-semibold text-gray-700 flex items-center gap-2">
                                <HiBookmark className="w-5 h-5 text-amber-500" />
                                Saved for Later ({savedCount})
                            </h2>
                            <p className="text-sm text-gray-500">These items won't be included in your current order</p>

                            <div className="grid sm:grid-cols-2 gap-4">
                                {savedForLater.map((item) => (
                                    <div
                                        key={item.productId}
                                        className="bg-gray-50 rounded-2xl border border-gray-200 p-4 hover:shadow-md transition-all"
                                    >
                                        <div className="flex gap-4">
                                            <Link to={`/store/product/${item.productId}`} className="flex-shrink-0">
                                                <div className="w-20 h-20 bg-white rounded-xl overflow-hidden flex items-center justify-center">
                                                    {item.image ? (
                                                        <img
                                                            src={item.image}
                                                            alt={item.name}
                                                            className="w-full h-full object-cover"
                                                        />
                                                    ) : (
                                                        <HiCube className="w-8 h-8 text-gray-300" />
                                                    )}
                                                </div>
                                            </Link>
                                            <div className="flex-1 min-w-0">
                                                <h3 className="font-semibold text-gray-800 text-sm line-clamp-2 mb-1">
                                                    {item.name}
                                                </h3>
                                                <p className="font-bold text-primary-600 mb-2">
                                                    ₹{item.price?.toLocaleString()}
                                                </p>
                                                <div className="flex gap-2">
                                                    <button
                                                        onClick={() => moveToCart(item.productId)}
                                                        className="flex-1 text-xs font-semibold py-2 px-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
                                                    >
                                                        Move to Cart
                                                    </button>
                                                    <button
                                                        onClick={() => removeFromSaved(item.productId)}
                                                        className="p-2 text-red-500 hover:bg-red-100 rounded-lg transition-colors"
                                                    >
                                                        <HiTrash className="w-4 h-4" />
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Empty Active Cart but has Saved Items */}
                    {activeCartCount === 0 && savedCount > 0 && (
                        <div className="text-center py-8 bg-white rounded-2xl border border-gray-100">
                            <HiShoppingCart className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                            <p className="text-gray-500">Your cart is empty. Move items from "Saved for Later" to continue shopping.</p>
                        </div>
                    )}
                </div>

                {/* Order Summary */}
                <div className="lg:col-span-1">
                    <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-3xl p-6 text-white sticky top-24">
                        <div className="flex items-center gap-3 mb-6">
                            <HiSparkles className="w-6 h-6 text-yellow-400" />
                            <h2 className="text-xl font-bold">Order Summary</h2>
                        </div>

                        <div className="space-y-4 mb-6">
                            <div className="flex justify-between text-gray-300">
                                <span>Subtotal ({activeCartCount} items)</span>
                                <span className="font-semibold text-white">₹{cartTotal.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between text-gray-300">
                                <span>Delivery</span>
                                <span className="text-green-400 font-medium">FREE</span>
                            </div>
                            {savedCount > 0 && (
                                <div className="flex justify-between text-gray-400 text-sm">
                                    <span>Saved for later</span>
                                    <span>{savedCount} items</span>
                                </div>
                            )}
                            <hr className="border-gray-700" />
                            <div className="flex justify-between text-lg">
                                <span className="font-semibold">Total</span>
                                <span className="font-bold text-2xl">₹{cartTotal.toLocaleString()}</span>
                            </div>
                        </div>

                        <button
                            onClick={handleCheckout}
                            disabled={activeCartCount === 0}
                            className={`w-full py-4 rounded-2xl font-bold text-lg flex items-center justify-center gap-2 transition-all ${activeCartCount === 0
                                    ? 'bg-gray-600 text-gray-400 cursor-not-allowed'
                                    : 'bg-gradient-to-r from-primary-500 to-accent-500 text-white hover:shadow-lg hover:shadow-primary-500/30 hover:scale-[1.02]'
                                }`}
                        >
                            Proceed to Checkout
                            <HiArrowRight className="w-5 h-5" />
                        </button>

                        <Link
                            to="/store"
                            className="w-full mt-4 border border-gray-600 text-gray-300 py-3 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-gray-700 transition-colors"
                        >
                            <HiArrowLeft className="w-5 h-5" />
                            Continue Shopping
                        </Link>

                        {/* Trust Badges */}
                        <div className="mt-6 pt-6 border-t border-gray-700">
                            <div className="flex items-center justify-center gap-4 text-gray-400 text-sm">
                                <span className="flex items-center gap-1">
                                    <HiLockClosed className="w-4 h-4" /> Secure
                                </span>
                                <span>•</span>
                                <span className="flex items-center gap-1">
                                    <HiTruck className="w-4 h-4" /> Fast Delivery
                                </span>
                                <span>•</span>
                                <span className="flex items-center gap-1">
                                    <HiBadgeCheck className="w-4 h-4" /> Quality
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Cart;
