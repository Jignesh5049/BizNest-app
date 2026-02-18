import { useState } from 'react';
import { formatCurrency, calculateMargin } from '../utils/helpers';
import { HiCalculator, HiCurrencyRupee, HiTrendingUp, HiLightBulb } from 'react-icons/hi';

const Pricing = () => {
    const [costPrice, setCostPrice] = useState('');
    const [desiredMargin, setDesiredMargin] = useState(30);
    const [sellingPrice, setSellingPrice] = useState('');
    const [mode, setMode] = useState('margin'); // 'margin' or 'price'

    const calculateFromMargin = () => {
        if (!costPrice) return { recommendedPrice: 0, profit: 0, margin: 0 };
        const cost = parseFloat(costPrice);
        const recommendedPrice = cost * (1 + desiredMargin / 100);
        const profit = recommendedPrice - cost;
        return { recommendedPrice, profit, margin: desiredMargin };
    };

    const calculateFromPrice = () => {
        if (!costPrice || !sellingPrice) return { profit: 0, margin: 0 };
        const cost = parseFloat(costPrice);
        const sell = parseFloat(sellingPrice);
        const profit = sell - cost;
        const margin = ((sell - cost) / cost) * 100;
        return { profit, margin };
    };

    const result = mode === 'margin' ? calculateFromMargin() : calculateFromPrice();

    const marginTips = [
        { range: '0-20%', label: 'Low margin', color: 'red', tip: 'Consider if volume makes up for thin margins' },
        { range: '20-40%', label: 'Standard margin', color: 'yellow', tip: 'Healthy for most retail businesses' },
        { range: '40-60%', label: 'Good margin', color: 'green', tip: 'Great profitability, maintain quality' },
        { range: '60%+', label: 'Premium margin', color: 'blue', tip: 'Ensure value justifies the premium' }
    ];

    const getMarginLevel = (margin) => {
        if (margin < 20) return marginTips[0];
        if (margin < 40) return marginTips[1];
        if (margin < 60) return marginTips[2];
        return marginTips[3];
    };

    const marginLevel = getMarginLevel(result.margin);

    return (
        <div className="space-y-8 animate-fadeIn max-w-4xl mx-auto">
            {/* Header */}
            <div className="text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl shadow-lg mb-4">
                    <HiCalculator className="w-8 h-8 text-white" />
                </div>
                <h1 className="text-2xl font-bold text-gray-900">Smart Pricing Calculator</h1>
                <p className="text-gray-600 mt-2">Find the perfect price for your products</p>
            </div>

            {/* Mode Toggle */}
            <div className="flex justify-center">
                <div className="bg-gray-100 p-1 rounded-xl inline-flex">
                    <button
                        onClick={() => setMode('margin')}
                        className={`px-6 py-2 rounded-lg font-medium transition-all ${mode === 'margin' ? 'bg-white shadow text-primary-600' : 'text-gray-600'
                            }`}
                    >
                        Calculate Price from Margin
                    </button>
                    <button
                        onClick={() => setMode('price')}
                        className={`px-6 py-2 rounded-lg font-medium transition-all ${mode === 'price' ? 'bg-white shadow text-primary-600' : 'text-gray-600'
                            }`}
                    >
                        Calculate Margin from Price
                    </button>
                </div>
            </div>

            {/* Calculator Card */}
            <div className="card">
                <div className="grid md:grid-cols-2 gap-8">
                    {/* Input Section */}
                    <div className="space-y-6">
                        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                            <HiCurrencyRupee className="w-5 h-5 text-primary-500" />
                            Enter Details
                        </h3>

                        <div>
                            <label className="label">Cost Price (Your Purchase Price) *</label>
                            <div className="relative">
                                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">₹</span>
                                <input
                                    type="number"
                                    value={costPrice}
                                    onChange={(e) => setCostPrice(e.target.value)}
                                    className="input pl-10 text-lg"
                                    placeholder="0"
                                    min="0"
                                    step="0.01"
                                />
                            </div>
                        </div>

                        {mode === 'margin' ? (
                            <div>
                                <label className="label">Desired Profit Margin: {desiredMargin}%</label>
                                <input
                                    type="range"
                                    value={desiredMargin}
                                    onChange={(e) => setDesiredMargin(parseInt(e.target.value))}
                                    className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-primary-500"
                                    min="5"
                                    max="100"
                                    step="5"
                                />
                                <div className="flex justify-between text-xs text-gray-500 mt-1">
                                    <span>5%</span>
                                    <span>50%</span>
                                    <span>100%</span>
                                </div>
                            </div>
                        ) : (
                            <div>
                                <label className="label">Selling Price *</label>
                                <div className="relative">
                                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500">₹</span>
                                    <input
                                        type="number"
                                        value={sellingPrice}
                                        onChange={(e) => setSellingPrice(e.target.value)}
                                        className="input pl-10 text-lg"
                                        placeholder="0"
                                        min="0"
                                        step="0.01"
                                    />
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Result Section */}
                    <div className="space-y-6">
                        <h3 className="font-semibold text-gray-900 flex items-center gap-2">
                            <HiTrendingUp className="w-5 h-5 text-green-500" />
                            Results
                        </h3>

                        {mode === 'margin' && (
                            <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-2xl p-6 text-white">
                                <p className="text-green-100 text-sm">Recommended Selling Price</p>
                                <p className="text-4xl font-bold mt-1">{formatCurrency(result.recommendedPrice)}</p>
                            </div>
                        )}

                        <div className="grid grid-cols-2 gap-4">
                            <div className="bg-gray-50 rounded-xl p-4 text-center">
                                <p className="text-sm text-gray-500">Profit per Unit</p>
                                <p className="text-2xl font-bold text-green-600">{formatCurrency(result.profit)}</p>
                            </div>
                            <div className="bg-gray-50 rounded-xl p-4 text-center">
                                <p className="text-sm text-gray-500">Profit Margin</p>
                                <p className="text-2xl font-bold text-primary-600">{result.margin.toFixed(1)}%</p>
                            </div>
                        </div>

                        {/* Margin Level Indicator */}
                        {costPrice && (
                            <div className={`bg-${marginLevel.color}-50 border border-${marginLevel.color}-200 rounded-xl p-4`}>
                                <div className="flex items-start gap-3">
                                    <HiLightBulb className={`w-5 h-5 text-${marginLevel.color}-500 mt-0.5`} />
                                    <div>
                                        <p className={`font-medium text-${marginLevel.color}-800`}>
                                            {marginLevel.label} ({marginLevel.range})
                                        </p>
                                        <p className={`text-sm text-${marginLevel.color}-600 mt-1`}>{marginLevel.tip}</p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Tips Section */}
            <div className="card bg-gradient-to-r from-primary-50 to-blue-50">
                <h3 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                    <HiLightBulb className="w-5 h-5 text-primary-500" />
                    Pricing Tips
                </h3>
                <div className="grid md:grid-cols-2 gap-4 text-sm text-gray-600">
                    <div className="flex items-start gap-2">
                        <span className="text-primary-500">•</span>
                        <p>Consider your competition's pricing before setting yours</p>
                    </div>
                    <div className="flex items-start gap-2">
                        <span className="text-primary-500">•</span>
                        <p>Factor in all costs: packaging, delivery, returns</p>
                    </div>
                    <div className="flex items-start gap-2">
                        <span className="text-primary-500">•</span>
                        <p>Test different price points to find customer sweet spot</p>
                    </div>
                    <div className="flex items-start gap-2">
                        <span className="text-primary-500">•</span>
                        <p>Premium products can have higher margins with right positioning</p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Pricing;
