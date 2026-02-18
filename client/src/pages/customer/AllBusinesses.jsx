import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { HiSearch, HiLocationMarker, HiPhone, HiArrowLeft } from 'react-icons/hi';
import { FaWhatsapp } from 'react-icons/fa';

const categories = [
    { value: 'all', label: 'All Categories' },
    { value: 'retail', label: 'Retail' },
    { value: 'food', label: 'Food & Bakery' },
    { value: 'services', label: 'Services' },
    { value: 'handmade', label: 'Handmade' },
    { value: 'consulting', label: 'Consulting' },
    { value: 'other', label: 'Other' }
];

const AllBusinesses = () => {
    const [businesses, setBusinesses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedCategory, setSelectedCategory] = useState('all');

    useEffect(() => {
        fetchBusinesses();
    }, [selectedCategory]);

    const fetchBusinesses = async () => {
        try {
            setLoading(true);
            const params = {};
            if (selectedCategory !== 'all') params.category = selectedCategory;
            if (searchQuery) params.search = searchQuery;

            const { data } = await storeAPI.getBusinesses(params);
            setBusinesses(data);
        } catch (error) {
            console.error('Failed to fetch businesses:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = (e) => {
        e.preventDefault();
        fetchBusinesses();
    };

    const getCategoryLabel = (value) => {
        return categories.find(c => c.value === value)?.label || value;
    };

    return (
        <div className="space-y-6">
            {/* Back Button */}
            <Link to="/store" className="inline-flex items-center gap-2 text-gray-600 hover:text-primary-600 transition-colors">
                <HiArrowLeft className="w-5 h-5" />
                Back to Home
            </Link>

            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <h1 className="text-2xl font-bold text-gray-800">All Businesses</h1>

                {/* Search Bar */}
                <form onSubmit={handleSearch} className="flex gap-2 max-w-md">
                    <div className="relative flex-1">
                        <HiSearch className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input
                            type="text"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            placeholder="Search businesses..."
                            className="input pl-12"
                        />
                    </div>
                    <button type="submit" className="btn-primary">
                        Search
                    </button>
                </form>
            </div>

            {/* Category Filters */}
            <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
                {categories.map(category => (
                    <button
                        key={category.value}
                        onClick={() => setSelectedCategory(category.value)}
                        className={`px-4 py-2 rounded-full font-medium whitespace-nowrap transition-colors ${selectedCategory === category.value
                                ? 'bg-primary-600 text-white'
                                : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
                            }`}
                    >
                        {category.label}
                    </button>
                ))}
            </div>

            {/* Businesses Grid */}
            {loading ? (
                <div className="flex justify-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
                </div>
            ) : businesses.length === 0 ? (
                <div className="text-center py-12 bg-white rounded-2xl">
                    <div className="text-6xl mb-4">🏪</div>
                    <h3 className="text-xl font-semibold text-gray-800 mb-2">No Businesses Found</h3>
                    <p className="text-gray-500">Try adjusting your search or filters</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                    {businesses.map(business => (
                        <Link
                            key={business._id}
                            to={`/store/business/${business._id}`}
                            className="card hover:shadow-xl transition-all duration-300 group"
                        >
                            {/* Business Logo */}
                            <div className="w-16 h-16 bg-gradient-to-br from-primary-100 to-primary-200 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-105 transition-transform">
                                {business.logo ? (
                                    <img src={business.logo} alt={business.name} className="w-12 h-12 object-contain rounded-xl" />
                                ) : (
                                    <span className="text-2xl font-bold text-primary-600">
                                        {business.name?.charAt(0)?.toUpperCase()}
                                    </span>
                                )}
                            </div>

                            {/* Business Info */}
                            <h3 className="text-lg font-semibold text-gray-800 mb-1 group-hover:text-primary-600 transition-colors">
                                {business.name}
                            </h3>

                            <span className="inline-block px-3 py-1 bg-primary-50 text-primary-700 text-sm font-medium rounded-full mb-3">
                                {getCategoryLabel(business.category)}
                            </span>

                            {business.description && (
                                <p className="text-gray-500 text-sm mb-4 line-clamp-2">
                                    {business.description}
                                </p>
                            )}

                            {/* Contact Info */}
                            <div className="space-y-2 text-sm text-gray-500">
                                {business.address?.city && (
                                    <div className="flex items-center gap-2">
                                        <HiLocationMarker className="w-4 h-4 text-gray-400" />
                                        <span>{business.address.city}{business.address.state ? `, ${business.address.state}` : ''}</span>
                                    </div>
                                )}
                                {business.contact?.phone && (
                                    <div className="flex items-center gap-2">
                                        <HiPhone className="w-4 h-4 text-gray-400" />
                                        <span>{business.contact.phone}</span>
                                    </div>
                                )}
                            </div>

                            {/* WhatsApp Button */}
                            {business.contact?.whatsapp && (
                                <a
                                    href={`https://wa.me/${business.contact.whatsapp.replace(/\D/g, '')}`}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    onClick={(e) => e.stopPropagation()}
                                    className="mt-4 flex items-center justify-center gap-2 w-full py-2 bg-green-500 text-white rounded-xl hover:bg-green-600 transition-colors"
                                >
                                    <FaWhatsapp className="w-5 h-5" />
                                    WhatsApp
                                </a>
                            )}
                        </Link>
                    ))}
                </div>
            )}
        </div>
    );
};

export default AllBusinesses;
