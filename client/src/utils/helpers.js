// Format currency in Indian Rupees
export const formatCurrency = (amount) => {
    if (amount === undefined || amount === null) return '₹0';
    return new Intl.NumberFormat('en-IN', {
        style: 'currency',
        currency: 'INR',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    }).format(amount);
};

// Format date
export const formatDate = (date) => {
    if (!date) return '';
    return new Date(date).toLocaleDateString('en-IN', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
    });
};

// Format date time
export const formatDateTime = (date) => {
    if (!date) return '';
    return new Date(date).toLocaleString('en-IN', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
};

// Get status color class
export const getStatusColor = (status) => {
    const colors = {
        pending: 'bg-yellow-100 text-yellow-800',
        confirmed: 'bg-blue-100 text-blue-800',
        completed: 'bg-green-100 text-green-800',
        cancelled: 'bg-red-100 text-red-800',
        unpaid: 'bg-red-100 text-red-800',
        partial: 'bg-yellow-100 text-yellow-800',
        paid: 'bg-green-100 text-green-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
};

// Calculate profit margin
export const calculateMargin = (costPrice, sellingPrice) => {
    if (!costPrice || costPrice === 0) return 100;
    return ((sellingPrice - costPrice) / costPrice * 100).toFixed(1);
};

// Calculate selling price from margin
export const calculateSellingPrice = (costPrice, marginPercent) => {
    return costPrice * (1 + marginPercent / 100);
};

// Get stock status
export const getStockStatus = (stock) => {
    if (stock === 0) return { label: 'Out of Stock', color: 'bg-red-100 text-red-800' };
    if (stock <= 5) return { label: 'Low Stock', color: 'bg-yellow-100 text-yellow-800' };
    return { label: 'In Stock', color: 'bg-green-100 text-green-800' };
};

// Expense categories with labels and icons (using icon names for react-icons)
export const expenseCategories = {
    raw_material: { label: 'Raw Material', icon: 'HiCube' },
    delivery: { label: 'Delivery', icon: 'HiTruck' },
    marketing: { label: 'Marketing', icon: 'HiSpeakerphone' },
    utilities: { label: 'Utilities', icon: 'HiLightBulb' },
    rent: { label: 'Rent', icon: 'HiHome' },
    salary: { label: 'Salary', icon: 'HiCurrencyRupee' },
    equipment: { label: 'Equipment', icon: 'HiCog' },
    packaging: { label: 'Packaging', icon: 'HiArchive' },
    misc: { label: 'Miscellaneous', icon: 'HiClipboardList' }
};

// Business categories
export const businessCategories = [
    { value: 'retail', label: 'Retail Store' },
    { value: 'food', label: 'Food & Beverages' },
    { value: 'services', label: 'Services' },
    { value: 'handmade', label: 'Handmade & Crafts' },
    { value: 'consulting', label: 'Consulting' },
    { value: 'other', label: 'Other' }
];

// Generate WhatsApp link
export const generateWhatsAppLink = (phone, message) => {
    const cleanPhone = phone?.replace(/\D/g, '') || '';
    const encodedMessage = encodeURIComponent(message);
    return `https://wa.me/${cleanPhone}?text=${encodedMessage}`;
};

// Generate product share message
export const generateProductShareMessage = (product, businessName) => {
    return `Check out ${product.name} from ${businessName}!\n\nPrice: ${formatCurrency(product.sellingPrice)}\n\n${product.description || ''}\n\nOrder now!`;
};
