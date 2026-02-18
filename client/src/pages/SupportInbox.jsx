import { useEffect, useState } from 'react';
import { supportAPI } from '../services/api';
import Modal from '../components/Modal';
import {
    HiChatAlt2,
    HiSearch,
    HiCheckCircle,
    HiClock,
    HiXCircle
} from 'react-icons/hi';

const statusStyles = {
    open: 'bg-yellow-50 text-yellow-700',
    in_progress: 'bg-blue-50 text-blue-700',
    resolved: 'bg-green-50 text-green-700'
};

const issueLabels = {
    complaint: 'Complaint',
    return: 'Return',
    replace: 'Replace',
    damaged: 'Damaged',
    wrong_item: 'Wrong Item',
    other: 'Other'
};

const SupportInbox = () => {
    const [tickets, setTickets] = useState([]);
    const [loading, setLoading] = useState(true);
    const [statusFilter, setStatusFilter] = useState('all');
    const [searchQuery, setSearchQuery] = useState('');
    const [selectedTicket, setSelectedTicket] = useState(null);
    const [replyMessage, setReplyMessage] = useState('');
    const [replyStatus, setReplyStatus] = useState('resolved');
    const [savingReply, setSavingReply] = useState(false);
    const [errorMessage, setErrorMessage] = useState('');

    useEffect(() => {
        fetchTickets();
    }, [statusFilter]);

    const fetchTickets = async () => {
        try {
            setLoading(true);
            const params = statusFilter === 'all' ? {} : { status: statusFilter };
            const { data } = await supportAPI.getAll(params);
            setTickets(data);
        } catch (error) {
            console.error('Failed to fetch support tickets:', error);
        } finally {
            setLoading(false);
        }
    };

    const openReplyModal = (ticket) => {
        setSelectedTicket(ticket);
        setReplyMessage(ticket.replyMessage || '');
        setReplyStatus(ticket.status === 'resolved' ? 'resolved' : 'in_progress');
        setErrorMessage('');
    };

    const closeReplyModal = () => {
        setSelectedTicket(null);
        setReplyMessage('');
        setReplyStatus('resolved');
        setErrorMessage('');
    };

    const handleReplySubmit = async (e) => {
        e.preventDefault();
        if (!replyMessage.trim()) {
            setErrorMessage('Reply message is required.');
            return;
        }

        setSavingReply(true);
        try {
            const { data } = await supportAPI.reply(selectedTicket._id, {
                replyMessage,
                status: replyStatus
            });

            setTickets(prev => prev.map(ticket =>
                ticket._id === data._id ? data : ticket
            ));
            closeReplyModal();
        } catch (error) {
            setErrorMessage(error.response?.data?.message || 'Failed to save reply');
        } finally {
            setSavingReply(false);
        }
    };

    const filteredTickets = tickets.filter(ticket => {
        const query = searchQuery.toLowerCase();
        return (
            ticket.customerName?.toLowerCase().includes(query) ||
            ticket.customerEmail?.toLowerCase().includes(query) ||
            ticket.subject?.toLowerCase().includes(query) ||
            ticket.orderId?.orderNumber?.toLowerCase().includes(query)
        );
    });

    return (
        <div className="space-y-6 animate-fadeIn">
            <div className="flex items-center gap-4">
                <div className="p-3 bg-gray-100 rounded-xl">
                    <HiChatAlt2 className="w-6 h-6 text-gray-600" />
                </div>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Support & Feedback</h1>
                    <p className="text-gray-600">Manage customer complaints, returns, and replacements.</p>
                </div>
            </div>

            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div className="relative">
                    <HiSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                    <input
                        type="text"
                        placeholder="Search tickets..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="input pl-10 w-72"
                    />
                </div>
                <div className="flex items-center gap-2">
                    <button
                        onClick={() => setStatusFilter('all')}
                        className={`px-4 py-2 rounded-xl text-sm font-medium border ${statusFilter === 'all'
                            ? 'bg-gray-900 text-white border-gray-900'
                            : 'bg-white text-gray-600 border-gray-200'
                            }`}
                    >
                        All
                    </button>
                    <button
                        onClick={() => setStatusFilter('open')}
                        className={`px-4 py-2 rounded-xl text-sm font-medium border ${statusFilter === 'open'
                            ? 'bg-yellow-500 text-white border-yellow-500'
                            : 'bg-white text-gray-600 border-gray-200'
                            }`}
                    >
                        Open
                    </button>
                    <button
                        onClick={() => setStatusFilter('in_progress')}
                        className={`px-4 py-2 rounded-xl text-sm font-medium border ${statusFilter === 'in_progress'
                            ? 'bg-blue-500 text-white border-blue-500'
                            : 'bg-white text-gray-600 border-gray-200'
                            }`}
                    >
                        In Progress
                    </button>
                    <button
                        onClick={() => setStatusFilter('resolved')}
                        className={`px-4 py-2 rounded-xl text-sm font-medium border ${statusFilter === 'resolved'
                            ? 'bg-green-500 text-white border-green-500'
                            : 'bg-white text-gray-600 border-gray-200'
                            }`}
                    >
                        Resolved
                    </button>
                </div>
            </div>

            {loading ? (
                <div className="flex items-center justify-center h-64">
                    <div className="w-12 h-12 border-4 border-primary-500 border-t-transparent rounded-full animate-spin"></div>
                </div>
            ) : filteredTickets.length === 0 ? (
                <div className="card text-center py-12">
                    <HiChatAlt2 className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                    <h3 className="text-lg font-semibold text-gray-900">No support requests</h3>
                    <p className="text-gray-500">Customer support tickets will appear here.</p>
                </div>
            ) : (
                <div className="card p-0 overflow-x-auto">
                    <table className="min-w-full text-sm">
                        <thead className="bg-gray-50 text-gray-500">
                            <tr>
                                <th className="text-left px-4 py-3 font-medium">Customer</th>
                                <th className="text-left px-4 py-3 font-medium">Order</th>
                                <th className="text-left px-4 py-3 font-medium">Issue</th>
                                <th className="text-left px-4 py-3 font-medium">Status</th>
                                <th className="text-left px-4 py-3 font-medium">Created</th>
                                <th className="text-right px-4 py-3 font-medium">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredTickets.map(ticket => (
                                <tr key={ticket._id} className="border-t">
                                    <td className="px-4 py-3">
                                        <div className="font-medium text-gray-900">{ticket.customerName}</div>
                                        <div className="text-xs text-gray-500">{ticket.customerEmail}</div>
                                    </td>
                                    <td className="px-4 py-3 text-gray-700">
                                        {ticket.orderId?.orderNumber || '—'}
                                    </td>
                                    <td className="px-4 py-3 text-gray-700">
                                        <div className="font-medium">{issueLabels[ticket.issueType] || 'Support'}</div>
                                        {ticket.productId?.name && (
                                            <div className="text-xs text-gray-500">{ticket.productId.name}</div>
                                        )}
                                    </td>
                                    <td className="px-4 py-3">
                                        <span className={`px-2.5 py-1 rounded-full text-xs font-semibold ${statusStyles[ticket.status] || 'bg-gray-100 text-gray-600'}`}>
                                            {ticket.status?.replace('_', ' ') || 'open'}
                                        </span>
                                    </td>
                                    <td className="px-4 py-3 text-gray-700">
                                        {new Date(ticket.createdAt).toLocaleDateString('en-IN', {
                                            day: 'numeric',
                                            month: 'short',
                                            year: 'numeric'
                                        })}
                                    </td>
                                    <td className="px-4 py-3 text-right">
                                        <button
                                            onClick={() => openReplyModal(ticket)}
                                            className="btn-secondary py-2 px-3"
                                        >
                                            {ticket.replyMessage ? 'View Reply' : 'Reply'}
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}

            <Modal
                isOpen={!!selectedTicket}
                onClose={closeReplyModal}
                title={selectedTicket ? `Ticket ${selectedTicket.orderId?.orderNumber || ''}` : 'Ticket'}
                size="lg"
            >
                {selectedTicket && (
                    <div className="space-y-4">
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm text-gray-600">
                            <div>
                                <p className="text-xs uppercase tracking-wide text-gray-400">Customer</p>
                                <p className="font-medium text-gray-900">{selectedTicket.customerName}</p>
                                <p>{selectedTicket.customerEmail}</p>
                            </div>
                            <div>
                                <p className="text-xs uppercase tracking-wide text-gray-400">Issue</p>
                                <p className="font-medium text-gray-900">{issueLabels[selectedTicket.issueType] || 'Support'}</p>
                                {selectedTicket.productId?.name && (
                                    <p>{selectedTicket.productId.name}</p>
                                )}
                            </div>
                        </div>

                        <div className="bg-gray-50 rounded-xl p-4">
                            <p className="text-xs uppercase tracking-wide text-gray-400 mb-2">Customer Message</p>
                            <p className="text-gray-700 whitespace-pre-line">{selectedTicket.message}</p>
                        </div>

                        <form onSubmit={handleReplySubmit} className="space-y-4">
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label className="label">Status</label>
                                    <select
                                        value={replyStatus}
                                        onChange={(e) => setReplyStatus(e.target.value)}
                                        className="input"
                                    >
                                        <option value="in_progress">In Progress</option>
                                        <option value="resolved">Resolved</option>
                                    </select>
                                </div>
                                <div className="flex items-center gap-2 text-xs text-gray-500">
                                    {replyStatus === 'resolved' ? (
                                        <HiCheckCircle className="w-5 h-5 text-green-500" />
                                    ) : (
                                        <HiClock className="w-5 h-5 text-blue-500" />
                                    )}
                                    {replyStatus === 'resolved'
                                        ? 'Mark resolved after reply'
                                        : 'Keep ticket open'
                                    }
                                </div>
                            </div>

                            <div>
                                <label className="label">Reply *</label>
                                <textarea
                                    value={replyMessage}
                                    onChange={(e) => setReplyMessage(e.target.value)}
                                    className="input min-h-[140px]"
                                    placeholder="Write your response to the customer..."
                                    required
                                />
                            </div>

                            {errorMessage && (
                                <div className="flex items-center gap-2 text-sm text-red-600">
                                    <HiXCircle className="w-4 h-4" />
                                    {errorMessage}
                                </div>
                            )}

                            <div className="flex items-center gap-3">
                                <button type="submit" className="btn-primary" disabled={savingReply}>
                                    {savingReply ? 'Saving...' : 'Save Reply'}
                                </button>
                                <button type="button" className="btn-secondary" onClick={closeReplyModal}>
                                    Close
                                </button>
                            </div>
                        </form>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default SupportInbox;
