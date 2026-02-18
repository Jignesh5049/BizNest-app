const express = require('express');
const router = express.Router();
const Expense = require('../models/Expense');
const Business = require('../models/Business');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

// @route   GET /api/expenses
// @desc    Get all expenses
// @access  Private
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { category, startDate, endDate, limit = 50 } = req.query;
        const query = { businessId };

        if (category) query.category = category;
        if (startDate || endDate) {
            query.date = {};
            if (startDate) query.date.$gte = new Date(startDate);
            if (endDate) query.date.$lte = new Date(endDate);
        }

        const expenses = await Expense.find(query)
            .sort({ date: -1 })
            .limit(parseInt(limit));

        res.json(expenses);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   GET /api/expenses/summary
// @desc    Get expense summary by category
// @access  Private
router.get('/summary', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { month, year } = req.query;
        const now = new Date();
        const targetMonth = month ? parseInt(month) - 1 : now.getMonth();
        const targetYear = year ? parseInt(year) : now.getFullYear();

        const startDate = new Date(targetYear, targetMonth, 1);
        const endDate = new Date(targetYear, targetMonth + 1, 0, 23, 59, 59);

        const summary = await Expense.aggregate([
            {
                $match: {
                    businessId,
                    date: { $gte: startDate, $lte: endDate }
                }
            },
            {
                $group: {
                    _id: '$category',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const totalExpenses = summary.reduce((acc, cat) => acc + cat.total, 0);

        res.json({ summary, totalExpenses, month: targetMonth + 1, year: targetYear });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   POST /api/expenses
// @desc    Create expense
// @access  Private
router.post('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const expense = await Expense.create({
            ...req.body,
            businessId
        });

        res.status(201).json(expense);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/expenses/:id
// @desc    Update expense
// @access  Private
router.put('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const expense = await Expense.findOneAndUpdate(
            { _id: req.params.id, businessId },
            req.body,
            { new: true, runValidators: true }
        );

        if (!expense) {
            return res.status(404).json({ message: 'Expense not found' });
        }

        res.json(expense);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   DELETE /api/expenses/:id
// @desc    Delete expense
// @access  Private
router.delete('/:id', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        const expense = await Expense.findOneAndDelete({ _id: req.params.id, businessId });

        if (!expense) {
            return res.status(404).json({ message: 'Expense not found' });
        }

        res.json({ message: 'Expense deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
