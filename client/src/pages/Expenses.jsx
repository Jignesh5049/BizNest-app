import { useState, useEffect } from 'react';
import { expensesAPI } from '../services/api';
import { formatCurrency, formatDate, expenseCategories } from '../utils/helpers';
import Modal from '../components/Modal';
import {
    HiPlus,
    HiCurrencyRupee,
    HiTrash,
    HiFilter,
    HiCube,
    HiTruck,
    HiSpeakerphone,
    HiLightBulb,
    HiHome,
    HiCog,
    HiArchive,
    HiClipboardList
} from 'react-icons/hi';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';

// Map icon names to components
const iconMap = {
    HiCube: HiCube,
    HiTruck: HiTruck,
    HiSpeakerphone: HiSpeakerphone,
    HiLightBulb: HiLightBulb,
    HiHome: HiHome,
    HiCurrencyRupee: HiCurrencyRupee,
    HiCog: HiCog,
    HiArchive: HiArchive,
    HiClipboardList: HiClipboardList
};

const COLORS = ['#0ea5e9', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#14b8a6', '#f97316', '#6366f1'];

const Expenses = () => {
    const [expenses, setExpenses] = useState([]);
    const [summary, setSummary] = useState({ summary: [], totalExpenses: 0 });
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [filterCategory, setFilterCategory] = useState('');
    const [formData, setFormData] = useState({
        category: 'raw_material',
        amount: '',
        description: '',
        date: new Date().toISOString().split('T')[0]
    });

    useEffect(() => {
        fetchExpenses();
        fetchSummary();
    }, [filterCategory]);

    const fetchExpenses = async () => {
        try {
            const { data } = await expensesAPI.getAll({ category: filterCategory || undefined });
            setExpenses(data);
        } catch (error) {
            console.error('Failed to fetch expenses:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchSummary = async () => {
        try {
            const { data } = await expensesAPI.getSummary();
            setSummary(data);
        } catch (error) {
            console.error('Failed to fetch summary:', error);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await expensesAPI.create({
                ...formData,
                amount: parseFloat(formData.amount),
                date: new Date(formData.date)
            });
            fetchExpenses();
            fetchSummary();
            closeModal();
        } catch (error) {
            console.error('Failed to add expense:', error);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm('Delete this expense?')) {
            try {
                await expensesAPI.delete(id);
                fetchExpenses();
                fetchSummary();
            } catch (error) {
                console.error('Failed to delete expense:', error);
            }
        }
    };

    const closeModal = () => {
        setShowModal(false);
        setFormData({
            category: 'raw_material',
            amount: '',
            description: '',
            date: new Date().toISOString().split('T')[0]
        });
    };

    const chartData = summary.summary.map((item, index) => ({
        name: expenseCategories[item._id]?.label || item._id,
        value: item.total,
        color: COLORS[index % COLORS.length]
    }));

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
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Expenses</h1>
                    <p className="text-gray-600">Track your business expenses</p>
                </div>
                <div className="flex gap-3">
                    <select
                        value={filterCategory}
                        onChange={(e) => setFilterCategory(e.target.value)}
                        className="input w-48"
                    >
                        <option value="">All Categories</option>
                        {Object.entries(expenseCategories).map(([key, { label }]) => (
                            <option key={key} value={key}>{label}</option>
                        ))}
                    </select>
                    <button onClick={() => setShowModal(true)} className="btn-primary flex items-center gap-2">
                        <HiPlus className="w-5 h-5" />
                        Add Expense
                    </button>
                </div>
            </div>

            {/* Summary Cards */}
            <div className="grid md:grid-cols-3 gap-6">
                {/* Total Expenses */}
                <div className="card bg-gradient-to-br from-red-500 to-red-600 text-white">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-white/20 rounded-xl">
                            <HiCurrencyRupee className="w-8 h-8" />
                        </div>
                        <div>
                            <p className="text-white/80 text-sm">Total Expenses (This Month)</p>
                            <h3 className="text-2xl font-bold">{formatCurrency(summary.totalExpenses)}</h3>
                        </div>
                    </div>
                </div>

                {/* Chart */}
                <div className="card md:col-span-2">
                    <h3 className="font-semibold text-gray-900 mb-4">Expense Breakdown</h3>
                    {chartData.length > 0 ? (
                        <div className="h-48">
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={chartData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={40}
                                        outerRadius={70}
                                        paddingAngle={2}
                                        dataKey="value"
                                    >
                                        {chartData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={entry.color} />
                                        ))}
                                    </Pie>
                                    <Tooltip formatter={(value) => formatCurrency(value)} />
                                    <Legend />
                                </PieChart>
                            </ResponsiveContainer>
                        </div>
                    ) : (
                        <p className="text-gray-500 text-center py-8">No expense data for this month</p>
                    )}
                </div>
            </div>

            {/* Expenses List */}
            {expenses.length === 0 ? (
                <div className="card text-center py-12">
                    <HiCurrencyRupee className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 mb-2">No expenses recorded</h3>
                    <p className="text-gray-500 mb-4">Start tracking your business expenses</p>
                    <button onClick={() => setShowModal(true)} className="btn-primary">
                        Add Expense
                    </button>
                </div>
            ) : (
                <div className="card">
                    <h3 className="font-semibold text-gray-900 mb-4">Recent Expenses</h3>
                    <div className="space-y-3">
                        {expenses.map((expense) => (
                            <div
                                key={expense._id}
                                className="flex items-center justify-between p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                            >
                                <div className="flex items-center gap-4">
                                    <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center shadow-sm">
                                        {(() => {
                                            const iconName = expenseCategories[expense.category]?.icon;
                                            const IconComponent = iconMap[iconName] || HiClipboardList;
                                            return <IconComponent className="w-5 h-5 text-gray-600" />;
                                        })()}
                                    </div>
                                    <div>
                                        <p className="font-medium text-gray-900">
                                            {expenseCategories[expense.category]?.label || expense.category}
                                        </p>
                                        {expense.description && (
                                            <p className="text-sm text-gray-500">{expense.description}</p>
                                        )}
                                        <p className="text-xs text-gray-400">{formatDate(expense.date)}</p>
                                    </div>
                                </div>
                                <div className="flex items-center gap-4">
                                    <span className="text-lg font-bold text-red-600">
                                        -{formatCurrency(expense.amount)}
                                    </span>
                                    <button
                                        type="button"
                                        onClick={(e) => {
                                            e.preventDefault();
                                            e.stopPropagation();
                                            handleDelete(expense._id);
                                        }}
                                        className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors cursor-pointer"
                                        title="Delete expense"
                                    >
                                        <HiTrash className="w-5 h-5" />
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {/* Add Expense Modal */}
            <Modal isOpen={showModal} onClose={closeModal} title="Add Expense">
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="label">Category *</label>
                        <select
                            value={formData.category}
                            onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                            className="input"
                            required
                        >
                            {Object.entries(expenseCategories).map(([key, { label }]) => (
                                <option key={key} value={key}>{label}</option>
                            ))}
                        </select>
                    </div>

                    <div>
                        <label className="label">Amount *</label>
                        <input
                            type="number"
                            value={formData.amount}
                            onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                            className="input"
                            placeholder="0"
                            min="0"
                            step="0.01"
                            required
                        />
                    </div>

                    <div>
                        <label className="label">Date</label>
                        <input
                            type="date"
                            value={formData.date}
                            onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                            className="input"
                        />
                    </div>

                    <div>
                        <label className="label">Description</label>
                        <textarea
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            className="input min-h-[80px]"
                            placeholder="What was this expense for?"
                        />
                    </div>

                    <div className="flex gap-3 pt-4">
                        <button type="button" onClick={closeModal} className="flex-1 btn-secondary">
                            Cancel
                        </button>
                        <button type="submit" className="flex-1 btn-primary">
                            Add Expense
                        </button>
                    </div>
                </form>
            </Modal>
        </div>
    );
};

export default Expenses;
