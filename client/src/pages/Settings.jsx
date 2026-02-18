import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { businessCategories } from '../utils/helpers';
import { HiCog, HiOfficeBuilding, HiPhone, HiMail, HiLocationMarker, HiCheck } from 'react-icons/hi';

const Settings = () => {
    const { business, updateBusiness, user, logout } = useAuth();
    const [loading, setLoading] = useState(false);
    const [saved, setSaved] = useState(false);
    const [formData, setFormData] = useState({
        name: business?.name || '',
        category: business?.category || 'retail',
        description: business?.description || '',
        contact: {
            phone: business?.contact?.phone || '',
            email: business?.contact?.email || '',
            whatsapp: business?.contact?.whatsapp || ''
        },
        address: {
            city: business?.address?.city || '',
            state: business?.address?.state || ''
        },
        socialLinks: {
            instagram: business?.socialLinks?.instagram || '',
            facebook: business?.socialLinks?.facebook || '',
            website: business?.socialLinks?.website || ''
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
        setSaved(false);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        const result = await updateBusiness(formData);

        if (result.success) {
            setSaved(true);
            setTimeout(() => setSaved(false), 3000);
        }
        setLoading(false);
    };

    return (
        <div className="space-y-8 animate-fadeIn max-w-3xl">
            {/* Header */}
            <div className="flex items-center gap-4">
                <div className="p-3 bg-gray-100 rounded-xl">
                    <HiCog className="w-6 h-6 text-gray-600" />
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
                    <p className="text-gray-600">Manage your business profile</p>
                </div>
            </div>

            {/* Business Profile Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
                <div className="card">
                    <h2 className="font-semibold text-gray-900 mb-6 flex items-center gap-2">
                        <HiOfficeBuilding className="w-5 h-5 text-primary-500" />
                        Business Information
                    </h2>

                    <div className="space-y-4">
                        <div>
                            <label className="label">Business Name</label>
                            <input
                                type="text"
                                name="name"
                                value={formData.name}
                                onChange={handleChange}
                                className="input"
                                placeholder="Your Business Name"
                            />
                        </div>

                        <div className="grid md:grid-cols-2 gap-4">
                            <div>
                                <label className="label">Category</label>
                                <select
                                    name="category"
                                    value={formData.category}
                                    onChange={handleChange}
                                    className="input"
                                >
                                    {businessCategories.map(cat => (
                                        <option key={cat.value} value={cat.value}>{cat.label}</option>
                                    ))}
                                </select>
                            </div>
                        </div>

                        <div>
                            <label className="label">Description</label>
                            <textarea
                                name="description"
                                value={formData.description}
                                onChange={handleChange}
                                className="input min-h-[100px]"
                                placeholder="Tell customers about your business..."
                            />
                        </div>
                    </div>
                </div>

                <div className="card">
                    <h2 className="font-semibold text-gray-900 mb-6 flex items-center gap-2">
                        <HiPhone className="w-5 h-5 text-primary-500" />
                        Contact Details
                    </h2>

                    <div className="grid md:grid-cols-2 gap-4">
                        <div>
                            <label className="label">Phone Number</label>
                            <input
                                type="tel"
                                name="contact.phone"
                                value={formData.contact.phone}
                                onChange={handleChange}
                                className="input"
                                placeholder="+91 98765 43210"
                            />
                        </div>
                        <div>
                            <label className="label">WhatsApp Number</label>
                            <input
                                type="tel"
                                name="contact.whatsapp"
                                value={formData.contact.whatsapp}
                                onChange={handleChange}
                                className="input"
                                placeholder="+91 98765 43210"
                            />
                        </div>
                        <div>
                            <label className="label">Business Email</label>
                            <input
                                type="email"
                                name="contact.email"
                                value={formData.contact.email}
                                onChange={handleChange}
                                className="input"
                                placeholder="business@email.com"
                            />
                        </div>
                    </div>
                </div>

                <div className="card">
                    <h2 className="font-semibold text-gray-900 mb-6 flex items-center gap-2">
                        <HiLocationMarker className="w-5 h-5 text-primary-500" />
                        Location
                    </h2>

                    <div className="grid md:grid-cols-2 gap-4">
                        <div>
                            <label className="label">City</label>
                            <input
                                type="text"
                                name="address.city"
                                value={formData.address.city}
                                onChange={handleChange}
                                className="input"
                                placeholder="Mumbai"
                            />
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
                </div>

                <div className="card">
                    <h2 className="font-semibold text-gray-900 mb-6">Social Links</h2>

                    <div className="grid md:grid-cols-2 gap-4">
                        <div>
                            <label className="label">Instagram</label>
                            <input
                                type="url"
                                name="socialLinks.instagram"
                                value={formData.socialLinks.instagram}
                                onChange={handleChange}
                                className="input"
                                placeholder="https://instagram.com/yourbusiness"
                            />
                        </div>
                        <div>
                            <label className="label">Facebook</label>
                            <input
                                type="url"
                                name="socialLinks.facebook"
                                value={formData.socialLinks.facebook}
                                onChange={handleChange}
                                className="input"
                                placeholder="https://facebook.com/yourbusiness"
                            />
                        </div>
                        <div>
                            <label className="label">Website</label>
                            <input
                                type="url"
                                name="socialLinks.website"
                                value={formData.socialLinks.website}
                                onChange={handleChange}
                                className="input"
                                placeholder="https://yourbusiness.com"
                            />
                        </div>
                    </div>
                </div>

                {/* Save Button */}
                <div className="flex items-center gap-4">
                    <button
                        type="submit"
                        disabled={loading}
                        className="btn-primary flex items-center gap-2"
                    >
                        {loading ? 'Saving...' : saved ? (
                            <>
                                <HiCheck className="w-5 h-5" />
                                Saved!
                            </>
                        ) : 'Save Changes'}
                    </button>
                    {saved && (
                        <span className="text-green-600 text-sm">Changes saved successfully!</span>
                    )}
                </div>
            </form>

            {/* Account Info */}
            <div className="card border-red-100">
                <h2 className="font-semibold text-gray-900 mb-4">Account</h2>
                <div className="flex items-center justify-between">
                    <div>
                        <p className="text-gray-900">{user?.name}</p>
                        <p className="text-sm text-gray-500">{user?.email}</p>
                    </div>
                    <button
                        onClick={logout}
                        className="btn-danger"
                    >
                        Logout
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Settings;
