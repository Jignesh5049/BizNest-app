import { HiX } from 'react-icons/hi';
import { useEffect } from 'react';
import { createPortal } from 'react-dom';

const Modal = ({ isOpen, onClose, title, children, size = 'md' }) => {
    // Prevent body scroll when modal is open
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = 'unset';
        }
        return () => {
            document.body.style.overflow = 'unset';
        };
    }, [isOpen]);

    if (!isOpen) return null;

    const sizeClasses = {
        sm: 'max-w-md',
        md: 'max-w-lg',
        lg: 'max-w-2xl',
        xl: 'max-w-4xl'
    };

    const modalContent = (
        <div
            className="fixed inset-0 overflow-y-auto"
            style={{ zIndex: 99999 }}
        >
            {/* Backdrop - covers entire screen */}
            <div
                className="fixed inset-0 bg-black/50 transition-opacity"
                onClick={onClose}
            ></div>

            {/* Modal Container */}
            <div
                className="fixed inset-0 flex items-center justify-center p-4"
                style={{ zIndex: 100000 }}
            >
                {/* Modal */}
                <div
                    className={`relative bg-white rounded-2xl shadow-2xl ${sizeClasses[size]} w-full animate-fadeIn max-h-[90vh] flex flex-col`}
                    onClick={(e) => e.stopPropagation()}
                >
                    {/* Header */}
                    <div className="flex items-center justify-between p-6 border-b border-gray-100 flex-shrink-0">
                        <h2 className="text-xl font-semibold text-gray-900">{title}</h2>
                        <button
                            onClick={onClose}
                            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
                        >
                            <HiX className="w-5 h-5" />
                        </button>
                    </div>

                    {/* Content */}
                    <div className="p-6 overflow-y-auto flex-1">
                        {children}
                    </div>
                </div>
            </div>
        </div>
    );

    // Use portal to render modal at document body level
    return createPortal(modalContent, document.body);
};

export default Modal;
