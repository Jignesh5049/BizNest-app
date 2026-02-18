import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import { useAuth } from '../../context/AuthContext';
import { formatCurrency } from '../../utils/helpers';
import {
    HiArrowLeft,
    HiLocationMarker,
    HiPhone,
    HiMail,
    HiSearch,
    HiPlus,
    HiMinus,
    HiHeart,
    HiShoppingCart,
    HiStar
} from 'react-icons/hi';
import { FaWhatsapp } from 'react-icons/fa';

const BusinessStore = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [business, setBusiness] = useState(null);
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('all');
    const [quantities, setQuantities] = useState({});
    const [favorites, setFavorites] = useState([]);
    const { addToCart, cart } = useCart();
    const { isAuthenticated } = useAuth();

    useEffect(() => {
        fetchBusinessData();
        if (isAuthenticated) {
            fetchFavorites();
        }
    }, [id, isAuthenticated]);

    const fetchBusinessData = async () => {
        try {
            setLoading(true);
            const { data } = await storeAPI.getBusiness(id);
            setBusiness(data.business);
            setProducts(data.products);
        } catch (error) {
            console.error('Failed to fetch business:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchFavorites = async () => {
        try {
            const { data } = await storeAPI.getFavorites();
            setFavorites(data.map(p => p._id));
        } catch (error) {
            console.error('Failed to fetch favorites:', error);
        }
    };

    const getQuantity = (productId) => quantities[productId] || 1;

    const updateProductQuantity = (productId, delta) => {
        setQuantities(prev => ({
            ...prev,
            [productId]: Math.max(1, (prev[productId] || 1) + delta)
        }));
    };

    const handleAddToCart = (product) => {
        addToCart(product, getQuantity(product._id), id);
        setQuantities(prev => ({ ...prev, [product._id]: 1 }));
    };

    const handleToggleFavorite = async (productId, e) => {
        e.preventDefault();
        e.stopPropagation();

        if (!isAuthenticated) {
            navigate('/login');
            return;
        }

        try {
            if (favorites.includes(productId)) {
                await storeAPI.removeFavorite(productId);
                setFavorites(prev => prev.filter(id => id !== productId));
            } else {
                await storeAPI.addFavorite(productId);
                setFavorites(prev => [...prev, productId]);
            }
        } catch (error) {
            console.error('Failed to update favorites:', error);
        }
    };

    const isInCart = (productId) => cart.some(item => item.productId === productId);
    const isFavorite = (productId) => favorites.includes(productId);

    // Get unique categories from products
    const categories = ['all', ...new Set(products.map(p => p.category).filter(Boolean))];

    // Filter products
    const filteredProducts = products.filter(product => {
        const matchesSearch = product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            product.description?.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesCategory = selectedCategory === 'all' || product.category === selectedCategory;
        return matchesSearch && matchesCategory;
    });

    if (loading) {
        return (
            <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    if (!business) {
        return (
            <div className="text-center py-12">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Business Not Found</h3>
                <Link to="/store" className="text-primary-600 hover:underline">Go back to home</Link>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Back Button */}
            <Link to="/store" className="inline-flex items-center gap-2 text-gray-600 hover:text-primary-600 transition-colors">
                <HiArrowLeft className="w-5 h-5" />
                Back to Home
            </Link>

            {/* Business Header */}
            <div className="card">
                <div className="flex flex-col md:flex-row gap-6">
                    {/* Logo */}
                    <div className="w-24 h-24 bg-gradient-to-br from-primary-100 to-primary-200 rounded-2xl flex items-center justify-center flex-shrink-0">
                        {business.logo ? (
                            <img src={business.logo} alt={business.name} className="w-20 h-20 object-contain rounded-xl" />
                        ) : (
                            <span className="text-4xl font-bold text-primary-600">
                                {business.name?.charAt(0)?.toUpperCase()}
                            </span>
                        )}
                    </div>

                    {/* Info */}
                    <div className="flex-1">
                        <h1 className="text-2xl font-bold text-gray-800 mb-2">{business.name}</h1>
                        <span className="inline-block px-3 py-1 bg-primary-50 text-primary-700 text-sm font-medium rounded-full mb-3">
                            {business.category?.charAt(0).toUpperCase() + business.category?.slice(1)}
                        </span>

                        {business.description && (
                            <p className="text-gray-600 mb-4">{business.description}</p>
                        )}

                        {/* Contact Details */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
                            {business.address?.city && (
                                <div className="flex items-center gap-2 text-gray-600">
                                    <HiLocationMarker className="w-4 h-4 text-gray-400" />
                                    <span>
                                        {[business.address.street, business.address.city, business.address.state, business.address.pincode]
                                            .filter(Boolean).join(', ')}
                                    </span>
                                </div>
                            )}
                            {business.contact?.phone && (
                                <div className="flex items-center gap-2 text-gray-600">
                                    <HiPhone className="w-4 h-4 text-gray-400" />
                                    <a href={`tel:${business.contact.phone}`} className="hover:text-primary-600">
                                        {business.contact.phone}
                                    </a>
                                </div>
                            )}
                            {business.contact?.email && (
                                <div className="flex items-center gap-2 text-gray-600">
                                    <HiMail className="w-4 h-4 text-gray-400" />
                                    <a href={`mailto:${business.contact.email}`} className="hover:text-primary-600">
                                        {business.contact.email}
                                    </a>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* WhatsApp Button */}
                    {business.contact?.whatsapp && (
                        <a
                            href={`https://wa.me/${business.contact.whatsapp.replace(/\D/g, '')}?text=Hi! I found your business on BizNest.`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center justify-center gap-2 px-6 py-3 bg-green-500 text-white rounded-xl hover:bg-green-600 transition-colors self-start"
                        >
                            <FaWhatsapp className="w-5 h-5" />
                            Chat on WhatsApp
                        </a>
                    )}
                </div>
            </div>

            {/* Products Section */}
            <div>
                <div className="flex flex-col sm:flex-row gap-4 mb-6">
                    <h2 className="text-xl font-bold text-gray-800">Products</h2>

                    {/* Search */}
                    <div className="relative flex-1 max-w-md ml-auto">
                        <HiSearch className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input
                            type="text"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            placeholder="Search products..."
                            className="input pl-12"
                        />
                    </div>
                </div>

                {/* Category Filters */}
                {categories.length > 1 && (
                    <div className="flex gap-2 overflow-x-auto pb-4">
                        {categories.map(category => (
                            <button
                                key={category}
                                onClick={() => setSelectedCategory(category)}
                                className={`px-4 py-2 rounded-full font-medium whitespace-nowrap transition-colors ${selectedCategory === category
                                    ? 'bg-primary-600 text-white'
                                    : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
                                    }`}
                            >
                                {category === 'all' ? 'All' : category}
                            </button>
                        ))}
                    </div>
                )}

                {/* Products Grid */}
                {filteredProducts.length === 0 ? (
                    <div className="text-center py-12 bg-white rounded-2xl">
                        <div className="text-5xl mb-4">📦</div>
                        <h3 className="text-lg font-semibold text-gray-800 mb-2">No Products Found</h3>
                        <p className="text-gray-500">Try adjusting your search</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                        {filteredProducts.map(product => (
                            <div key={product._id} className="card group relative">
                                {/* Favorite Button */}
                                <button
                                    onClick={(e) => handleToggleFavorite(product._id, e)}
                                    className={`absolute top-3 right-3 z-10 w-8 h-8 rounded-full flex items-center justify-center transition-all ${isFavorite(product._id)
                                        ? 'bg-red-500 text-white'
                                        : 'bg-white/80 text-gray-400 hover:text-red-500 hover:bg-white'
                                        }`}
                                >
                                    <HiHeart className={`w-5 h-5 ${isFavorite(product._id) ? 'fill-current' : ''}`} />
                                </button>

                                {/* Product Image */}
                                <div className="aspect-square bg-gray-100 rounded-xl mb-4 overflow-hidden">
                                    {product.image ? (
                                        <img
                                            src={product.image}
                                            alt={product.name}
                                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                        />
                                    ) : (
                                        <div className="w-full h-full flex items-center justify-center text-gray-400">
                                            <span className="text-4xl">📦</span>
                                        </div>
                                    )}
                                </div>

                                {/* Product Info */}
                                <Link to={`/store/product/${product._id}`}>
                                    <h3 className="font-semibold text-gray-800 mb-1 hover:text-primary-600 transition-colors line-clamp-2">
                                        {product.name}
                                    </h3>
                                </Link>

                                {product.category && (
                                    <span className="text-xs text-gray-500 mb-2 block">{product.category}</span>
                                )}

                                <div className="flex items-center justify-between mb-4">
                                    <span className="text-xl font-bold text-primary-600">
                                        {formatCurrency(product.sellingPrice)}
                                    </span>
                                    <span className={`text-sm ${product.stock > 0 ? 'text-green-600' : 'text-red-600'}`}>
                                        {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
                                    </span>
                                </div>

                                <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
                                    <HiStar className={`w-4 h-4 ${product.ratingAverage > 0 ? 'text-yellow-400' : 'text-gray-300'}`} />
                                    <span>
                                        {product.ratingCount > 0
                                            ? `${product.ratingAverage?.toFixed(1)} (${product.ratingCount})`
                                            : 'No ratings yet'}
                                    </span>
                                </div>

                                {/* Quantity & Add to Cart */}
                                {product.stock > 0 && (
                                    <div className="space-y-3">
                                        <div className="flex items-center justify-center gap-4 bg-gray-100 rounded-xl p-2">
                                            <button
                                                onClick={() => updateProductQuantity(product._id, -1)}
                                                className="w-8 h-8 rounded-lg bg-white shadow flex items-center justify-center hover:bg-gray-50"
                                            >
                                                <HiMinus className="w-4 h-4" />
                                            </button>
                                            <span className="font-semibold w-8 text-center">{getQuantity(product._id)}</span>
                                            <button
                                                onClick={() => updateProductQuantity(product._id, 1)}
                                                className="w-8 h-8 rounded-lg bg-white shadow flex items-center justify-center hover:bg-gray-50"
                                            >
                                                <HiPlus className="w-4 h-4" />
                                            </button>
                                        </div>
                                        <button
                                            onClick={() => handleAddToCart(product)}
                                            className={`w-full py-2.5 rounded-xl font-medium flex items-center justify-center gap-2 transition-colors ${isInCart(product._id)
                                                ? 'bg-green-500 text-white'
                                                : 'bg-primary-600 text-white hover:bg-primary-700'
                                                }`}
                                        >
                                            <HiShoppingCart className="w-5 h-5" />
                                            {isInCart(product._id) ? 'Added to Cart' : 'Add to Cart'}
                                        </button>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default BusinessStore;
