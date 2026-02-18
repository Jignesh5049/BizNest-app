import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import logo from '../assets/logo.svg';
import {
    HiHome,
    HiCube,
    HiShoppingCart,
    HiUsers,
    HiCurrencyRupee,
    HiChartBar,
    HiCalculator,
    HiDocumentText,
    HiAcademicCap,
    HiCog,
    HiChatAlt2,
    HiLogout
} from 'react-icons/hi';

const navItems = [
    { path: '/dashboard', icon: HiHome, label: 'Dashboard' },
    { path: '/products', icon: HiCube, label: 'Products' },
    { path: '/orders', icon: HiShoppingCart, label: 'Orders' },
    { path: '/customers', icon: HiUsers, label: 'Customers' },
    { path: '/expenses', icon: HiCurrencyRupee, label: 'Expenses' },
    { path: '/analytics', icon: HiChartBar, label: 'Analytics' },
    { path: '/pricing', icon: HiCalculator, label: 'Pricing Tool' },
    { path: '/invoices', icon: HiDocumentText, label: 'Invoices' },
    { path: '/learn', icon: HiAcademicCap, label: 'Learn' },
];

const Sidebar = ({ onClose }) => {
    const { business, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const handleNavClick = () => {
        if (onClose) onClose();
    };

    return (
        <aside className="h-screen w-64 bg-white border-r border-gray-200 flex flex-col z-50 overflow-y-auto">
            {/* Logo */}
            <div className="p-6 border-b border-gray-100">
                <div className="flex items-center gap-3">
                    <div className="w-[180px] h-[60px] rounded-xl overflow-hidden flex items-center justify-center bg-transparent">
                        <img src={logo} alt="BizNest" className="w-full h-full object-contain" />
                    </div>
                </div>
            </div>

            {/* Navigation */}
            <nav className="flex-1 p-4 overflow-y-auto">
                <ul className="space-y-1">
                    {navItems.map((item) => (
                        <li key={item.path}>
                            <NavLink
                                to={item.path}
                                onClick={handleNavClick}
                                className={({ isActive }) =>
                                    isActive ? 'sidebar-link-active' : 'sidebar-link'
                                }
                            >
                                <item.icon className="w-5 h-5" />
                                <span>{item.label}</span>
                            </NavLink>
                        </li>
                    ))}
                </ul>
            </nav>

            {/* Bottom section */}
            <div className="p-4 border-t border-gray-100">
                <NavLink
                    to="/support"
                    className={({ isActive }) =>
                        isActive ? 'sidebar-link-active' : 'sidebar-link'
                    }
                >
                    <HiChatAlt2 className="w-5 h-5" />
                    <span>Support</span>
                </NavLink>
                <NavLink
                    to="/settings"
                    className={({ isActive }) =>
                        isActive ? 'sidebar-link-active' : 'sidebar-link'
                    }
                >
                    <HiCog className="w-5 h-5" />
                    <span>Settings</span>
                </NavLink>
                <button
                    onClick={handleLogout}
                    className="sidebar-link w-full text-red-600 hover:bg-red-50 hover:text-red-700 mt-1"
                >
                    <HiLogout className="w-5 h-5" />
                    <span>Logout</span>
                </button>
            </div>
        </aside>
    );
};

export default Sidebar;
