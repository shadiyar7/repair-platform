import React from 'react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Truck, Shield, ArrowRight, Package } from 'lucide-react';

const HomePage: React.FC = () => {
    return (
        <div className="flex flex-col space-y-20 pb-20">
            {/* Hero Section */}
            <section className="relative py-20 overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-red-50 to-white -z-10" />
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center space-y-8">
                        <Badge variant="secondary" className="px-4 py-1 text-red-600 bg-red-50 border-red-100">
                            B2B Логистика Нового Поколения
                        </Badge>
                        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight text-gray-900">
                            Модернизация <br />
                            <span className="text-red-600">Цепочки Поставок</span>
                        </h1>
                        <p className="max-w-2xl mx-auto text-xl text-gray-600">
                            DYNAMIX — это единая платформа для закупки железнодорожных комплектующих,
                            автоматизированного документооборота и отслеживания логистики в реальном времени.
                        </p>
                        <div className="flex justify-center gap-4">
                            <Button asChild size="lg" className="px-8 py-6 text-lg rounded-full bg-red-600 hover:bg-red-700">
                                <Link to="/catalog">
                                    Перейти в каталог <ArrowRight className="ml-2 h-5 w-5" />
                                </Link>
                            </Button>
                            <Button asChild variant="outline" size="lg" className="px-8 py-6 text-lg rounded-full border-red-200 text-red-600 hover:bg-red-50">
                                <Link to="/register">Создать аккаунт</Link>
                            </Button>
                        </div>
                    </div>
                </div>
            </section>

            {/* Features Section */}
            <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
                    <div className="space-y-4 p-6 rounded-2xl bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                        <div className="h-12 w-12 bg-red-100 rounded-xl flex items-center justify-center text-red-600">
                            <Package className="h-6 w-6" />
                        </div>
                        <h3 className="text-xl font-bold">Умный каталог</h3>
                        <p className="text-gray-600">
                            Управление запасами в реальном времени с автоматической интеграцией 1С для точных цен и остатков.
                        </p>
                    </div>
                    <div className="space-y-4 p-6 rounded-2xl bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                        <div className="h-12 w-12 bg-red-100 rounded-xl flex items-center justify-center text-red-600">
                            <Shield className="h-6 w-6" />
                        </div>
                        <h3 className="text-xl font-bold">Автоматизация iDocs</h3>
                        <p className="text-gray-600">
                            Юридически значимые цифровые контракты и счета, генерируемые мгновенно. Забудьте о бумажной рутине.
                        </p>
                    </div>
                    <div className="space-y-4 p-6 rounded-2xl bg-white border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                        <div className="h-12 w-12 bg-red-100 rounded-xl flex items-center justify-center text-red-600">
                            <Truck className="h-6 w-6" />
                        </div>
                        <h3 className="text-xl font-bold">Логистика 24/7</h3>
                        <p className="text-gray-600">
                            Сквозное отслеживание от склада до двери. Интегрированная сеть водителей для быстрого исполнения.
                        </p>
                    </div>
                </div>
            </section>

            {/* Workflow Section */}
            <section className="bg-gray-900 text-white py-24 rounded-[3rem]">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl md:text-5xl font-bold">Как это работает</h2>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                        {[
                            { step: "01", title: "Заказ", desc: "Выберите компоненты и оформите заказ" },
                            { step: "02", title: "Договор", desc: "Подпишите цифровой контракт через iDocs" },
                            { step: "03", title: "Оплата", desc: "Автоматическая оплата счета 1С" },
                            { step: "04", title: "Доставка", desc: "Отслеживайте доставку в реальном времени" }
                        ].map((item, idx) => (
                            <div key={idx} className="relative space-y-4">
                                <div className="text-4xl font-black text-red-500/30">{item.step}</div>
                                <h4 className="text-xl font-bold">{item.title}</h4>
                                <p className="text-gray-400">{item.desc}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* Stats Section */}
            <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
                    <div>
                        <div className="text-4xl font-bold text-red-600">500+</div>
                        <div className="text-gray-500">Компонентов</div>
                    </div>
                    <div>
                        <div className="text-4xl font-bold text-red-600">10k+</div>
                        <div className="text-gray-500">Доставок</div>
                    </div>
                    <div>
                        <div className="text-4xl font-bold text-red-600">99.9%</div>
                        <div className="text-gray-500">Аптайм</div>
                    </div>
                    <div>
                        <div className="text-4xl font-bold text-red-600">24/7</div>
                        <div className="text-gray-500">Поддержка</div>
                    </div>
                </div>
            </section>
        </div>
    );
};

// Helper component for the landing page
const Badge = ({ children, className }: any) => (
    <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 ${className}`}>
        {children}
    </span>
);

export default HomePage;
