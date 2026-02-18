import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { storeAPI, authAPI } from '../../services/api';
import {
    HiUser,
    HiMail,
    HiPhone,
    HiLocationMarker,
    HiPencil,
    HiTrash,
    HiPlus,
    HiCheck,
    HiLockClosed,
    HiLogout,
    HiChatAlt2
} from 'react-icons/hi';

const CustomerProfile = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const [addresses, setAddresses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [editMode, setEditMode] = useState(false);
    const [showPasswordForm, setShowPasswordForm] = useState(false);
    const [showAddressForm, setShowAddressForm] = useState(false);
    const [supportReplies, setSupportReplies] = useState([]);
    const [supportLoading, setSupportLoading] = useState(true);

    const [profileData, setProfileData] = useState({
        name: '',
        phone: ''
    });

    const [passwordData, setPasswordData] = useState({
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
    });

    const [newAddress, setNewAddress] = useState({
        label: 'Home',
        street: '',
        city: '',
        state: '',
        pincode: '',
        isDefault: false
    });

    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState('');

    useEffect(() => {
        if (user) {
            setProfileData({
                name: user.name || '',
                phone: user.phone || ''
            });
        }
        fetchAddresses();
        fetchSupportReplies();
    }, [user]);

    const fetchAddresses = async () => {
        try {
            const { data } = await storeAPI.getAddresses();
            setAddresses(data);
        } catch (error) {
            console.error('Failed to fetch addresses:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchSupportReplies = async () => {
        try {
            setSupportLoading(true);
            const { data } = await storeAPI.getSupportTickets();
            setSupportReplies(data.filter(ticket => ticket.replyMessage));
        } catch (error) {
            console.error('Failed to fetch support replies:', error);
        } finally {
            setSupportLoading(false);
        }
    };

    const handleProfileUpdate = async (e) => {
        e.preventDefault();
        setSaving(true);
        setMessage('');

        try {
            await authAPI.updateProfile(profileData);
            setMessage('Profile updated successfully!');
            setEditMode(false);
        } catch (error) {
            setMessage(error.response?.data?.message || 'Failed to update profile');
        } finally {
            setSaving(false);
        }
    };

    const handlePasswordChange = async (e) => {
        e.preventDefault();

        if (passwordData.newPassword !== passwordData.confirmPassword) {
            setMessage('New passwords do not match');
            return;
        }

        setSaving(true);
        setMessage('');

        try {
            await authAPI.updateProfile({
                currentPassword: passwordData.currentPassword,
                newPassword: passwordData.newPassword
            });
            setMessage('Password changed successfully!');
            setShowPasswordForm(false);
            setPasswordData({ currentPassword: '', newPassword: '', confirmPassword: '' });
        } catch (error) {
            setMessage(error.response?.data?.message || 'Failed to change password');
        } finally {
            setSaving(false);
        }
    };

    const handleAddAddress = async (e) => {
        e.preventDefault();
        try {
            const { data } = await storeAPI.addAddress(newAddress);
            setAddresses(data);
            setShowAddressForm(false);
            setNewAddress({ label: 'Home', street: '', city: '', state: '', pincode: '', isDefault: false });
        } catch (error) {
            console.error('Failed to add address:', error);
        }
    };

    const handleDeleteAddress = async (id) => {
        if (!window.confirm('Delete this address?')) return;
        try {
            const { data } = await storeAPI.deleteAddress(id);
            setAddresses(data);
        } catch (error) {
            console.error('Failed to delete address:', error);
        }
    };

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    if (loading) {
        return (
            <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    return (
        <div className="max-w-2xl mx-auto space-y-6">
            <h1 className="text-2xl font-bold text-gray-800">My Profile</h1>

            {/* Success/Error Message */}
            {message && (
                <div className={`p-4 rounded-xl ${message.includes('success') ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
                    {message}
                </div>
            )}

            {/* Profile Info */}
            <div className="card">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                        <HiUser className="w-5 h-5 text-primary-600" />
                        Personal Information
                    </h2>
                    {!editMode && (
                        <button
                            onClick={() => setEditMode(true)}
                            className="text-primary-600 hover:text-primary-700 font-medium text-sm flex items-center gap-1"
                        >
                            <HiPencil className="w-4 h-4" />
                            Edit
                        </button>
                    )}
                </div>

                {editMode ? (
                    <form onSubmit={handleProfileUpdate} className="space-y-4">
                        <div>
                            <label className="label">Full Name</label>
                            <input
                                type="text"
                                value={profileData.name}
                                onChange={(e) => setProfileData({ ...profileData, name: e.target.value })}
                                className="input"
                                required
                            />
                        </div>
                        <div>
                            <label className="label">Phone Number</label>
                            <input
                                type="tel"
                                value={profileData.phone}
                                onChange={(e) => setProfileData({ ...profileData, phone: e.target.value })}
                                className="input"
                            />
                        </div>
                        <div className="flex gap-3">
                            <button type="submit" className="btn-primary py-2" disabled={saving}>
                                {saving ? 'Saving...' : 'Save Changes'}
                            </button>
                            <button
                                type="button"
                                onClick={() => setEditMode(false)}
                                className="btn-secondary py-2"
                            >
                                Cancel
                            </button>
                        </div>
                    </form>
                ) : (
                    <div className="space-y-4">
                        <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                            <HiUser className="w-5 h-5 text-gray-400" />
                            <div>
                                <p className="text-sm text-gray-500">Name</p>
                                <p className="font-medium text-gray-800">{user?.name || '-'}</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                            <HiMail className="w-5 h-5 text-gray-400" />
                            <div>
                                <p className="text-sm text-gray-500">Email</p>
                                <p className="font-medium text-gray-800">{user?.email || '-'}</p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                            <HiPhone className="w-5 h-5 text-gray-400" />
                            <div>
                                <p className="text-sm text-gray-500">Phone</p>
                                <p className="font-medium text-gray-800">{user?.phone || '-'}</p>
                            </div>
                        </div>
                    </div>
                )}
            </div>

            {/* Change Password */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                        <HiLockClosed className="w-5 h-5 text-primary-600" />
                        Password
                    </h2>
                    {!showPasswordForm && (
                        <button
                            onClick={() => setShowPasswordForm(true)}
                            className="text-primary-600 hover:text-primary-700 font-medium text-sm"
                        >
                            Change Password
                        </button>
                    )}
                </div>

                {showPasswordForm && (
                    <form onSubmit={handlePasswordChange} className="space-y-4">
                        <div>
                            <label className="label">Current Password</label>
                            <input
                                type="password"
                                value={passwordData.currentPassword}
                                onChange={(e) => setPasswordData({ ...passwordData, currentPassword: e.target.value })}
                                className="input"
                                required
                            />
                        </div>
                        <div>
                            <label className="label">New Password</label>
                            <input
                                type="password"
                                value={passwordData.newPassword}
                                onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })}
                                className="input"
                                required
                                minLength={6}
                            />
                        </div>
                        <div>
                            <label className="label">Confirm New Password</label>
                            <input
                                type="password"
                                value={passwordData.confirmPassword}
                                onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })}
                                className="input"
                                required
                            />
                        </div>
                        <div className="flex gap-3">
                            <button type="submit" className="btn-primary py-2" disabled={saving}>
                                {saving ? 'Changing...' : 'Change Password'}
                            </button>
                            <button
                                type="button"
                                onClick={() => setShowPasswordForm(false)}
                                className="btn-secondary py-2"
                            >
                                Cancel
                            </button>
                        </div>
                    </form>
                )}
            </div>

            {/* Addresses */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                        <HiLocationMarker className="w-5 h-5 text-primary-600" />
                        Saved Addresses
                    </h2>
                    <button
                        onClick={() => setShowAddressForm(!showAddressForm)}
                        className="text-primary-600 hover:text-primary-700 font-medium text-sm flex items-center gap-1"
                    >
                        <HiPlus className="w-4 h-4" />
                        Add New
                    </button>
                </div>

                {showAddressForm && (
                    <form onSubmit={handleAddAddress} className="bg-gray-50 rounded-xl p-4 mb-4 space-y-3">
                        <div className="grid grid-cols-2 gap-3">
                            <div>
                                <label className="label">Label</label>
                                <select
                                    value={newAddress.label}
                                    onChange={(e) => setNewAddress({ ...newAddress, label: e.target.value })}
                                    className="input"
                                >
                                    <option value="Home">Home</option>
                                    <option value="Work">Work</option>
                                    <option value="Other">Other</option>
                                </select>
                            </div>
                            <div>
                                <label className="label">Pincode</label>
                                <input
                                    type="text"
                                    value={newAddress.pincode}
                                    onChange={(e) => setNewAddress({ ...newAddress, pincode: e.target.value })}
                                    className="input"
                                    required
                                />
                            </div>
                        </div>
                        <div>
                            <label className="label">Street Address</label>
                            <input
                                type="text"
                                value={newAddress.street}
                                onChange={(e) => setNewAddress({ ...newAddress, street: e.target.value })}
                                className="input"
                                required
                            />
                        </div>
                        <div className="grid grid-cols-2 gap-3">
                            <div>
                                <label className="label">City</label>
                                <input
                                    type="text"
                                    value={newAddress.city}
                                    onChange={(e) => setNewAddress({ ...newAddress, city: e.target.value })}
                                    className="input"
                                    required
                                />
                            </div>
                            <div>
                                <label className="label">State</label>
                                <input
                                    type="text"
                                    value={newAddress.state}
                                    onChange={(e) => setNewAddress({ ...newAddress, state: e.target.value })}
                                    className="input"
                                    required
                                />
                            </div>
                        </div>
                        <div className="flex gap-3">
                            <button type="submit" className="btn-primary py-2">Save Address</button>
                            <button type="button" onClick={() => setShowAddressForm(false)} className="btn-secondary py-2">
                                Cancel
                            </button>
                        </div>
                    </form>
                )}

                {addresses.length === 0 ? (
                    <p className="text-gray-500 text-center py-4">No saved addresses</p>
                ) : (
                    <div className="space-y-3">
                        {addresses.map(address => (
                            <div key={address._id} className="flex items-start justify-between p-4 bg-gray-50 rounded-xl">
                                <div>
                                    <div className="flex items-center gap-2 mb-1">
                                        <span className="font-medium text-gray-800">{address.label}</span>
                                        {address.isDefault && (
                                            <span className="text-xs bg-primary-100 text-primary-700 px-2 py-0.5 rounded-full">
                                                Default
                                            </span>
                                        )}
                                    </div>
                                    <p className="text-sm text-gray-600">
                                        {[address.street, address.city, address.state, address.pincode]
                                            .filter(Boolean).join(', ')}
                                    </p>
                                </div>
                                <button
                                    onClick={() => handleDeleteAddress(address._id)}
                                    className="text-red-500 hover:text-red-600 p-2"
                                >
                                    <HiTrash className="w-5 h-5" />
                                </button>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Support Replies */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                        <HiChatAlt2 className="w-5 h-5 text-primary-600" />
                        Support Replies
                    </h2>
                    <button
                        onClick={fetchSupportReplies}
                        className="text-primary-600 hover:text-primary-700 font-medium text-sm"
                    >
                        Refresh
                    </button>
                </div>

                {supportLoading ? (
                    <p className="text-gray-500">Loading replies...</p>
                ) : supportReplies.length === 0 ? (
                    <p className="text-gray-500">No replies yet.</p>
                ) : (
                    <div className="space-y-3">
                        {supportReplies.map(reply => (
                            <div key={reply._id} className="p-4 bg-gray-50 rounded-xl">
                                <div className="flex items-center justify-between mb-2">
                                    <div>
                                        <p className="font-medium text-gray-800">
                                            {reply.orderId?.orderNumber || 'Support Ticket'}
                                        </p>
                                        <p className="text-xs text-gray-500">
                                            {reply.productId?.name || 'General request'}
                                        </p>
                                    </div>
                                    <span className="text-xs text-gray-500">
                                        {reply.repliedAt
                                            ? new Date(reply.repliedAt).toLocaleDateString('en-IN', {
                                                day: 'numeric',
                                                month: 'short',
                                                year: 'numeric'
                                            })
                                            : ''}
                                    </span>
                                </div>
                                <p className="text-sm text-gray-600 whitespace-pre-line">{reply.replyMessage}</p>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Logout */}
            <button
                onClick={handleLogout}
                className="w-full py-3 bg-red-50 text-red-600 rounded-xl font-medium flex items-center justify-center gap-2 hover:bg-red-100 transition-colors"
            >
                <HiLogout className="w-5 h-5" />
                Logout
            </button>
        </div>
    );
};

export default CustomerProfile;
