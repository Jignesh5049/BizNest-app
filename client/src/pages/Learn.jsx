import { HiAcademicCap, HiLightBulb, HiTrendingUp, HiCurrencyRupee, HiSpeakerphone, HiShoppingCart } from 'react-icons/hi';

const articles = [
    {
        icon: HiCurrencyRupee,
        title: 'Pricing Your Products Right',
        color: 'green',
        tips: [
            'Research what competitors charge for similar products',
            'Factor in ALL costs: materials, time, packaging, delivery',
            'Start with a 30-50% margin for most products',
            'Premium products can have 60-100% margins with right positioning',
            'Test different price points and track what sells best'
        ]
    },
    {
        icon: HiSpeakerphone,
        title: 'Marketing on a Budget',
        color: 'purple',
        tips: [
            'Use WhatsApp Status to showcase new products daily',
            'Create an Instagram page and post consistently',
            'Ask happy customers for reviews and referrals',
            'Offer first-time buyer discounts to attract new customers',
            'Partner with complementary businesses for cross-promotion'
        ]
    },
    {
        icon: HiShoppingCart,
        title: 'Managing Inventory',
        color: 'blue',
        tips: [
            'Track your best-sellers and always keep them in stock',
            'Set reorder points for each product before running out',
            'Review slow-moving items monthly and run clearance sales',
            'Keep a safety stock for your top 20% products',
            'Negotiate better rates with suppliers for bulk orders'
        ]
    },
    {
        icon: HiTrendingUp,
        title: 'Growing Your Business',
        color: 'orange',
        tips: [
            'Focus on customer retention - repeat customers are gold',
            'Expand product range based on customer feedback',
            'Consider delivery options to reach more customers',
            'Build an email/WhatsApp list for promotions',
            'Track your numbers weekly to spot trends early'
        ]
    },
    {
        icon: HiLightBulb,
        title: 'Customer Service Tips',
        color: 'yellow',
        tips: [
            'Respond to inquiries within 1-2 hours during business hours',
            'Handle complaints with empathy and quick solutions',
            'Follow up after purchase to ensure satisfaction',
            'Remember regular customers by name',
            'Surprise loyal customers with small extras occasionally'
        ]
    },
    {
        icon: HiAcademicCap,
        title: 'Business Best Practices',
        color: 'primary',
        tips: [
            'Separate business money from personal finances',
            'Record every transaction, no matter how small',
            'Review finances weekly, analyze monthly',
            'Set aside money for taxes from the start',
            'Invest in quality over quantity for supplies'
        ]
    }
];

const Learn = () => {
    return (
        <div className="space-y-8 animate-fadeIn">
            {/* Header */}
            <div className="text-center max-w-2xl mx-auto">
                <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl shadow-lg mb-4">
                    <HiAcademicCap className="w-8 h-8 text-white" />
                </div>
                <h1 className="text-2xl font-bold text-gray-900">Learning Hub</h1>
                <p className="text-gray-600 mt-2">
                    Quick tips and best practices to help grow your business
                </p>
            </div>

            {/* Articles Grid */}
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                {articles.map((article, index) => (
                    <div key={index} className="card hover:shadow-card-hover">
                        <div className="flex items-center gap-3 mb-4">
                            <div className={`p-3 bg-${article.color}-100 rounded-xl`}>
                                <article.icon className={`w-6 h-6 text-${article.color}-600`} />
                            </div>
                            <h2 className="font-semibold text-gray-900">{article.title}</h2>
                        </div>

                        <ul className="space-y-3">
                            {article.tips.map((tip, tipIndex) => (
                                <li key={tipIndex} className="flex items-start gap-3 text-sm text-gray-600">
                                    <span className={`w-1.5 h-1.5 rounded-full bg-${article.color}-500 mt-2 flex-shrink-0`}></span>
                                    <span>{tip}</span>
                                </li>
                            ))}
                        </ul>
                    </div>
                ))}
            </div>

            {/* Quick Tips Banner */}
            <div className="card bg-gradient-to-r from-primary-500 to-blue-600 text-white">
                <div className="flex items-center gap-4">
                    <div className="p-4 bg-white/20 rounded-xl">
                        <HiLightBulb className="w-8 h-8" />
                    </div>
                    <div>
                        <h3 className="font-bold text-lg">Pro Tip of the Day</h3>
                        <p className="text-primary-100 mt-1">
                            Track your top 3 best-selling products and focus on keeping them in stock.
                            80% of your revenue likely comes from 20% of your products!
                        </p>
                    </div>
                </div>
            </div>

            {/* Resources */}
            <div className="card">
                <h2 className="font-semibold text-gray-900 mb-4">Helpful Resources</h2>
                <div className="grid md:grid-cols-3 gap-4">
                    <a
                        href="https://www.youtube.com/results?search_query=small+business+tips"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                    >
                        <p className="font-medium text-gray-900">📺 YouTube Tutorials</p>
                        <p className="text-sm text-gray-500">Free business education videos</p>
                    </a>
                    <a
                        href="https://www.canva.com"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                    >
                        <p className="font-medium text-gray-900">🎨 Canva</p>
                        <p className="text-sm text-gray-500">Create marketing materials</p>
                    </a>
                    <a
                        href="https://business.whatsapp.com"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="p-4 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors"
                    >
                        <p className="font-medium text-gray-900">💬 WhatsApp Business</p>
                        <p className="text-sm text-gray-500">Professional messaging tools</p>
                    </a>
                </div>
            </div>
        </div>
    );
};

export default Learn;
