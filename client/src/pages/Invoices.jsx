import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { ordersAPI } from '../services/api';
import { formatCurrency, formatDate } from '../utils/helpers';
import { useAuth } from '../context/AuthContext';
import { HiDocumentText, HiDownload, HiPrinter } from 'react-icons/hi';

const Invoices = () => {
    const [searchParams] = useSearchParams();
    const orderId = searchParams.get('order');
    const { business } = useAuth();
    const [order, setOrder] = useState(null);
    const [orders, setOrders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedOrder, setSelectedOrder] = useState(null);

    useEffect(() => {
        if (orderId) {
            fetchOrder(orderId);
        } else {
            fetchOrders();
        }
    }, [orderId]);

    const fetchOrder = async (id) => {
        try {
            const { data } = await ordersAPI.getOne(id);
            setOrder(data);
            setSelectedOrder(data);
        } catch (error) {
            console.error('Failed to fetch order:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchOrders = async () => {
        try {
            const { data } = await ordersAPI.getAll({ paymentStatus: 'paid' });
            setOrders(data);
            if (data.length > 0) {
                setSelectedOrder(data[0]);
            }
        } catch (error) {
            console.error('Failed to fetch orders:', error);
        } finally {
            setLoading(false);
        }
    };

    const handlePrint = () => {
        window.print();
    };

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
            <div className="flex items-center justify-between print:hidden">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Invoices</h1>
                    <p className="text-gray-600">Generate and view invoices for your orders</p>
                </div>
            </div>

            <div className="grid lg:grid-cols-3 gap-6">
                {/* Order List */}
                <div className="lg:col-span-1 print:hidden">
                    <div className="card">
                        <h3 className="font-semibold text-gray-900 mb-4">Paid Orders</h3>
                        {orders.length === 0 ? (
                            <p className="text-gray-500 text-center py-8">No paid orders yet</p>
                        ) : (
                            <div className="space-y-2 max-h-[500px] overflow-y-auto">
                                {orders.map((o) => (
                                    <button
                                        key={o._id}
                                        onClick={() => setSelectedOrder(o)}
                                        className={`w-full text-left p-3 rounded-xl transition-colors ${selectedOrder?._id === o._id
                                                ? 'bg-primary-50 border border-primary-200'
                                                : 'hover:bg-gray-50'
                                            }`}
                                    >
                                        <div className="flex justify-between">
                                            <span className="font-medium">{o.orderNumber}</span>
                                            <span className="text-sm text-gray-500">{formatCurrency(o.total)}</span>
                                        </div>
                                        <p className="text-sm text-gray-500">{o.customerId?.name}</p>
                                        <p className="text-xs text-gray-400">{formatDate(o.createdAt)}</p>
                                    </button>
                                ))}
                            </div>
                        )}
                    </div>
                </div>

                {/* Invoice Preview */}
                <div className="lg:col-span-2">
                    {selectedOrder ? (
                        <div>
                            {/* Actions */}
                            <div className="flex gap-3 mb-4 print:hidden">
                                <button onClick={handlePrint} className="btn-primary flex items-center gap-2">
                                    <HiPrinter className="w-5 h-5" />
                                    Print Invoice
                                </button>
                            </div>

                            {/* Invoice */}
                            <div className="card bg-white print:shadow-none" id="invoice">
                                {/* Header */}
                                <div className="flex justify-between items-start border-b pb-6 mb-6">
                                    <div>
                                        <div className="flex items-center gap-3 mb-2">
                                            <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl flex items-center justify-center">
                                                <span className="text-white font-bold text-xl">B</span>
                                            </div>
                                            <div>
                                                <h2 className="text-xl font-bold text-gray-900">{business?.name || 'My Business'}</h2>
                                                <p className="text-sm text-gray-500">{business?.contact?.phone}</p>
                                            </div>
                                        </div>
                                        {business?.address?.city && (
                                            <p className="text-sm text-gray-500">
                                                {business.address.city}, {business.address.state}
                                            </p>
                                        )}
                                    </div>
                                    <div className="text-right">
                                        <h1 className="text-2xl font-bold text-primary-600">INVOICE</h1>
                                        <p className="text-gray-900 font-medium mt-2">{selectedOrder.orderNumber}</p>
                                        <p className="text-sm text-gray-500">{formatDate(selectedOrder.createdAt)}</p>
                                    </div>
                                </div>

                                {/* Bill To */}
                                <div className="mb-6">
                                    <p className="text-sm text-gray-500 uppercase tracking-wider mb-2">Bill To</p>
                                    <p className="font-semibold text-gray-900">{selectedOrder.customerId?.name}</p>
                                    {selectedOrder.customerId?.phone && (
                                        <p className="text-sm text-gray-600">{selectedOrder.customerId.phone}</p>
                                    )}
                                    {selectedOrder.customerId?.email && (
                                        <p className="text-sm text-gray-600">{selectedOrder.customerId.email}</p>
                                    )}
                                </div>

                                {/* Items Table */}
                                <table className="w-full mb-6">
                                    <thead>
                                        <tr className="border-b border-gray-200">
                                            <th className="text-left py-3 text-sm font-semibold text-gray-600">Item</th>
                                            <th className="text-center py-3 text-sm font-semibold text-gray-600">Qty</th>
                                            <th className="text-right py-3 text-sm font-semibold text-gray-600">Price</th>
                                            <th className="text-right py-3 text-sm font-semibold text-gray-600">Total</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {selectedOrder.items?.map((item, index) => (
                                            <tr key={index} className="border-b border-gray-100">
                                                <td className="py-3 text-gray-900">{item.name}</td>
                                                <td className="py-3 text-center text-gray-600">{item.quantity}</td>
                                                <td className="py-3 text-right text-gray-600">{formatCurrency(item.price)}</td>
                                                <td className="py-3 text-right text-gray-900 font-medium">{formatCurrency(item.total)}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>

                                {/* Totals */}
                                <div className="border-t pt-4 space-y-2">
                                    <div className="flex justify-between text-gray-600">
                                        <span>Subtotal</span>
                                        <span>{formatCurrency(selectedOrder.subtotal)}</span>
                                    </div>
                                    {selectedOrder.discount > 0 && (
                                        <div className="flex justify-between text-gray-600">
                                            <span>Discount</span>
                                            <span>-{formatCurrency(selectedOrder.discount)}</span>
                                        </div>
                                    )}
                                    <div className="flex justify-between text-xl font-bold text-gray-900 pt-2 border-t">
                                        <span>Total</span>
                                        <span>{formatCurrency(selectedOrder.total)}</span>
                                    </div>
                                </div>

                                {/* Footer */}
                                <div className="mt-8 pt-6 border-t text-center text-gray-500 text-sm">
                                    <p className="font-medium text-gray-700">Thank you for your business!</p>
                                    <p className="mt-1">Generated by BizNest</p>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <div className="card text-center py-12">
                            <HiDocumentText className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                            <h3 className="text-lg font-medium text-gray-900 mb-2">No invoice selected</h3>
                            <p className="text-gray-500">Select an order from the list to view its invoice</p>
                        </div>
                    )}
                </div>
            </div>

            {/* Print Styles */}
            <style>{`
        @media print {
          body * {
            visibility: hidden;
          }
          #invoice, #invoice * {
            visibility: visible;
          }
          #invoice {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
          }
        }
      `}</style>
        </div>
    );
};

export default Invoices;
