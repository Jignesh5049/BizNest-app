import { createContext, useContext, useState, useEffect } from 'react';
import { authAPI, businessAPI } from '../services/api';

const AuthContext = createContext(null);

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [business, setBusiness] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isAuthenticated, setIsAuthenticated] = useState(false);

    useEffect(() => {
        checkAuth();
    }, []);

    const checkAuth = async () => {
        const token = localStorage.getItem('token');
        if (token) {
            try {
                const { data } = await authAPI.getMe();
                setUser(data);
                setBusiness(data.business);
                setIsAuthenticated(true);
            } catch (error) {
                console.error('Auth check failed:', error);
                logout();
            }
        }
        setLoading(false);
    };

    const login = async (email, password, role = 'business') => {
        try {
            const { data } = await authAPI.login({ email, password, role });
            localStorage.setItem('token', data.token);
            localStorage.setItem('userRole', data.role);
            setUser(data);
            if (data.business) {
                setBusiness(data.business);
            }
            setIsAuthenticated(true);
            return { success: true, data };
        } catch (error) {
            return { success: false, error: error.response?.data?.message || 'Login failed' };
        }
    };

    const signup = async (userData) => {
        try {
            const { data } = await authAPI.signup(userData);
            localStorage.setItem('token', data.token);
            localStorage.setItem('userRole', data.role);
            setUser(data);
            if (data.business) {
                setBusiness(data.business);
            }
            setIsAuthenticated(true);
            return { success: true, data };
        } catch (error) {
            return { success: false, error: error.response?.data?.message || 'Signup failed' };
        }
    };

    const logout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('userRole');
        setUser(null);
        setBusiness(null);
        setIsAuthenticated(false);
    };

    const updateBusiness = async (businessData) => {
        try {
            const { data } = await businessAPI.create(businessData);
            setBusiness(data);
            return { success: true, data };
        } catch (error) {
            return { success: false, error: error.response?.data?.message || 'Update failed' };
        }
    };

    const refreshBusiness = async () => {
        try {
            const { data } = await businessAPI.get();
            setBusiness(data);
        } catch (error) {
            console.error('Failed to refresh business:', error);
        }
    };

    const isBusinessOwner = () => {
        return user?.role === 'business';
    };

    const isCustomer = () => {
        return user?.role === 'customer';
    };

    const value = {
        user,
        business,
        loading,
        isAuthenticated,
        login,
        signup,
        logout,
        updateBusiness,
        refreshBusiness,
        isBusinessOwner,
        isCustomer
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export default AuthContext;
