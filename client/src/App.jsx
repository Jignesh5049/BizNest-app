import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import CustomerProtectedRoute from './components/CustomerProtectedRoute';
import Layout from './components/Layout';
import CustomerLayout from './components/customer/CustomerLayout';

// Auth Pages
import Login from './pages/Login';
import Signup from './pages/Signup';
import Onboarding from './pages/Onboarding';

// Business App Pages
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Orders from './pages/Orders';
import Customers from './pages/Customers';
import Expenses from './pages/Expenses';
import Analytics from './pages/Analytics';
import Pricing from './pages/Pricing';
import Invoices from './pages/Invoices';
import Learn from './pages/Learn';
import Settings from './pages/Settings';
import SupportInbox from './pages/SupportInbox';

// Customer Pages
import CustomerSignup from './pages/customer/CustomerSignup';
import CustomerHome from './pages/customer/CustomerHome';
import BusinessStore from './pages/customer/BusinessStore';
import AllBusinesses from './pages/customer/AllBusinesses';
import ProductDetails from './pages/customer/ProductDetails';
import Cart from './pages/customer/Cart';
import Checkout from './pages/customer/Checkout';
import CustomerOrders from './pages/customer/CustomerOrders';
import OrderDetails from './pages/customer/OrderDetails';
import Favorites from './pages/customer/Favorites';
import CustomerProfile from './pages/customer/CustomerProfile';

function App() {
    return (
        <AuthProvider>
            <Router>
                <Routes>
                    {/* Public Routes */}
                    <Route path="/login" element={<Login />} />
                    <Route path="/signup" element={<Signup />} />
                    <Route path="/customer-signup" element={<CustomerSignup />} />

                    {/* Onboarding - Protected but no layout */}
                    <Route
                        path="/onboarding"
                        element={
                            <ProtectedRoute>
                                <Onboarding />
                            </ProtectedRoute>
                        }
                    />

                    {/* Business Owner Protected Routes with Layout */}
                    <Route
                        path="/"
                        element={
                            <ProtectedRoute>
                                <Layout />
                            </ProtectedRoute>
                        }
                    >
                        <Route index element={<Navigate to="/dashboard" replace />} />
                        <Route path="dashboard" element={<Dashboard />} />
                        <Route path="products" element={<Products />} />
                        <Route path="orders" element={<Orders />} />
                        <Route path="customers" element={<Customers />} />
                        <Route path="expenses" element={<Expenses />} />
                        <Route path="analytics" element={<Analytics />} />
                        <Route path="pricing" element={<Pricing />} />
                        <Route path="invoices" element={<Invoices />} />
                        <Route path="learn" element={<Learn />} />
                        <Route path="support" element={<SupportInbox />} />
                        <Route path="settings" element={<Settings />} />
                    </Route>

                    {/* Customer Portal Routes */}
                    <Route path="/store" element={<CustomerLayout />}>
                        {/* Public customer routes */}
                        <Route index element={<CustomerHome />} />
                        <Route path="businesses" element={<AllBusinesses />} />
                        <Route path="business/:id" element={<BusinessStore />} />
                        <Route path="product/:id" element={<ProductDetails />} />
                        <Route path="cart" element={<Cart />} />

                        {/* Protected customer routes */}
                        <Route path="checkout" element={
                            <CustomerProtectedRoute><Checkout /></CustomerProtectedRoute>
                        } />
                        <Route path="orders" element={
                            <CustomerProtectedRoute><CustomerOrders /></CustomerProtectedRoute>
                        } />
                        <Route path="orders/:id" element={
                            <CustomerProtectedRoute><OrderDetails /></CustomerProtectedRoute>
                        } />
                        <Route path="favorites" element={
                            <CustomerProtectedRoute><Favorites /></CustomerProtectedRoute>
                        } />
                        <Route path="profile" element={
                            <CustomerProtectedRoute><CustomerProfile /></CustomerProtectedRoute>
                        } />
                    </Route>

                    {/* Catch all */}
                    <Route path="*" element={<Navigate to="/login" replace />} />
                </Routes>
            </Router>
        </AuthProvider>
    );
}

export default App;
