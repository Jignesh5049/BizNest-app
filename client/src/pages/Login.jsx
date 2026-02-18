import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { HiMail, HiLockClosed, HiEye, HiEyeOff, HiOfficeBuilding, HiUser } from 'react-icons/hi';
import logo from '../assets/logo.svg';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [selectedRole, setSelectedRole] = useState('business');
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        const result = await login(email, password, selectedRole);

        if (result.success) {
            if (result.data.role === 'customer') {
                navigate('/store');
            } else {
                navigate('/dashboard');
            }
        } else {
            setError(result.error);
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-primary-500 via-primary-600 to-primary-700 flex items-center justify-center p-4">
            <div className="w-full max-w-md">
                {/* Logo */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-[240px] h-[60px] bg-transparent rounded-xl mb-4">
                        <img src={logo} alt="BizNest" className="w-full h-full object-contain" />
                    </div>
                    <h1 className="text-3xl font-bold text-white">Welcome Back</h1>
                    <p className="text-primary-100 mt-2">Sign in to continue to BizNest</p>
                </div>

                {/* Role Selection Tabs */}
                <div className="flex bg-white/20 rounded-xl p-1 mb-6">
                    <button
                        type="button"
                        onClick={() => setSelectedRole('business')}
                        className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium transition-all duration-200 ${selectedRole === 'business'
                            ? 'bg-white text-primary-600 shadow-md'
                            : 'text-white hover:bg-white/10'
                            }`}
                    >
                        <HiOfficeBuilding className="w-5 h-5" />
                        Business Owner
                    </button>
                    <button
                        type="button"
                        onClick={() => setSelectedRole('customer')}
                        className={`flex-1 flex items-center justify-center gap-2 py-3 px-4 rounded-lg font-medium transition-all duration-200 ${selectedRole === 'customer'
                            ? 'bg-white text-primary-600 shadow-md'
                            : 'text-white hover:bg-white/10'
                            }`}
                    >
                        <HiUser className="w-5 h-5" />
                        Customer
                    </button>
                </div>

                {/* Form */}
                <div className="bg-white rounded-2xl shadow-xl p-8">
                    <form onSubmit={handleSubmit} className="space-y-5">
                        {error && (
                            <div className="bg-red-50 text-red-600 p-4 rounded-xl text-sm">
                                {error}
                            </div>
                        )}

                        <div>
                            <label className="label">Email</label>
                            <div className="relative">
                                <HiMail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type="email"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    className="input pl-12"
                                    placeholder="you@example.com"
                                    required
                                />
                            </div>
                        </div>

                        <div>
                            <label className="label">Password</label>
                            <div className="relative">
                                <HiLockClosed className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="input pl-12 pr-12"
                                    placeholder="••••••••"
                                    required
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                                >
                                    {showPassword ? <HiEyeOff className="w-5 h-5" /> : <HiEye className="w-5 h-5" />}
                                </button>
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="btn-primary w-full py-3 disabled:opacity-50"
                        >
                            {loading ? 'Signing in...' : `Sign In as ${selectedRole === 'business' ? 'Business Owner' : 'Customer'}`}
                        </button>
                    </form>

                    <p className="mt-6 text-center text-gray-600">
                        Don't have an account?{' '}
                        <Link
                            to={selectedRole === 'customer' ? '/customer-signup' : '/signup'}
                            className="text-primary-600 font-medium hover:underline"
                        >
                            Sign up
                        </Link>
                    </p>
                </div>
            </div>
        </div>
    );
};

export default Login;
