const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Product = require('../models/Product');
const Customer = require('../models/Customer');
const Expense = require('../models/Expense');
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

// @route   GET /api/analytics/dashboard
// @desc    Get dashboard stats
// @access  Private
router.get('/dashboard', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const now = new Date();
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
        const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);

        // Total revenue (all time)
        const totalRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid' } },
            { $group: { _id: null, total: { $sum: '$total' } } }
        ]);
        const totalRevenue = totalRevenueResult[0]?.total || 0;

        // This month's revenue
        const monthlyRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: startOfMonth } } },
            { $group: { _id: null, total: { $sum: '$total' }, profit: { $sum: '$profit' } } }
        ]);
        const monthlyRevenue = monthlyRevenueResult[0]?.total || 0;
        const monthlyProfit = monthlyRevenueResult[0]?.profit || 0;

        // Last month's revenue for comparison
        const lastMonthRevenueResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: startOfLastMonth, $lte: endOfLastMonth } } },
            { $group: { _id: null, total: { $sum: '$total' } } }
        ]);
        const lastMonthRevenue = lastMonthRevenueResult[0]?.total || 0;

        // Total orders
        const totalOrders = await Order.countDocuments({ businessId, status: { $ne: 'cancelled' } });
        const monthlyOrders = await Order.countDocuments({ businessId, status: { $ne: 'cancelled' }, createdAt: { $gte: startOfMonth } });

        // This month's expenses
        const monthlyExpensesResult = await Expense.aggregate([
            { $match: { businessId, date: { $gte: startOfMonth } } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const monthlyExpenses = monthlyExpensesResult[0]?.total || 0;

        // Net profit
        const netProfit = monthlyProfit - monthlyExpenses;

        // Product stats
        const totalProducts = await Product.countDocuments({ businessId, isActive: true });
        const lowStockProducts = await Product.countDocuments({ businessId, isActive: true, stock: { $lte: 5, $gt: 0 } });
        const outOfStockProducts = await Product.countDocuments({ businessId, isActive: true, stock: 0 });

        // Customer stats
        const totalCustomers = await Customer.countDocuments({ businessId });
        const repeatCustomers = await Customer.countDocuments({ businessId, isRepeatCustomer: true });

        // Pending orders
        const pendingOrders = await Order.countDocuments({ businessId, status: 'pending' });
        const unpaidOrders = await Order.countDocuments({ businessId, paymentStatus: 'unpaid', status: { $ne: 'cancelled' } });

        res.json({
            revenue: {
                total: totalRevenue,
                monthly: monthlyRevenue,
                lastMonth: lastMonthRevenue,
                growth: lastMonthRevenue > 0 ? ((monthlyRevenue - lastMonthRevenue) / lastMonthRevenue * 100).toFixed(1) : 0
            },
            profit: {
                monthly: monthlyProfit,
                net: netProfit
            },
            expenses: {
                monthly: monthlyExpenses
            },
            orders: {
                total: totalOrders,
                monthly: monthlyOrders,
                pending: pendingOrders,
                unpaid: unpaidOrders
            },
            products: {
                total: totalProducts,
                lowStock: lowStockProducts,
                outOfStock: outOfStockProducts
            },
            customers: {
                total: totalCustomers,
                repeat: repeatCustomers,
                repeatRate: totalCustomers > 0 ? ((repeatCustomers / totalCustomers) * 100).toFixed(1) : 0
            }
        });
    } catch (error) {
        console.error('Dashboard analytics error:', error);
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/revenue-chart
// @desc    Get monthly revenue data for chart
// @access  Private
router.get('/revenue-chart', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const months = 6;
        const data = [];

        for (let i = months - 1; i >= 0; i--) {
            const now = new Date();
            const startDate = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const endDate = new Date(now.getFullYear(), now.getMonth() - i + 1, 0, 23, 59, 59);

            const result = await Order.aggregate([
                { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: startDate, $lte: endDate } } },
                { $group: { _id: null, revenue: { $sum: '$total' }, profit: { $sum: '$profit' } } }
            ]);

            const expenseResult = await Expense.aggregate([
                { $match: { businessId, date: { $gte: startDate, $lte: endDate } } },
                { $group: { _id: null, total: { $sum: '$amount' } } }
            ]);

            data.push({
                month: startDate.toLocaleString('default', { month: 'short' }),
                revenue: result[0]?.revenue || 0,
                profit: result[0]?.profit || 0,
                expenses: expenseResult[0]?.total || 0
            });
        }

        res.json(data);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/top-products
// @desc    Get top selling products
// @access  Private
router.get('/top-products', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const result = await Order.aggregate([
            { $match: { businessId, status: { $ne: 'cancelled' } } },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.productId',
                    name: { $first: '$items.name' },
                    totalQuantity: { $sum: '$items.quantity' },
                    totalRevenue: { $sum: '$items.total' }
                }
            },
            { $sort: { totalQuantity: -1 } },
            { $limit: 5 }
        ]);

        res.json(result);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/analytics/health-score
// @desc    Calculate business health score
// @access  Private
router.get('/health-score', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const now = new Date();
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

        // Factor 1: Order frequency (max 25 points)
        const recentOrders = await Order.countDocuments({
            businessId,
            status: { $ne: 'cancelled' },
            createdAt: { $gte: thirtyDaysAgo }
        });
        const orderScore = Math.min(25, recentOrders * 2.5);

        // Factor 2: Profit margin (max 25 points)
        const profitResult = await Order.aggregate([
            { $match: { businessId, paymentStatus: 'paid', createdAt: { $gte: thirtyDaysAgo } } },
            { $group: { _id: null, revenue: { $sum: '$total' }, profit: { $sum: '$profit' } } }
        ]);
        const revenue = profitResult[0]?.revenue || 0;
        const profit = profitResult[0]?.profit || 0;
        const profitMargin = revenue > 0 ? (profit / revenue) * 100 : 0;
        const marginScore = Math.min(25, profitMargin);

        // Factor 3: Inventory health (max 25 points)
        const totalProducts = await Product.countDocuments({ businessId, isActive: true });
        const healthyStock = await Product.countDocuments({ businessId, isActive: true, stock: { $gt: 5 } });
        const inventoryHealth = totalProducts > 0 ? (healthyStock / totalProducts) * 100 : 100;
        const inventoryScore = (inventoryHealth / 100) * 25;

        // Factor 4: Repeat customers (max 25 points)
        const totalCustomers = await Customer.countDocuments({ businessId });
        const repeatCustomers = await Customer.countDocuments({ businessId, isRepeatCustomer: true });
        const repeatRate = totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0;
        const repeatScore = (repeatRate / 100) * 25;

        const totalScore = Math.round(orderScore + marginScore + inventoryScore + repeatScore);

        // Generate tips based on weakest areas
        const tips = [];
        if (orderScore < 15) tips.push('Increase marketing to get more orders');
        if (marginScore < 15) tips.push('Review pricing to improve profit margins');
        if (inventoryScore < 15) tips.push('Restock products running low on inventory');
        if (repeatScore < 15) tips.push('Focus on customer retention for repeat business');
        if (tips.length === 0) tips.push('Great job! Keep up the good work!');

        res.json({
            score: totalScore,
            breakdown: {
                orderFrequency: Math.round(orderScore),
                profitMargin: Math.round(marginScore),
                inventoryHealth: Math.round(inventoryScore),
                customerRetention: Math.round(repeatScore)
            },
            tips: tips.slice(0, 3),
            status: totalScore >= 70 ? 'healthy' : totalScore >= 40 ? 'moderate' : 'needs_attention'
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
