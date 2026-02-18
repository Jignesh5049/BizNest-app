import { useState, useEffect } from 'react';
import { productsAPI, uploadsAPI } from '../services/api';
import { formatCurrency, getStockStatus, calculateMargin } from '../utils/helpers';
import Modal from '../components/Modal';
import {
    HiPlus,
    HiPencil,
    HiTrash,
    HiCube,
    HiSearch,
    HiShare,
    HiExternalLink,
    HiViewGrid,
    HiViewList,
    HiStar
} from 'react-icons/hi';
import { FaWhatsapp } from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { generateWhatsAppLink, generateProductShareMessage } from '../utils/helpers';

const Products = () => {
    const { business } = useAuth();
    const [products, setProducts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingProduct, setEditingProduct] = useState(null);
    const [searchQuery, setSearchQuery] = useState('');
    const viewStorageKey = 'admin-products-view';
    const [viewMode, setViewMode] = useState(() => localStorage.getItem(viewStorageKey) || 'grid');
    const [uploadingImage, setUploadingImage] = useState(false);
    const [uploadError, setUploadError] = useState('');
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        costPrice: '',
        sellingPrice: '',
        stock: '',
        category: '',
        unit: 'piece',
        image: ''
    });

    useEffect(() => {
        fetchProducts();
    }, []);

    useEffect(() => {
        localStorage.setItem(viewStorageKey, viewMode);
    }, [viewMode]);

    const fetchProducts = async () => {
        try {
            const { data } = await productsAPI.getAll();
            setProducts(data);
        } catch (error) {
            console.error('Failed to fetch products:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const payload = {
                ...formData,
                costPrice: parseFloat(formData.costPrice),
                sellingPrice: parseFloat(formData.sellingPrice),
                stock: parseInt(formData.stock) || 0
            };

            if (editingProduct) {
                await productsAPI.update(editingProduct._id, payload);
            } else {
                await productsAPI.create(payload);
            }

            fetchProducts();
            closeModal();
        } catch (error) {
            console.error('Failed to save product:', error);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Are you sure you want to delete this product?')) {
            try {
                await productsAPI.delete(id);
                fetchProducts();
            } catch (error) {
                console.error('Failed to delete product:', error);
            }
        }
    };

    const openEditModal = (product) => {
        setEditingProduct(product);
        setFormData({
            name: product.name,
            description: product.description || '',
            costPrice: product.costPrice,
            sellingPrice: product.sellingPrice,
            stock: product.stock,
            category: product.category || '',
            unit: product.unit || 'piece',
            image: product.image || ''
        });
        setShowModal(true);
    };

    const closeModal = () => {
        setShowModal(false);
        setEditingProduct(null);
        setUploadError('');
        setFormData({
            name: '',
            description: '',
            costPrice: '',
            sellingPrice: '',
            stock: '',
            category: '',
            unit: 'piece',
            image: ''
        });
    };

    const handleImageUpload = async (file) => {
        if (!file) return;
        setUploadingImage(true);
        setUploadError('');

        try {
            const { data } = await uploadsAPI.uploadProductImage(file);
            setFormData((prev) => ({ ...prev, image: data.url }));
        } catch (error) {
            setUploadError(error.response?.data?.message || 'Failed to upload image');
        } finally {
            setUploadingImage(false);
        }
    };

    const shareOnWhatsApp = (product) => {
        const message = generateProductShareMessage(product, business?.name || 'My Business');
        const link = generateWhatsAppLink(business?.contact?.whatsapp || '', message);
        window.open(link, '_blank');
    };

    const filteredProducts = products.filter(p =>
        p.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.category?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6 animate-fadeIn">
            {/* Header */}
            <div className="flex flex-col gap-4">
                {/* Title + View Toggle */}
                <div className="flex items-center justify-between gap-3">
                    <div>
                        <h1 className="text-2xl font-bold text-gray-900">Products</h1>
                        <p className="text-gray-600">{products.length} products in catalog</p>
                    </div>
                    <div className="flex items-center bg-gray-100 rounded-xl p-1 w-fit">
                        <button
                            onClick={() => setViewMode('grid')}
                            className={`p-2 rounded-lg transition-colors ${viewMode === 'grid'
                                ? 'bg-white text-primary-600 shadow'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                            title="Grid view"
                        >
                            <HiViewGrid className="w-5 h-5" />
                        </button>
                        <button
                            onClick={() => setViewMode('list')}
                            className={`p-2 rounded-lg transition-colors ${viewMode === 'list'
                                ? 'bg-white text-primary-600 shadow'
                                : 'text-gray-500 hover:text-gray-700'
                                }`}
                            title="List view"
                        >
                            <HiViewList className="w-5 h-5" />
                        </button>
                    </div>
                </div>
                {/* Controls */}
                <div className="flex flex-col sm:flex-row sm:flex-wrap gap-3 w-full">
                    <div className="relative w-full sm:w-64">
                        <HiSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search products..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="input pl-10 w-full"
                        />
                    </div>
                    <button onClick={() => setShowModal(true)} className="btn-primary flex items-center justify-center gap-2 w-full sm:w-auto">
                        <HiPlus className="w-5 h-5" />
                        Add Product
                    </button>
                </div>
            </div>

            {/* Products Grid */}
            {filteredProducts.length === 0 ? (
                <div className="card text-center py-12">
                    <HiCube className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No products yet</h3>
                    <p className="text-gray-500 mb-4">Start by adding your first product</p>
                    <button onClick={() => setShowModal(true)} className="btn-primary">
                        Add Product
                    </button>
                </div>
            ) : (
                viewMode === 'grid' ? (
                    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filteredProducts.map((product) => {
                            const stockStatus = getStockStatus(product.stock);
                            const margin = calculateMargin(product.costPrice, product.sellingPrice);

                            return (
                                <div key={product._id} className="card hover:shadow-card-hover group">
                                    <div className="flex items-start justify-between mb-4">
                                        <div className="flex items-center gap-3">
                                            <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
                                                <HiCube className="w-6 h-6 text-primary-600" />
                                            </div>
                                            <div>
                                                <h3 className="font-semibold text-gray-900">{product.name}</h3>
                                                {product.category && (
                                                    <p className="text-sm text-gray-500">{product.category}</p>
                                                )}
                                            </div>
                                        </div>
                                        <span className={`badge ${stockStatus.color}`}>{stockStatus.label}</span>
                                    </div>

                                    {product.description && (
                                        <p className="text-sm text-gray-600 mb-4 line-clamp-2">{product.description}</p>
                                    )}

                                    <div className="grid grid-cols-2 gap-4 mb-4">
                                        <div>
                                            <p className="text-xs text-gray-500 uppercase tracking-wider">Selling Price</p>
                                            <p className="text-lg font-bold text-gray-900">{formatCurrency(product.sellingPrice)}</p>
                                        </div>
                                        <div>
                                            <p className="text-xs text-gray-500 uppercase tracking-wider">Stock</p>
                                            <p className="text-lg font-bold text-gray-900">{product.stock} {product.unit}</p>
                                        </div>
                                    </div>

                                    <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                                        <span>Cost: {formatCurrency(product.costPrice)}</span>
                                        <span className="text-green-600 font-medium">+{margin}% margin</span>
                                    </div>

                                    <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
                                        <HiStar className={`w-4 h-4 ${product.ratingAverage > 0 ? 'text-yellow-400' : 'text-gray-300'}`} />
                                        <span>
                                            {product.ratingCount > 0
                                                ? `${product.ratingAverage?.toFixed(1)} (${product.ratingCount})`
                                                : 'No ratings yet'}
                                        </span>
                                    </div>

                                    <div className="flex items-center gap-2 pt-4 border-t border-gray-100">
                                        <button
                                            onClick={() => openEditModal(product)}
                                            className="flex-1 btn-secondary py-2 flex items-center justify-center gap-2"
                                        >
                                            <HiPencil className="w-4 h-4" />
                                            Edit
                                        </button>
                                        <button
                                            onClick={() => shareOnWhatsApp(product)}
                                            className="p-2 bg-green-50 text-green-600 rounded-xl hover:bg-green-100 transition-colors"
                                            title="Share on WhatsApp"
                                        >
                                            <FaWhatsapp className="w-5 h-5" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(product._id)}
                                            className="p-2 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors"
                                            title="Delete"
                                        >
                                            <HiTrash className="w-5 h-5" />
                                        </button>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                ) : (
                    <div className="card p-0 overflow-x-auto">
                        <table className="min-w-full text-sm">
                            <thead className="bg-gray-50 text-gray-500">
                                <tr>
                                    <th className="text-left px-4 py-3 font-medium">Product</th>
                                    <th className="text-left px-4 py-3 font-medium">Price</th>
                                    <th className="text-left px-4 py-3 font-medium">Stock</th>
                                    <th className="text-left px-4 py-3 font-medium">Rating</th>
                                    <th className="text-left px-4 py-3 font-medium">Margin</th>
                                    <th className="text-right px-4 py-3 font-medium">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredProducts.map((product) => {
                                    const stockStatus = getStockStatus(product.stock);
                                    const margin = calculateMargin(product.costPrice, product.sellingPrice);

                                    return (
                                        <tr key={product._id} className="border-t">
                                            <td className="px-4 py-3">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                                                        <HiCube className="w-5 h-5 text-primary-600" />
                                                    </div>
                                                    <div>
                                                        <p className="font-medium text-gray-900">{product.name}</p>
                                                        {product.category && (
                                                            <p className="text-xs text-gray-500">{product.category}</p>
                                                        )}
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="px-4 py-3 text-gray-700">{formatCurrency(product.sellingPrice)}</td>
                                            <td className="px-4 py-3">
                                                <div className="flex items-center gap-2">
                                                    <span className="text-gray-700">{product.stock} {product.unit}</span>
                                                    <span className={`badge ${stockStatus.color}`}>{stockStatus.label}</span>
                                                </div>
                                            </td>
                                            <td className="px-4 py-3 text-gray-700">
                                                {product.ratingCount > 0
                                                    ? `${product.ratingAverage?.toFixed(1)} (${product.ratingCount})`
                                                    : '—'}
                                            </td>
                                            <td className="px-4 py-3 text-green-600 font-medium">+{margin}%</td>
                                            <td className="px-4 py-3">
                                                <div className="flex items-center justify-end gap-2">
                                                    <button
                                                        onClick={() => openEditModal(product)}
                                                        className="btn-secondary py-2 px-3"
                                                    >
                                                        <HiPencil className="w-4 h-4" />
                                                    </button>
                                                    <button
                                                        onClick={() => shareOnWhatsApp(product)}
                                                        className="p-2 bg-green-50 text-green-600 rounded-xl hover:bg-green-100 transition-colors"
                                                        title="Share on WhatsApp"
                                                    >
                                                        <FaWhatsapp className="w-5 h-5" />
                                                    </button>
                                                    <button
                                                        onClick={() => handleDelete(product._id)}
                                                        className="p-2 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors"
                                                        title="Delete"
                                                    >
                                                        <HiTrash className="w-5 h-5" />
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )
            )}

            {/* Add/Edit Modal */}
            <Modal
                isOpen={showModal}
                onClose={closeModal}
                title={editingProduct ? 'Edit Product' : 'Add New Product'}
                size="md"
            >
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="label">Product Name *</label>
                        <input
                            type="text"
                            value={formData.name}
                            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                            className="input"
                            placeholder="Enter product name"
                            required
                        />
                    </div>

                    <div>
                        <label className="label">Description</label>
                        <textarea
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            className="input min-h-[80px]"
                            placeholder="Product description..."
                        />
                    </div>

                    <div>
                        <label className="label">Product Image URL</label>
                        <input
                            type="url"
                            value={formData.image}
                            onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                            className="input"
                            placeholder="https://example.com/image.jpg"
                        />
                    </div>

                    <div>
                        <label className="label">Upload Image</label>
                        <div className="flex flex-col sm:flex-row sm:items-center gap-3">
                            <input
                                type="file"
                                accept="image/*"
                                onChange={(e) => handleImageUpload(e.target.files?.[0])}
                                className="input"
                            />
                            {uploadingImage && (
                                <span className="text-sm text-gray-500">Uploading...</span>
                            )}
                        </div>
                        {uploadError && (
                            <p className="text-sm text-red-600 mt-2">{uploadError}</p>
                        )}
                        {formData.image && (
                            <div className="mt-3 w-24 h-24 rounded-xl overflow-hidden border border-gray-200">
                                <img
                                    src={formData.image}
                                    alt="Product preview"
                                    className="w-full h-full object-cover"
                                />
                            </div>
                        )}
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="label">Cost Price *</label>
                            <input
                                type="number"
                                value={formData.costPrice}
                                onChange={(e) => setFormData({ ...formData, costPrice: e.target.value })}
                                className="input"
                                placeholder="0"
                                min="0"
                                step="0.01"
                                required
                            />
                        </div>
                        <div>
                            <label className="label">Selling Price *</label>
                            <input
                                type="number"
                                value={formData.sellingPrice}
                                onChange={(e) => setFormData({ ...formData, sellingPrice: e.target.value })}
                                className="input"
                                placeholder="0"
                                min="0"
                                step="0.01"
                                required
                            />
                        </div>
                    </div>

                    {formData.costPrice && formData.sellingPrice && (
                        <div className="bg-green-50 border border-green-200 rounded-xl p-3 text-center">
                            <span className="text-green-800 font-medium">
                                Profit Margin: {calculateMargin(parseFloat(formData.costPrice), parseFloat(formData.sellingPrice))}%
                            </span>
                        </div>
                    )}

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="label">Stock Quantity</label>
                            <input
                                type="number"
                                value={formData.stock}
                                onChange={(e) => setFormData({ ...formData, stock: e.target.value })}
                                className="input"
                                placeholder="0"
                                min="0"
                            />
                        </div>
                        <div>
                            <label className="label">Unit</label>
                            <select
                                value={formData.unit}
                                onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                                className="input"
                            >
                                <option value="piece">Piece</option>
                                <option value="kg">Kilogram</option>
                                <option value="g">Gram</option>
                                <option value="l">Liter</option>
                                <option value="ml">Milliliter</option>
                                <option value="dozen">Dozen</option>
                                <option value="box">Box</option>
                                <option value="pack">Pack</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label className="label">Category</label>
                        <input
                            type="text"
                            value={formData.category}
                            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                            className="input"
                            placeholder="e.g., Electronics, Food, Clothing"
                        />
                    </div>

                    <div className="flex gap-3 pt-4">
                        <button type="button" onClick={closeModal} className="flex-1 btn-secondary">
                            Cancel
                        </button>
                        <button type="submit" className="flex-1 btn-primary">
                            {editingProduct ? 'Update Product' : 'Add Product'}
                        </button>
                    </div>
                </form>
            </Modal>
        </div>
    );
};

export default Products;
