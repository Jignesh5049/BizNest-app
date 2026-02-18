import { useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Sidebar from './Sidebar';
import { HiMenuAlt3, HiX } from 'react-icons/hi';

const Layout = () => {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const location = useLocation();

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col lg:flex-row">
            {/* Mobile Header */}
            <div className="lg:hidden fixed top-0 left-0 right-0 bg-white border-b border-gray-200 z-40 p-4 flex items-center justify-between">
                <button
                    onClick={() => setSidebarOpen(!sidebarOpen)}
                    className="p-2 text-gray-600 hover:bg-gray-100 rounded-lg"
                >
                    {sidebarOpen ? <HiX className="w-6 h-6" /> : <HiMenuAlt3 className="w-6 h-6" />}
                </button>
                <h2 className="text-lg font-bold text-gray-900">BizNest</h2>
                <div className="w-10" />
            </div>

            {/* Mobile Overlay */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 bg-black/50 lg:hidden z-30"
                    onClick={() => setSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <div className={`fixed left-0 top-0 h-screen w-64 bg-white border-r border-gray-200 z-40 transform transition-transform lg:translate-x-0 lg:static lg:w-64 lg:h-screen lg:flex-shrink-0 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'
                }`}>
                <Sidebar onClose={() => setSidebarOpen(false)} />
            </div>

            {/* Main Content */}
            <main className="flex-1 min-h-screen pt-20 lg:pt-0">
                <div className="p-4 md:p-8">
                    <Outlet />
                </div>
            </main>
        </div>
    );
};

export default Layout;
