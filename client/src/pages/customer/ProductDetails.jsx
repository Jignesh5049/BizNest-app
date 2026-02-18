import { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { storeAPI } from '../../services/api';
import { useCart } from '../../components/customer/CustomerLayout';
import { useAuth } from '../../context/AuthContext';
import { formatCurrency } from '../../utils/helpers';
import {
    HiArrowLeft,
    HiPlus,
    HiMinus,
    HiHeart,
    HiShoppingCart,
    HiCheck,
    HiStar
} from 'react-icons/hi';
import { FaWhatsapp } from 'react-icons/fa';

const ProductDetails = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const [product, setProduct] = useState(null);
    const [loading, setLoading] = useState(true);
    const [quantity, setQuantity] = useState(1);
    const [addedToCart, setAddedToCart] = useState(false);
    const [isFavorite, setIsFavorite] = useState(false);
    const [reviews, setReviews] = useState([]);
    const [reviewsLoading, setReviewsLoading] = useState(true);
    const [reviewEligibility, setReviewEligibility] = useState({ canReview: false, reason: '' });
    const [reviewForm, setReviewForm] = useState({ rating: 0, comment: '' });
    const [reviewMessage, setReviewMessage] = useState('');
    const { addToCart, cart } = useCart();
    const { isAuthenticated } = useAuth();

    useEffect(() => {
        fetchProduct();
    }, [id]);

    useEffect(() => {
        fetchReviews();
        if (isAuthenticated) {
            fetchReviewEligibility();
        }
    }, [id, isAuthenticated]);

    const fetchProduct = async () => {
        try {
            setLoading(true);
            const { data } = await storeAPI.getProduct(id);
            setProduct(data);
        } catch (error) {
            console.error('Failed to fetch product:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchReviews = async () => {
        try {
            setReviewsLoading(true);
            const { data } = await storeAPI.getProductReviews(id);
            setReviews(data);
        } catch (error) {
            console.error('Failed to fetch reviews:', error);
        } finally {
            setReviewsLoading(false);
        }
    };

    const fetchReviewEligibility = async () => {
        try {
            const { data } = await storeAPI.getReviewEligibility(id);
            setReviewEligibility(data);
        } catch (error) {
            console.error('Failed to fetch review eligibility:', error);
        }
    };

    const handleAddToCart = () => {
        if (product) {
            addToCart(product, quantity, product.businessId._id);
            setAddedToCart(true);
            setTimeout(() => setAddedToCart(false), 2000);
        }
    };

    const handleToggleFavorite = async () => {
        if (!isAuthenticated) {
            navigate('/login');
            return;
        }
        try {
            if (isFavorite) {
                await storeAPI.removeFavorite(id);
            } else {
                await storeAPI.addFavorite(id);
            }
            setIsFavorite(!isFavorite);
        } catch (error) {
            console.error('Failed to update favorites:', error);
        }
    };

    const handleReviewSubmit = async (e) => {
        e.preventDefault();
        setReviewMessage('');

        if (!reviewForm.rating) {
            setReviewMessage('Please select a rating.');
            return;
        }

        try {
            await storeAPI.createReview(id, {
                rating: reviewForm.rating,
                comment: reviewForm.comment
            });
            setReviewMessage('Thanks for your review!');
            setReviewForm({ rating: 0, comment: '' });
            setReviewEligibility({ canReview: false, reason: 'Already reviewed' });
            fetchReviews();
        } catch (error) {
            setReviewMessage(error.response?.data?.message || 'Failed to submit review');
        }
    };

    const isInCart = cart.some(item => item.productId === id);
    const averageRating = reviews.length
        ? (reviews.reduce((sum, review) => sum + review.rating, 0) / reviews.length).toFixed(1)
        : '0.0';
    const reviewReasonText = {
        'Purchase required': 'Only customers with a completed purchase can leave a review.',
        'Already reviewed': 'You have already reviewed this product.'
    };

    if (loading) {
        return (
            <div className="flex justify-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
            </div>
        );
    }

    if (!product) {
        return (
            <div className="text-center py-12">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">Product Not Found</h3>
                <Link to="/store" className="text-primary-600 hover:underline">Go back to home</Link>
            </div>
        );
    }

    return (
        <div className="max-w-5xl mx-auto">
            {/* Back Button */}
            <button
                onClick={() => navigate(-1)}
                className="inline-flex items-center gap-2 text-gray-600 hover:text-primary-600 transition-colors mb-6"
            >
                <HiArrowLeft className="w-5 h-5" />
                Back
            </button>

            <div className="card">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    {/* Product Image */}
                    <div className="aspect-square bg-gray-100 rounded-2xl overflow-hidden">
                        {product.image ? (
                            <img
                                src={product.image}
                                alt={product.name}
                                className="w-full h-full object-cover"
                            />
                        ) : (
                            <div className="w-full h-full flex items-center justify-center text-gray-400">
                                <span className="text-8xl">📦</span>
                            </div>
                        )}
                    </div>

                    {/* Product Info */}
                    <div className="space-y-6">
                        {/* Business Link */}
                        {product.businessId && (
                            <Link
                                to={`/store/business/${product.businessId._id}`}
                                className="inline-flex items-center gap-2 text-gray-500 hover:text-primary-600 transition-colors"
                            >
                                {product.businessId.logo ? (
                                    <img src={product.businessId.logo} alt="" className="w-6 h-6 rounded-lg object-cover" />
                                ) : (
                                    <div className="w-6 h-6 bg-primary-100 rounded-lg flex items-center justify-center">
                                        <span className="text-xs font-bold text-primary-600">
                                            {product.businessId.name?.charAt(0)}
                                        </span>
                                    </div>
                                )}
                                <span className="text-sm font-medium">{product.businessId.name}</span>
                            </Link>
                        )}

                        {/* Name & Category */}
                        <div>
                            <h1 className="text-2xl md:text-3xl font-bold text-gray-800 mb-2">
                                {product.name}
                            </h1>
                            {product.category && (
                                <span className="inline-block px-3 py-1 bg-gray-100 text-gray-600 text-sm rounded-full">
                                    {product.category}
                                </span>
                            )}
                        </div>

                        {/* Price */}
                        <div className="flex items-baseline gap-4">
                            <span className="text-3xl font-bold text-primary-600">
                                {formatCurrency(product.sellingPrice)}
                            </span>
                            <span className="text-gray-500">
                                per {product.unit || 'piece'}
                            </span>
                        </div>

                        {/* Availability */}
                        <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl ${product.stock > 0
                            ? 'bg-green-50 text-green-700'
                            : 'bg-red-50 text-red-700'
                            }`}>
                            {product.stock > 0 ? (
                                <>
                                    <HiCheck className="w-5 h-5" />
                                    <span className="font-medium">{product.stock} in stock</span>
                                </>
                            ) : (
                                <span className="font-medium">Out of Stock</span>
                            )}
                        </div>

                        {/* Description */}
                        {product.description && (
                            <div>
                                <h3 className="font-semibold text-gray-800 mb-2">Description</h3>
                                <p className="text-gray-600 leading-relaxed">{product.description}</p>
                            </div>
                        )}

                        {/* Quantity & Actions */}
                        {product.stock > 0 && (
                            <div className="space-y-4 pt-4 border-t">
                                {/* Quantity Selector */}
                                <div className="flex items-center gap-4">
                                    <span className="text-gray-600 font-medium">Quantity:</span>
                                    <div className="flex items-center gap-3 bg-gray-100 rounded-xl p-2">
                                        <button
                                            onClick={() => setQuantity(q => Math.max(1, q - 1))}
                                            className="w-10 h-10 rounded-lg bg-white shadow flex items-center justify-center hover:bg-gray-50"
                                        >
                                            <HiMinus className="w-5 h-5" />
                                        </button>
                                        <span className="font-semibold w-12 text-center text-lg">{quantity}</span>
                                        <button
                                            onClick={() => setQuantity(q => Math.min(product.stock, q + 1))}
                                            className="w-10 h-10 rounded-lg bg-white shadow flex items-center justify-center hover:bg-gray-50"
                                        >
                                            <HiPlus className="w-5 h-5" />
                                        </button>
                                    </div>
                                </div>

                                {/* Action Buttons */}
                                <div className="flex gap-3">
                                    <button
                                        onClick={handleAddToCart}
                                        className={`flex-1 py-3 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all ${addedToCart
                                            ? 'bg-green-500 text-white'
                                            : 'bg-primary-600 text-white hover:bg-primary-700'
                                            }`}
                                    >
                                        {addedToCart ? (
                                            <>
                                                <HiCheck className="w-5 h-5" />
                                                Added!
                                            </>
                                        ) : (
                                            <>
                                                <HiShoppingCart className="w-5 h-5" />
                                                Add to Cart
                                            </>
                                        )}
                                    </button>
                                    <button
                                        onClick={handleToggleFavorite}
                                        className={`w-14 h-14 rounded-xl flex items-center justify-center transition-colors ${isFavorite
                                            ? 'bg-red-50 text-red-500'
                                            : 'bg-gray-100 text-gray-500 hover:bg-gray-200'
                                            }`}
                                    >
                                        <HiHeart className={`w-6 h-6 ${isFavorite ? 'fill-current' : ''}`} />
                                    </button>
                                </div>

                                {/* WhatsApp Contact */}
                                {product.businessId?.contact?.whatsapp && (
                                    <a
                                        href={`https://wa.me/${product.businessId.contact.whatsapp.replace(/\D/g, '')}?text=Hi! I'm interested in ${product.name} on BizNest.`}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="flex items-center justify-center gap-2 w-full py-3 bg-green-500 text-white rounded-xl hover:bg-green-600 transition-colors"
                                    >
                                        <FaWhatsapp className="w-5 h-5" />
                                        Contact via WhatsApp
                                    </a>
                                )}
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Reviews */}
            <div className="card mt-8">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
                    <div>
                        <h2 className="text-xl font-semibold text-gray-800">Customer Reviews</h2>
                        <p className="text-sm text-gray-500">{reviews.length} review{reviews.length !== 1 ? 's' : ''}</p>
                    </div>
                    <div className="flex items-center gap-2">
                        <span className="text-2xl font-bold text-gray-800">{averageRating}</span>
                        <div className="flex items-center gap-1">
                            {[1, 2, 3, 4, 5].map((star) => (
                                <HiStar
                                    key={star}
                                    className={`w-5 h-5 ${Number(averageRating) >= star ? 'text-yellow-400' : 'text-gray-200'}`}
                                />
                            ))}
                        </div>
                    </div>
                </div>

                {reviewsLoading ? (
                    <div className="text-gray-500">Loading reviews...</div>
                ) : reviews.length === 0 ? (
                    <div className="text-gray-500">No reviews yet.</div>
                ) : (
                    <div className="space-y-4 mb-8">
                        {reviews.map((review) => (
                            <div key={review._id} className="p-4 bg-gray-50 rounded-xl">
                                <div className="flex items-center justify-between mb-2">
                                    <div>
                                        <p className="font-semibold text-gray-800">{review.customerName}</p>
                                        <p className="text-xs text-gray-500">
                                            {new Date(review.createdAt).toLocaleDateString('en-IN', {
                                                day: 'numeric',
                                                month: 'short',
                                                year: 'numeric'
                                            })}
                                        </p>
                                    </div>
                                    <div className="flex items-center gap-1">
                                        {[1, 2, 3, 4, 5].map((star) => (
                                            <HiStar
                                                key={star}
                                                className={`w-4 h-4 ${review.rating >= star ? 'text-yellow-400' : 'text-gray-200'}`}
                                            />
                                        ))}
                                    </div>
                                </div>
                                {review.comment && (
                                    <p className="text-gray-600 text-sm">{review.comment}</p>
                                )}
                            </div>
                        ))}
                    </div>
                )}

                {isAuthenticated ? (
                    reviewEligibility.canReview ? (
                        <form onSubmit={handleReviewSubmit} className="space-y-4">
                            <div>
                                <label className="label">Your Rating</label>
                                <div className="flex items-center gap-2">
                                    {[1, 2, 3, 4, 5].map((star) => (
                                        <button
                                            key={star}
                                            type="button"
                                            onClick={() => setReviewForm({ ...reviewForm, rating: star })}
                                            className="p-1"
                                        >
                                            <HiStar
                                                className={`w-6 h-6 ${reviewForm.rating >= star ? 'text-yellow-400' : 'text-gray-300'}`}
                                            />
                                        </button>
                                    ))}
                                </div>
                            </div>
                            <div>
                                <label className="label">Review</label>
                                <textarea
                                    value={reviewForm.comment}
                                    onChange={(e) => setReviewForm({ ...reviewForm, comment: e.target.value })}
                                    className="input min-h-[120px]"
                                    placeholder="Share your experience..."
                                    maxLength={1000}
                                />
                            </div>
                            {reviewMessage && (
                                <div className={`text-sm ${reviewMessage.includes('Thanks') ? 'text-green-600' : 'text-red-600'}`}>
                                    {reviewMessage}
                                </div>
                            )}
                            <button type="submit" className="btn-primary">
                                Submit Review
                            </button>
                        </form>
                    ) : (
                        <div className="text-sm text-gray-500">
                            {reviewReasonText[reviewEligibility.reason] || 'You are not eligible to review this product.'}
                        </div>
                    )
                ) : (
                    <div className="text-sm text-gray-500">
                        Please log in to leave a review.
                    </div>
                )}
            </div>
        </div>
    );
};

export default ProductDetails;
