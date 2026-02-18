import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const CustomerProtectedRoute = ({ children }) => {
    const { isAuthenticated, loading, user } = useAuth();

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    // Allow customers only
    if (user?.role !== 'customer') {
        return <Navigate to="/dashboard" replace />;
    }

    return children;
};

export default CustomerProtectedRoute;
