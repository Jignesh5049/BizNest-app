import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import { useAuth } from '../../context/AuthContext';
import { formatCurrency } from '../../utils/helpers';
import {
    HiSearch,
    HiShoppingCart,
    HiHeart,
    HiPlus,
    HiMinus,
    HiArrowRight,
    HiOfficeBuilding,
    HiSortAscending,
    HiSortDescending,
    HiFilter,
    HiSparkles,
    HiCube,
    HiStar,
    HiViewGrid,
    HiColorSwatch,
    HiCog,
    HiDesktopComputer,
    HiCollection,
    HiTemplate
} from 'react-icons/hi';
import { MdFastfood, MdStorefront } from 'react-icons/md';
import { GiClothes } from 'react-icons/gi';

const categories = [
    { value: 'all', label: 'All', Icon: HiViewGrid },
    { value: 'retail', label: 'Retail', Icon: MdStorefront },
    { value: 'food', label: 'Food', Icon: MdFastfood },
    { value: 'services', label: 'Services', Icon: HiCog },
    { value: 'handmade', label: 'Handmade', Icon: HiColorSwatch },
    { value: 'electronics', label: 'Electronics', Icon: HiDesktopComputer },
    { value: 'clothing', label: 'Clothing', Icon: HiTemplate },
    { value: 'other', label: 'Other', Icon: HiCollection }
];

const sortOptions = [
    { value: 'newest', label: 'Newest First', icon: HiSparkles },
    { value: 'price_low', label: 'Price: Low to High', icon: HiSortAscending },
    { value: 'price_high', label: 'Price: High to Low', icon: HiSortDescending },
    { value: 'name_asc', label: 'Name: A to Z', icon: HiSortAscending },
    { value: 'name_desc', label: 'Name: Z to A', icon: HiSortDescending },
];

const CustomerHome = () => {
    const [products, setProducts] = useState([]);
    const [businesses, setBusinesses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('all');
    const [sortBy, setSortBy] = useState('newest');
    const [showFilters, setShowFilters] = useState(false);
    const [quantities, setQuantities] = useState({});
    const [favorites, setFavorites] = useState([]);
    const { addToCart, cart } = useCart();
    const { isAuthenticated } = useAuth();
    const navigate = useNavigate();

    useEffect(() => {
        fetchData();
        if (isAuthenticated) {
            fetchFavorites();
        }
    }, [selectedCategory, isAuthenticated]);

    const fetchData = async () => {
        try {
            setLoading(true);
            const params = { limit: 30 };
            if (selectedCategory !== 'all') params.category = selectedCategory;
            if (searchQuery) params.search = searchQuery;

            const [productsRes, businessesRes] = await Promise.all([
                storeAPI.getAllProducts(params),
                storeAPI.getBusinesses({ limit: 8 })
            ]);

            setProducts(productsRes.data);
            setBusinesses(businessesRes.data);
        } catch (error) {
            console.error('Failed to fetch data:', error);
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

    const handleSearch = (e) => {
        e.preventDefault();
        fetchData();
    };

    const getQuantity = (productId) => quantities[productId] || 1;

    const updateProductQuantity = (productId, delta) => {
        setQuantities(prev => ({
            ...prev,
            [productId]: Math.max(1, (prev[productId] || 1) + delta)
        }));
    };

    const handleAddToCart = (product) => {
        addToCart(product, getQuantity(product._id), product.businessId?._id);
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

    // Sort products
    const sortedProducts = [...products].sort((a, b) => {
        switch (sortBy) {
            case 'price_low':
                return (a.sellingPrice || 0) - (b.sellingPrice || 0);
            case 'price_high':
                return (b.sellingPrice || 0) - (a.sellingPrice || 0);
            case 'name_asc':
                return (a.name || '').localeCompare(b.name || '');
            case 'name_desc':
                return (b.name || '').localeCompare(a.name || '');
            default:
                return 0;
        }
    });

    return (
        <div className="space-y-8">
            {/* Hero Section - Enhanced */}
            <div className="relative overflow-hidden bg-gradient-to-br from-primary-800 via-primary-600 to-primary-500 rounded-3xl p-8 md:p-12 text-white">
                {/* Decorative elements */}
                <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -translate-y-1/2 translate-x-1/2"></div>
                <div className="absolute bottom-0 left-0 w-48 h-48 bg-white/10 rounded-full blur-2xl translate-y-1/2 -translate-x-1/2"></div>

                <div className="relative z-10">
                    <div className="flex items-center gap-2 mb-4">
                        <span className="px-3 py-1 bg-white/20 rounded-full text-sm font-medium backdrop-blur-sm flex items-center gap-1.5">
                            <HiSparkles className="w-4 h-4" /> Shop Local
                        </span>
                    </div>
                    <h1 className="text-3xl md:text-5xl font-bold mb-4 leading-tight">
                        Discover Amazing<br />
                        <span className="text-primary-100">Products & Services</span>
                    </h1>
                    <p className="text-primary-100 text-lg mb-8 max-w-xl">
                        Support local businesses and find unique items from shops in your community.
                    </p>

                    {/* Search Bar - Enhanced */}
                    <form onSubmit={handleSearch} className="flex gap-3 max-w-2xl">
                        <div className="relative flex-1">
                            <HiSearch className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                            <input
                                type="text"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                placeholder="What are you looking for?"
                                className="w-full pl-12 pr-4 py-4 rounded-2xl text-gray-800 bg-white shadow-lg focus:ring-4 focus:ring-white/30 outline-none text-lg"
                            />
                        </div>
                        <button type="submit" className="bg-gray-900 text-white font-semibold px-8 py-4 rounded-2xl hover:bg-gray-800 transition-all shadow-lg hover:shadow-xl hover:scale-105">
                            Search
                        </button>
                    </form>
                </div>
            </div>

            {/* Category Pills - Enhanced */}
            <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
                {categories.map(category => {
                    const IconComponent = category.Icon;
                    return (
                        <button
                            key={category.value}
                            onClick={() => setSelectedCategory(category.value)}
                            className={`flex items-center gap-2 px-5 py-3 rounded-2xl font-medium whitespace-nowrap transition-all duration-300 ${selectedCategory === category.value
                                ? 'bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg shadow-primary-500/30 scale-105'
                                : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200 hover:border-primary-200 hover:shadow-md'
                                }`}
                        >
                            <IconComponent className="w-5 h-5" />
                            {category.label}
                        </button>
                    );
                })}
            </div>

            {/* Sort & Filter Bar */}
            <div className="flex flex-wrap items-center justify-between gap-4 bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
                <div className="flex items-center gap-3">
                    <span className="text-gray-500 font-medium">
                        {sortedProducts.length} products
                    </span>
                </div>

                <div className="flex items-center gap-3">
                    {/* Sort Dropdown */}
                    <div className="relative">
                        <select
                            value={sortBy}
                            onChange={(e) => setSortBy(e.target.value)}
                            className="appearance-none bg-gray-50 border border-gray-200 rounded-xl px-4 py-2.5 pr-10 font-medium text-gray-700 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 cursor-pointer hover:bg-gray-100 transition-colors"
                        >
                            {sortOptions.map(option => (
                                <option key={option.value} value={option.value}>
                                    {option.label}
                                </option>
                            ))}
                        </select>
                        <HiFilter className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 pointer-events-none" />
                    </div>
                </div>
            </div>

            {/* Products Grid - Enhanced */}
            <div>
                {loading ? (
                    <div className="flex flex-col items-center justify-center py-16">
                        <div className="relative">
                            <div className="w-16 h-16 border-4 border-primary-200 rounded-full animate-spin border-t-primary-600"></div>
                        </div>
                        <p className="mt-4 text-gray-500 font-medium">Loading products...</p>
                    </div>
                ) : sortedProducts.length === 0 ? (
                    <div className="text-center py-16 bg-gradient-to-br from-gray-50 to-white rounded-3xl border border-gray-100">
                        <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <HiSearch className="w-10 h-10 text-gray-400" />
                        </div>
                        <h3 className="text-2xl font-bold text-gray-800 mb-2">No Products Found</h3>
                        <p className="text-gray-500 mb-6">Try adjusting your search or filters</p>
                        <button
                            onClick={() => { setSelectedCategory('all'); setSearchQuery(''); fetchData(); }}
                            className="btn-primary"
                        >
                            Clear Filters
                        </button>
                    </div>
                ) : (
                    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-5">
                        {sortedProducts.map(product => (
                            <div
                                key={product._id}
                                className="group bg-white rounded-2xl border border-gray-100 overflow-hidden hover:shadow-xl hover:shadow-gray-200/50 transition-all duration-300 hover:-translate-y-1"
                            >
                                {/* Product Image */}
                                <div className="relative">
                                    {/* Favorite Button */}
                                    <button
                                        onClick={(e) => handleToggleFavorite(product._id, e)}
                                        className={`absolute top-3 right-3 z-10 w-9 h-9 rounded-full flex items-center justify-center transition-all duration-300 backdrop-blur-sm ${isFavorite(product._id)
                                            ? 'bg-red-500 text-white scale-110 shadow-lg shadow-red-500/30'
                                            : 'bg-white/90 text-gray-400 hover:text-red-500 hover:bg-white shadow-md'
                                            }`}
                                    >
                                        <HiHeart className={`w-5 h-5 ${isFavorite(product._id) ? 'fill-current' : ''}`} />
                                    </button>

                                    <Link to={`/store/product/${product._id}`}>
                                        <div className="aspect-square bg-gradient-to-br from-gray-50 to-gray-100 overflow-hidden">
                                            {product.image ? (
                                                <img
                                                    src={product.image}
                                                    alt={product.name}
                                                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                                                />
                                            ) : (
                                                <div className="w-full h-full flex items-center justify-center">
                                                    <HiCube className="w-12 h-12 text-gray-300" />
                                                </div>
                                            )}
                                        </div>
                                    </Link>

                                    {/* Stock Badge */}
                                    {product.stock <= 5 && product.stock > 0 && (
                                        <span className="absolute bottom-3 left-3 bg-orange-500 text-white text-xs font-bold px-2 py-1 rounded-lg shadow-lg">
                                            Only {product.stock} left!
                                        </span>
                                    )}
                                </div>

                                {/* Product Info */}
                                <div className="p-4">
                                    {/* Business Name */}
                                    {product.businessId && (
                                        <Link
                                            to={`/store/business/${product.businessId._id}`}
                                            className="text-xs text-primary-600 font-medium hover:underline mb-1 block truncate"
                                        >
                                            {product.businessId.name}
                                        </Link>
                                    )}

                                    <Link to={`/store/product/${product._id}`}>
                                        <h3 className="font-semibold text-gray-800 text-sm mb-2 hover:text-primary-600 transition-colors line-clamp-2 min-h-[2.5rem]">
                                            {product.name}
                                        </h3>
                                    </Link>

                                    <div className="flex items-center justify-between mb-3">
                                        <span className="text-xl font-bold bg-gradient-to-r from-primary-600 to-accent-600 bg-clip-text text-transparent">
                                            {formatCurrency(product.sellingPrice)}
                                        </span>
                                        <span className={`text-xs font-medium px-2 py-1 rounded-full ${product.stock > 0
                                            ? 'bg-green-50 text-green-600'
                                            : 'bg-red-50 text-red-600'
                                            }`}>
                                            {product.stock > 0 ? 'In Stock' : 'Out'}
                                        </span>
                                    </div>

                                    <div className="flex items-center gap-2 text-xs text-gray-500 mb-3">
                                        <HiStar className={`w-4 h-4 ${product.ratingAverage > 0 ? 'text-yellow-400' : 'text-gray-300'}`} />
                                        <span>
                                            {product.ratingCount > 0
                                                ? `${product.ratingAverage?.toFixed(1)} (${product.ratingCount})`
                                                : 'No ratings'}
                                        </span>
                                    </div>

                                    {/* Quantity & Add to Cart */}
                                    {product.stock > 0 && (
                                        <div className="space-y-2">
                                            <div className="flex items-center justify-center gap-2 bg-gray-50 rounded-xl p-1.5">
                                                <button
                                                    onClick={() => updateProductQuantity(product._id, -1)}
                                                    className="w-8 h-8 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-100 transition-colors"
                                                >
                                                    <HiMinus className="w-4 h-4" />
                                                </button>
                                                <span className="font-bold w-8 text-center">{getQuantity(product._id)}</span>
                                                <button
                                                    onClick={() => updateProductQuantity(product._id, 1)}
                                                    className="w-8 h-8 rounded-lg bg-white shadow-sm flex items-center justify-center hover:bg-gray-100 transition-colors"
                                                >
                                                    <HiPlus className="w-4 h-4" />
                                                </button>
                                            </div>
                                            <button
                                                onClick={() => handleAddToCart(product)}
                                                className={`w-full py-2.5 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 transition-all duration-300 ${isInCart(product._id)
                                                    ? 'bg-green-500 text-white shadow-lg shadow-green-500/30'
                                                    : 'bg-gradient-to-r from-primary-500 to-primary-600 text-white hover:shadow-lg hover:shadow-primary-500/30 hover:scale-[1.02]'
                                                    }`}
                                            >
                                                <HiShoppingCart className="w-4 h-4" />
                                                {isInCart(product._id) ? 'Added!' : 'Add to Cart'}
                                            </button>
                                        </div>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Browse Businesses Section - Enhanced */}
            <div className="bg-gradient-to-br from-gray-50 to-white rounded-3xl p-8 border border-gray-100">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h2 className="text-2xl font-bold text-gray-800 flex items-center gap-3">
                            <div className="w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl flex items-center justify-center">
                                <HiOfficeBuilding className="w-5 h-5 text-white" />
                            </div>
                            Browse Businesses
                        </h2>
                        <p className="text-gray-500 mt-1">Discover local shops and stores</p>
                    </div>
                    <Link
                        to="/store/businesses"
                        className="flex items-center gap-2 px-5 py-2.5 bg-white border border-gray-200 rounded-xl font-medium text-gray-700 hover:bg-gray-50 hover:border-primary-300 transition-all group"
                    >
                        View All
                        <HiArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                    </Link>
                </div>

                {businesses.length === 0 ? (
                    <p className="text-gray-500 text-center py-8">No businesses available yet.</p>
                ) : (
                    <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-4">
                        {businesses.slice(0, 8).map(business => (
                            <Link
                                key={business._id}
                                to={`/store/business/${business._id}`}
                                className="text-center group"
                            >
                                <div className="w-16 h-16 mx-auto bg-gradient-to-br from-primary-100 to-primary-200 rounded-2xl flex items-center justify-center mb-3 group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-primary-500/20 transition-all duration-300">
                                    {business.logo ? (
                                        <img src={business.logo} alt={business.name} className="w-12 h-12 object-contain rounded-xl" />
                                    ) : (
                                        <span className="text-xl font-bold text-primary-600">
                                            {business.name?.charAt(0)?.toUpperCase()}
                                        </span>
                                    )}
                                </div>
                                <p className="text-sm font-medium text-gray-800 group-hover:text-primary-600 truncate transition-colors">
                                    {business.name}
                                </p>
                            </Link>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default CustomerHome;
