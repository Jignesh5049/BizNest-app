import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json'
    }
});

// Add token to requests
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle auth errors
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('userRole');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

// Auth API
export const authAPI = {
    signup: (data) => api.post('/auth/signup', data),
    login: (data) => api.post('/auth/login', data),
    getMe: () => api.get('/auth/me'),
    updateProfile: (data) => api.put('/auth/profile', data)
};

// Business API
export const businessAPI = {
    get: () => api.get('/business'),
    create: (data) => api.post('/business', data),
    update: (data) => api.put('/business', data)
};

// Products API
export const productsAPI = {
    getAll: () => api.get('/products'),
    getOne: (id) => api.get(`/products/${id}`),
    create: (data) => api.post('/products', data),
    update: (id, data) => api.put(`/products/${id}`, data),
    delete: (id) => api.delete(`/products/${id}`),
    updateStock: (id, data) => api.patch(`/products/${id}/stock`, data)
};

// Customers API
export const customersAPI = {
    getAll: () => api.get('/customers'),
    getOne: (id) => api.get(`/customers/${id}`),
    create: (data) => api.post('/customers', data),
    update: (id, data) => api.put(`/customers/${id}`, data),
    delete: (id) => api.delete(`/customers/${id}`)
};

// Orders API
export const ordersAPI = {
    getAll: (params) => api.get('/orders', { params }),
    getOne: (id) => api.get(`/orders/${id}`),
    create: (data) => api.post('/orders', data),
    updateStatus: (id, status) => api.put(`/orders/${id}/status`, { status }),
    updatePayment: (id, data) => api.put(`/orders/${id}/payment`, data),
    cancel: (id) => api.delete(`/orders/${id}`)
};

// Expenses API
export const expensesAPI = {
    getAll: (params) => api.get('/expenses', { params }),
    getSummary: (params) => api.get('/expenses/summary', { params }),
    create: (data) => api.post('/expenses', data),
    update: (id, data) => api.put(`/expenses/${id}`, data),
    delete: (id) => api.delete(`/expenses/${id}`)
};

// Analytics API
export const analyticsAPI = {
    getDashboard: () => api.get('/analytics/dashboard'),
    getRevenueChart: () => api.get('/analytics/revenue-chart'),
    getTopProducts: () => api.get('/analytics/top-products'),
    getHealthScore: () => api.get('/analytics/health-score')
};

// Support API (Business)
export const supportAPI = {
    getAll: (params) => api.get('/support', { params }),
    reply: (id, data) => api.put(`/support/${id}/reply`, data)
};

// Uploads API
export const uploadsAPI = {
    uploadProductImage: (file) => {
        const formData = new FormData();
        formData.append('image', file);
        return api.post('/uploads/product-image', formData, {
            headers: { 'Content-Type': 'multipart/form-data' }
        });
    }
};

// ==================== CUSTOMER STORE API ====================

export const storeAPI = {
    // Public
    getBusinesses: (params) => api.get('/store/businesses', { params }),
    getBusiness: (id) => api.get(`/store/businesses/${id}`),
    getProduct: (id) => api.get(`/store/products/${id}`),
    getProductReviews: (id) => api.get(`/store/products/${id}/reviews`),
    getAllProducts: (params) => api.get('/store/all-products', { params }),

    // Orders (Customer only)
    createOrder: (data) => api.post('/store/orders', data),
    getOrders: (params) => api.get('/store/orders', { params }),
    getOrder: (id) => api.get(`/store/orders/${id}`),
    cancelOrder: (id) => api.put(`/store/orders/${id}/cancel`),
    reorder: (id) => api.post(`/store/orders/${id}/reorder`),

    // Reviews
    getReviewEligibility: (id) => api.get(`/store/products/${id}/reviews/eligibility`),
    createReview: (id, data) => api.post(`/store/products/${id}/reviews`, data),

    // Favorites
    getFavorites: () => api.get('/store/favorites'),
    addFavorite: (productId) => api.post(`/store/favorites/${productId}`),
    removeFavorite: (productId) => api.delete(`/store/favorites/${productId}`),

    // Addresses
    getAddresses: () => api.get('/store/addresses'),
    addAddress: (data) => api.post('/store/addresses', data),
    updateAddress: (id, data) => api.put(`/store/addresses/${id}`, data),
    deleteAddress: (id) => api.delete(`/store/addresses/${id}`),

    // Support
    createSupportTicket: (data) => api.post('/store/support', data),
    getSupportTickets: () => api.get('/store/support'),

    // Dashboard
    getDashboard: () => api.get('/store/dashboard')
};

export default api;
