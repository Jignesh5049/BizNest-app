import { useState, createContext, useContext } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/logo.svg';
import {
    HiHome,
    HiShoppingBag,
    HiHeart,
    HiUser,
    HiShoppingCart,
    HiMenuAlt3,
    HiX,
    HiLogout,
    HiLogin
} from 'react-icons/hi';

// Cart Context
const CartContext = createContext(null);

export const useCart = () => {
    const context = useContext(CartContext);
    if (!context) {
        throw new Error('useCart must be used within CustomerLayout');
    }
    return context;
};

const CustomerLayout = () => {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [cart, setCart] = useState([]);
    const [savedForLater, setSavedForLater] = useState([]);
    const { user, logout, isAuthenticated } = useAuth();
    const navigate = useNavigate();

    const addToCart = (product, quantity = 1, businessId) => {
        // Remove from saved for later if exists
        setSavedForLater(prev => prev.filter(item => item.productId !== product._id));

        setCart(prev => {
            const existingIndex = prev.findIndex(item => item.productId === product._id);
            if (existingIndex >= 0) {
                const updated = [...prev];
                updated[existingIndex].quantity += quantity;
                return updated;
            }
            return [...prev, {
                productId: product._id,
                name: product.name,
                price: product.sellingPrice,
                image: product.image,
                quantity,
                businessId
            }];
        });
    };

    const removeFromCart = (productId) => {
        setCart(prev => prev.filter(item => item.productId !== productId));
    };

    const updateQuantity = (productId, quantity) => {
        if (quantity <= 0) {
            removeFromCart(productId);
            return;
        }
        setCart(prev => prev.map(item =>
            item.productId === productId ? { ...item, quantity } : item
        ));
    };

    const clearCart = () => {
        setCart([]);
    };

    // Save for later functions
    const saveForLater = (productId) => {
        const item = cart.find(item => item.productId === productId);
        if (item) {
            setSavedForLater(prev => [...prev, item]);
            setCart(prev => prev.filter(item => item.productId !== productId));
        }
    };

    const moveToCart = (productId) => {
        const item = savedForLater.find(item => item.productId === productId);
        if (item) {
            setCart(prev => [...prev, item]);
            setSavedForLater(prev => prev.filter(item => item.productId !== productId));
        }
    };

    const removeFromSaved = (productId) => {
        setSavedForLater(prev => prev.filter(item => item.productId !== productId));
    };

    // Add items to cart for reorder (from orders page)
    const addItemsForReorder = (items) => {
        items.forEach(item => {
            const existingIndex = cart.findIndex(cartItem => cartItem.productId === item.productId);
            if (existingIndex < 0) {
                setCart(prev => [...prev, {
                    productId: item.productId,
                    name: item.name,
                    price: item.price,
                    image: item.image || '',
                    quantity: item.quantity,
                    businessId: item.businessId
                }]);
            }
        });
    };

    const cartTotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const navLinks = [
        { to: '/store', icon: HiHome, label: 'Home', end: true },
        { to: '/store/orders', icon: HiShoppingBag, label: 'My Orders', requireAuth: true },
        { to: '/store/favorites', icon: HiHeart, label: 'Favorites', requireAuth: true },
        { to: '/store/profile', icon: HiUser, label: 'Profile', requireAuth: true }
    ];

    const filteredLinks = navLinks.filter(link => !link.requireAuth || isAuthenticated);

    return (
        <CartContext.Provider value={{
            cart,
            addToCart,
            removeFromCart,
            updateQuantity,
            clearCart,
            cartTotal,
            cartCount,
            savedForLater,
            saveForLater,
            moveToCart,
            removeFromSaved,
            addItemsForReorder
        }}>
            <div className="min-h-screen bg-gradient-to-br from-gray-50 via-white to-gray-50">
                {/* Header - Enhanced */}
                <header className="bg-white/80 backdrop-blur-lg border-b border-gray-100 sticky top-0 z-40">
                    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                        <div className="flex items-center justify-between h-18 py-3">
                            {/* Logo - Enhanced */}
                            <NavLink to="/store" className="flex items-center gap-3 group">
                                <div className="relative">
                                    <div className="absolute inset-0 bg-gradient-to-br from-primary-400 to-accent-500 rounded-xl blur-lg opacity-50 group-hover:opacity-70 transition-opacity"></div>
                                    <div className="relative w-[180px] h-[60px] rounded-xl overflow-hidden bg-transparent">
                                        <img src={logo} alt="BizNest" className="w-full h-full object-contain" />
                                    </div>
                                </div>
                            </NavLink>

                            {/* Desktop Nav - Enhanced */}
                            <nav className="hidden md:flex items-center gap-1 bg-gray-50 rounded-2xl p-1.5">
                                {filteredLinks.map(link => (
                                    <NavLink
                                        key={link.to}
                                        to={link.to}
                                        end={link.end}
                                        className={({ isActive }) =>
                                            `flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium transition-all duration-300 ${isActive
                                                ? 'bg-white text-primary-600 shadow-md'
                                                : 'text-gray-500 hover:text-gray-700 hover:bg-white/50'
                                            }`
                                        }
                                    >
                                        <link.icon className="w-5 h-5" />
                                        <span className="text-sm">{link.label}</span>
                                    </NavLink>
                                ))}
                            </nav>

                            {/* Right Actions - Enhanced */}
                            <div className="flex items-center gap-2">
                                {/* Cart Button - Enhanced */}
                                <NavLink
                                    to="/store/cart"
                                    className={({ isActive }) =>
                                        `relative p-3 rounded-xl transition-all duration-300 ${isActive
                                            ? 'bg-primary-50 text-primary-600'
                                            : 'text-gray-600 hover:bg-gray-100'
                                        }`
                                    }
                                >
                                    <HiShoppingCart className="w-6 h-6" />
                                    {cartCount > 0 && (
                                        <span className="absolute -top-1 -right-1 min-w-[22px] h-[22px] bg-gradient-to-r from-red-500 to-red-600 text-white text-xs font-bold rounded-full flex items-center justify-center shadow-lg shadow-red-500/30 px-1">
                                            {cartCount > 99 ? '99+' : cartCount}
                                        </span>
                                    )}
                                </NavLink>

                                {/* Auth Button */}
                                {isAuthenticated ? (
                                    <button
                                        onClick={handleLogout}
                                        className="hidden md:flex items-center gap-2 px-4 py-2.5 text-gray-600 hover:bg-gray-100 rounded-xl transition-all font-medium"
                                    >
                                        <HiLogout className="w-5 h-5" />
                                        <span className="text-sm">Logout</span>
                                    </button>
                                ) : (
                                    <NavLink
                                        to="/login"
                                        className="hidden md:flex items-center gap-2 bg-gradient-to-r from-primary-500 to-primary-600 text-white px-5 py-2.5 rounded-xl font-semibold shadow-lg shadow-primary-500/20 hover:shadow-xl hover:shadow-primary-500/30 transition-all hover:scale-105"
                                    >
                                        <HiLogin className="w-5 h-5" />
                                        Sign In
                                    </NavLink>
                                )}

                                {/* Mobile menu button */}
                                <button
                                    onClick={() => setSidebarOpen(!sidebarOpen)}
                                    className="md:hidden p-3 text-gray-600 hover:bg-gray-100 rounded-xl transition-colors"
                                >
                                    {sidebarOpen ? <HiX className="w-6 h-6" /> : <HiMenuAlt3 className="w-6 h-6" />}
                                </button>
                            </div>
                        </div>
                    </div>
                </header>

                {/* Mobile Sidebar - Enhanced */}
                {sidebarOpen && (
                    <div className="fixed inset-0 z-50 md:hidden">
                        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setSidebarOpen(false)} />
                        <div className="fixed right-0 top-0 h-full w-80 bg-white shadow-2xl">
                            <div className="p-5 border-b bg-gradient-to-r from-primary-500 to-primary-600 text-white">
                                <div className="flex items-center justify-between">
                                    <div>
                                        <span className="font-bold text-lg">Menu</span>
                                        {isAuthenticated && user && (
                                            <p className="text-primary-100 text-sm mt-0.5">Hello, {user.name?.split(' ')[0]}</p>
                                        )}
                                    </div>
                                    <button onClick={() => setSidebarOpen(false)} className="p-2 hover:bg-white/20 rounded-xl transition-colors">
                                        <HiX className="w-6 h-6" />
                                    </button>
                                </div>
                            </div>
                            <nav className="p-4 space-y-2">
                                {filteredLinks.map(link => (
                                    <NavLink
                                        key={link.to}
                                        to={link.to}
                                        end={link.end}
                                        onClick={() => setSidebarOpen(false)}
                                        className={({ isActive }) =>
                                            `flex items-center gap-3 px-4 py-4 rounded-2xl font-medium transition-all ${isActive
                                                ? 'bg-gradient-to-r from-primary-50 to-primary-100 text-primary-600'
                                                : 'text-gray-600 hover:bg-gray-100'
                                            }`
                                        }
                                    >
                                        <link.icon className="w-6 h-6" />
                                        {link.label}
                                    </NavLink>
                                ))}
                                <hr className="my-4" />
                                {isAuthenticated ? (
                                    <button
                                        onClick={() => { handleLogout(); setSidebarOpen(false); }}
                                        className="flex items-center gap-3 px-4 py-4 rounded-2xl font-medium text-red-600 hover:bg-red-50 w-full transition-all"
                                    >
                                        <HiLogout className="w-6 h-6" />
                                        Logout
                                    </button>
                                ) : (
                                    <NavLink
                                        to="/login"
                                        onClick={() => setSidebarOpen(false)}
                                        className="flex items-center justify-center gap-2 bg-gradient-to-r from-primary-500 to-primary-600 text-white px-6 py-4 rounded-2xl font-semibold shadow-lg"
                                    >
                                        <HiLogin className="w-5 h-5" />
                                        Sign In
                                    </NavLink>
                                )}
                            </nav>
                        </div>
                    </div>
                )}

                {/* Main Content */}
                <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                    <Outlet />
                </main>

                {/* Footer - Enhanced */}
                <footer className="bg-gradient-to-br from-gray-900 to-gray-800 text-white mt-16">
                    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                            {/* Brand */}
                            <div>
                                <div className="flex items-center gap-3 mb-4">
                                    <div className="w-[240px] h-[60px] rounded-xl overflow-hidden bg-transparent">
                                        <img src={logo} alt="BizNest" className="w-full h-full object-contain" />
                                    </div>
                                </div>
                                <p className="text-gray-400 text-sm">
                                    Connecting you with the best local businesses and products.
                                </p>
                            </div>

                            {/* Quick Links */}
                            <div>
                                <h4 className="font-semibold mb-4">Quick Links</h4>
                                <div className="space-y-2">
                                    <NavLink to="/store" className="block text-gray-400 hover:text-white transition-colors text-sm">Home</NavLink>
                                    <NavLink to="/store/businesses" className="block text-gray-400 hover:text-white transition-colors text-sm">All Businesses</NavLink>
                                    {isAuthenticated && (
                                        <>
                                            <NavLink to="/store/orders" className="block text-gray-400 hover:text-white transition-colors text-sm">My Orders</NavLink>
                                            <NavLink to="/store/favorites" className="block text-gray-400 hover:text-white transition-colors text-sm">Favorites</NavLink>
                                        </>
                                    )}
                                </div>
                            </div>

                            {/* Contact */}
                            <div>
                                <h4 className="font-semibold mb-4">Support</h4>
                                <div className="space-y-2 text-sm text-gray-400">
                                    <p>Need help? Contact us</p>
                                    <p className="text-primary-400">support@biznest.com</p>
                                </div>
                            </div>
                        </div>

                        <div className="border-t border-gray-700 mt-10 pt-8 text-center text-gray-500 text-sm">
                            © 2026 BizNest. All rights reserved.
                        </div>
                    </div>
                </footer>
            </div>
        </CartContext.Provider>
    );
};

export default CustomerLayout;
