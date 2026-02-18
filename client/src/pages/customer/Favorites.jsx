import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import {
    HiHeart,
    HiShoppingCart,
    HiTrash,
    HiPlus,
    HiMinus,
    HiArrowLeft,
    HiOutlineHeart
} from 'react-icons/hi';

const Favorites = () => {
    const [favorites, setFavorites] = useState([]);
    const [loading, setLoading] = useState(true);
    const [quantities, setQuantities] = useState({});
    const [removingId, setRemovingId] = useState(null);
    const { addToCart, cart } = useCart();

    useEffect(() => {
        fetchFavorites();
    }, []);

    const fetchFavorites = async () => {
        try {
            const { data } = await storeAPI.getFavorites();
            setFavorites(data);
        } catch (error) {
            console.error('Failed to fetch favorites:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleRemoveFavorite = async (productId) => {
        setRemovingId(productId);
        try {
            await storeAPI.removeFavorite(productId);
            setFavorites(prev => prev.filter(p => p._id !== productId));
        } catch (error) {
            console.error('Failed to remove favorite:', error);
        } finally {
            setRemovingId(null);
        }
    };

    const getQuantity = (productId) => quantities[productId] || 1;

    const updateQuantity = (productId, delta) => {
        setQuantities(prev => ({
            ...prev,
            [productId]: Math.max(1, (prev[productId] || 1) + delta)
        }));
    };

    const handleAddToCart = (product) => {
        addToCart(product, getQuantity(product._id), product.businessId?._id);
        setQuantities(prev => ({ ...prev, [product._id]: 1 }));
    };

    const isInCart = (productId) => cart.some(item => item.productId === productId);

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center py-20">
                <div className="relative">
                    <div className="w-16 h-16 border-4 border-red-200 rounded-full animate-spin border-t-red-500"></div>
                    <HiHeart className="absolute inset-0 m-auto w-6 h-6 text-red-500" />
                </div>
                <p className="mt-4 text-gray-500 font-medium">Loading your favorites...</p>
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
                            <HiHeart className="w-7 h-7 text-red-500" />
                            My Favorites
                        </h1>
                        <p className="text-gray-500 text-sm">
                            {favorites.length} {favorites.length === 1 ? 'item' : 'items'} saved
                        </p>
                    </div>
                </div>
            </div>

            {favorites.length === 0 ? (
                <div className="text-center py-20 bg-gradient-to-br from-gray-50 to-white rounded-3xl border border-gray-100">
                    <div className="w-24 h-24 bg-red-50 rounded-full flex items-center justify-center mx-auto mb-6">
                        <HiOutlineHeart className="w-12 h-12 text-red-300" />
                    </div>
                    <h3 className="text-2xl font-bold text-gray-800 mb-2">No Favorites Yet</h3>
                    <p className="text-gray-500 mb-6 max-w-md mx-auto">
                        Start exploring products and tap the heart icon to save your favorites here.
                    </p>
                    <Link to="/store" className="btn-primary inline-flex items-center gap-2">
                        <HiShoppingCart className="w-5 h-5" />
                        Start Shopping
                    </Link>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {favorites.map(product => (
                        <div
                            key={product._id}
                            className={`bg-white rounded-2xl border border-gray-100 overflow-hidden hover:shadow-xl transition-all duration-300 ${removingId === product._id ? 'opacity-50 scale-95' : ''
                                }`}
                        >
                            {/* Product Image */}
                            <div className="relative">
                                <Link to={`/store/product/${product._id}`}>
                                    <div className="aspect-[4/3] bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
                                        {product.image ? (
                                            <img
                                                src={product.image}
                                                alt={product.name}
                                                className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
                                            />
                                        ) : (
                                            <div className="w-full h-full flex items-center justify-center">
                                                <span className="text-5xl opacity-50">📦</span>
                                            </div>
                                        )}
                                    </div>
                                </Link>

                                {/* Remove Button - Prominent */}
                                <button
                                    onClick={() => handleRemoveFavorite(product._id)}
                                    disabled={removingId === product._id}
                                    className="absolute top-3 right-3 flex items-center gap-2 px-3 py-2 bg-white/95 backdrop-blur-sm text-red-600 rounded-xl shadow-lg hover:bg-red-500 hover:text-white transition-all duration-300 font-medium text-sm group"
                                >
                                    <HiTrash className="w-4 h-4" />
                                    <span className="hidden group-hover:inline">Remove</span>
                                </button>

                                {/* Favorite Heart */}
                                <div className="absolute top-3 left-3 w-10 h-10 bg-red-500 rounded-full flex items-center justify-center shadow-lg shadow-red-500/30">
                                    <HiHeart className="w-5 h-5 text-white" />
                                </div>
                            </div>

                            {/* Product Info */}
                            <div className="p-5">
                                {/* Business Name */}
                                {product.businessId && (
                                    <Link
                                        to={`/store/business/${product.businessId._id}`}
                                        className="text-xs text-primary-600 font-semibold hover:underline mb-2 block uppercase tracking-wide"
                                    >
                                        {product.businessId.name}
                                    </Link>
                                )}

                                <Link to={`/store/product/${product._id}`}>
                                    <h3 className="font-bold text-gray-800 text-lg mb-2 hover:text-primary-600 transition-colors line-clamp-2">
                                        {product.name}
                                    </h3>
                                </Link>

                                <div className="flex items-center justify-between mb-4">
                                    <span className="text-2xl font-bold bg-gradient-to-r from-primary-600 to-accent-600 bg-clip-text text-transparent">
                                        ₹{product.sellingPrice?.toLocaleString()}
                                    </span>
                                    <span className={`text-sm font-medium px-3 py-1 rounded-full ${product.stock > 0
                                            ? 'bg-green-50 text-green-600 border border-green-200'
                                            : 'bg-red-50 text-red-600 border border-red-200'
                                        }`}>
                                        {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
                                    </span>
                                </div>

                                {/* Quantity & Add to Cart */}
                                {product.stock > 0 && (
                                    <div className="flex items-center gap-3">
                                        {/* Quantity Selector */}
                                        <div className="flex items-center gap-2 bg-gray-100 rounded-xl p-1">
                                            <button
                                                onClick={() => updateQuantity(product._id, -1)}
                                                className="w-9 h-9 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-50 transition-colors"
                                            >
                                                <HiMinus className="w-4 h-4" />
                                            </button>
                                            <span className="font-bold w-8 text-center">{getQuantity(product._id)}</span>
                                            <button
                                                onClick={() => updateQuantity(product._id, 1)}
                                                className="w-9 h-9 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-50 transition-colors"
                                            >
                                                <HiPlus className="w-4 h-4" />
                                            </button>
                                        </div>

                                        {/* Add to Cart Button */}
                                        <button
                                            onClick={() => handleAddToCart(product)}
                                            className={`flex-1 py-3 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all duration-300 ${isInCart(product._id)
                                                    ? 'bg-green-500 text-white shadow-lg shadow-green-500/30'
                                                    : 'bg-gradient-to-r from-primary-500 to-primary-600 text-white hover:shadow-lg hover:shadow-primary-500/30'
                                                }`}
                                        >
                                            <HiShoppingCart className="w-5 h-5" />
                                            {isInCart(product._id) ? 'Added!' : 'Add to Cart'}
                                        </button>
                                    </div>
                                )}

                                {product.stock <= 0 && (
                                    <button
                                        disabled
                                        className="w-full py-3 rounded-xl font-semibold bg-gray-100 text-gray-400 cursor-not-allowed"
                                    >
                                        Out of Stock
                                    </button>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Favorites;
