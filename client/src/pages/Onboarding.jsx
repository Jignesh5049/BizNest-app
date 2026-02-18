import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { businessCategories } from '../utils/helpers';
import { HiOfficeBuilding, HiPhone, HiMail, HiLocationMarker } from 'react-icons/hi';

const Onboarding = () => {
    const { user, updateBusiness } = useAuth();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const [formData, setFormData] = useState({
        name: '',
        category: 'retail',
        description: '',
        contact: {
            phone: '',
            email: user?.email || '',
            whatsapp: ''
        },
        address: {
            city: '',
            state: ''
        }
    });

    const handleChange = (e) => {
        const { name, value } = e.target;
        if (name.includes('.')) {
            const [parent, child] = name.split('.');
            setFormData(prev => ({
                ...prev,
                [parent]: { ...prev[parent], [child]: value }
            }));
        } else {
            setFormData(prev => ({ ...prev, [name]: value }));
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);

        const result = await updateBusiness(formData);

        if (result.success) {
            navigate('/dashboard');
        } else {
            setError(result.error);
        }
        setLoading(false);
    };

    return (
        <div className="min-h-screen bg-gray-50 py-12 px-4">
            <div className="max-w-2xl mx-auto">
                {/* Header */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl shadow-lg mb-4">
                        <span className="text-white font-bold text-3xl">B</span>
                    </div>
                    <h1 className="text-3xl font-bold text-gray-900">Set Up Your Business</h1>
                    <p className="text-gray-600 mt-2">Let's get your business profile ready</p>
                </div>

                {/* Form */}
                <div className="bg-white rounded-2xl shadow-lg p-8">
                    <form onSubmit={handleSubmit} className="space-y-6">
                        {error && (
                            <div className="bg-red-50 text-red-600 p-4 rounded-xl text-sm">
                                {error}
                            </div>
                        )}

                        {/* Business Name */}
                        <div>
                            <label className="label">Business Name *</label>
                            <div className="relative">
                                <HiOfficeBuilding className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type="text"
                                    name="name"
                                    value={formData.name}
                                    onChange={handleChange}
                                    className="input pl-12"
                                    placeholder="My Awesome Business"
                                    required
                                />
                            </div>
                        </div>

                        {/* Category */}
                        <div>
                            <label className="label">Business Category *</label>
                            <select
                                name="category"
                                value={formData.category}
                                onChange={handleChange}
                                className="input"
                                required
                            >
                                {businessCategories.map(cat => (
                                    <option key={cat.value} value={cat.value}>{cat.label}</option>
                                ))}
                            </select>
                        </div>

                        {/* Description */}
                        <div>
                            <label className="label">Description</label>
                            <textarea
                                name="description"
                                value={formData.description}
                                onChange={handleChange}
                                className="input min-h-[100px]"
                                placeholder="Tell us about your business..."
                            />
                        </div>

                        {/* Contact Details */}
                        <div className="grid md:grid-cols-2 gap-4">
                            <div>
                                <label className="label">Phone Number</label>
                                <div className="relative">
                                    <HiPhone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                    <input
                                        type="tel"
                                        name="contact.phone"
                                        value={formData.contact.phone}
                                        onChange={handleChange}
                                        className="input pl-12"
                                        placeholder="+91 98765 43210"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="label">WhatsApp Number</label>
                                <div className="relative">
                                    <HiPhone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                    <input
                                        type="tel"
                                        name="contact.whatsapp"
                                        value={formData.contact.whatsapp}
                                        onChange={handleChange}
                                        className="input pl-12"
                                        placeholder="+91 98765 43210"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Location */}
                        <div className="grid md:grid-cols-2 gap-4">
                            <div>
                                <label className="label">City</label>
                                <div className="relative">
                                    <HiLocationMarker className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                    <input
                                        type="text"
                                        name="address.city"
                                        value={formData.address.city}
                                        onChange={handleChange}
                                        className="input pl-12"
                                        placeholder="Mumbai"
                                    />
                                </div>
                            </div>
                            <div>
                                <label className="label">State</label>
                                <input
                                    type="text"
                                    name="address.state"
                                    value={formData.address.state}
                                    onChange={handleChange}
                                    className="input"
                                    placeholder="Maharashtra"
                                />
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="btn-primary w-full py-3 disabled:opacity-50"
                        >
                            {loading ? 'Setting up...' : 'Complete Setup'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default Onboarding;
