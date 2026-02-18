const express = require('express');
const router = express.Router();
const SupportTicket = require('../models/SupportTicket');
const Business = require('../models/Business');
const Order = require('../models/Order');
const { protect } = require('../middleware/auth');

router.use(protect);

const getBusinessId = async (userId) => {
    const business = await Business.findOne({ userId });
    return business?._id;
};

// @route   GET /api/support
// @desc    Get support tickets for business
// @access  Private (Business)
router.get('/', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const query = { businessId };
        if (req.query.status) query.status = req.query.status;

        const tickets = await SupportTicket.find(query)
            .populate('orderId', 'orderNumber createdAt')
            .populate('productId', 'name')
            .sort({ createdAt: -1 });

        res.json(tickets);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/support/:id/reply
// @desc    Reply to a support ticket
// @access  Private (Business)
router.put('/:id/reply', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { replyMessage, status } = req.body;
        if (!replyMessage || !replyMessage.trim()) {
            return res.status(400).json({ message: 'Reply message is required' });
        }

        let ticket = await SupportTicket.findOne({ _id: req.params.id, businessId });

        if (!ticket) {
            const fallbackTicket = await SupportTicket.findOne({
                _id: req.params.id,
                businessId: { $in: [null, undefined] }
            });

            if (fallbackTicket && fallbackTicket.orderId) {
                const order = await Order.findById(fallbackTicket.orderId).select('businessId');
                if (order && order.businessId?.toString() === businessId.toString()) {
                    ticket = fallbackTicket;
                    ticket.businessId = businessId;
                }
            }
        }

        if (!ticket) {
            return res.status(404).json({ message: 'Ticket not found' });
        }

        ticket.replyMessage = replyMessage;
        ticket.status = status || 'resolved';
        ticket.repliedAt = new Date();
        ticket.updatedAt = new Date();
        await ticket.save();

        await ticket.populate('orderId', 'orderNumber createdAt');
        await ticket.populate('productId', 'name');

        res.json(ticket);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @route   PUT /api/support/:id/status
// @desc    Update support ticket status only (no reply required)
// @access  Private (Business)
router.put('/:id/status', async (req, res) => {
    try {
        const businessId = await getBusinessId(req.user._id);
        if (!businessId) {
            return res.status(404).json({ message: 'Business not found' });
        }

        const { status } = req.body;
        if (!status) {
            return res.status(400).json({ message: 'Status is required' });
        }

        const ticket = await SupportTicket.findOneAndUpdate(
            { _id: req.params.id, businessId },
            { status, updatedAt: new Date() },
            { new: true }
        ).populate('orderId', 'orderNumber createdAt')
            .populate('productId', 'name');

        if (!ticket) {
            return res.status(404).json({ message: 'Ticket not found' });
        }

        res.json(ticket);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
