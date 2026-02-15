import React, { useState } from 'react';
import { Outlet, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { useCart } from '@/context/CartContext';
import { ShoppingCart } from 'lucide-react';
import CartDrawer from '@/components/cart/CartDrawer';
import LoginModal from '@/components/auth/LoginModal';
import api from '@/lib/api';

const Layout: React.FC = () => {
    const { user, logout } = useAuth();
    const { totalItems, isCartOpen, setIsCartOpen } = useCart();
    const navigate = useNavigate();
    // const [isCartOpen, setIsCartOpen] = useState(false); // Moved to Context
    const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);

    const handleLogout = () => {
        logout();
        navigate('/');
    };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col">
            <header className="bg-white shadow-sm sticky top-0 z-40">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-16">
                        <div className="flex">
                            <div className="flex-shrink-0 flex items-center">
                                <Link to="/" className="text-2xl font-black tracking-tighter text-red-600 hover:text-red-700 transition-colors">
                                    DYNAMIX
                                </Link>
                            </div>
                            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                                <Link to="/" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                    Каталог
                                </Link>
                                {user?.role === 'client' && (
                                    <Link to="/orders" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                        Мои заказы
                                    </Link>
                                )}
                                {user?.role === 'warehouse' && (
                                    <Link to="/warehouse" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                        Панель склада
                                    </Link>
                                )}
                                {user?.role === 'driver' && (
                                    <Link to="/driver" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                        Панель водителя
                                    </Link>
                                )}
                                {user?.role === 'admin' && (
                                    <>
                                        <Link to="/orders" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                            Админ-панель
                                        </Link>
                                        <Link to="/admin/warehouses" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                            Склады
                                        </Link>
                                        <Link to="/admin/users" className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium">
                                            Сотрудники
                                        </Link>
                                    </>
                                )}
                            </div>
                        </div>
                        <div className="flex items-center space-x-4">
                            {user && (
                                <button
                                    onClick={async () => {
                                        try {
                                            // Extract order ID from URL if present (e.g. /orders/123)
                                            const match = window.location.pathname.match(/\/orders\/(\d+)/);
                                            const orderId = match ? match[1] : null;

                                            if (!orderId) {
                                                alert('Для теста нужно находиться на странице конкретного заказа (например, /orders/1)');
                                                return;
                                            }

                                            alert(`Отправка тестового запроса в 1С для заказа #${orderId}...`);
                                            const response = await api.post('/api/v1/integrations/one_c/test_trigger', {
                                                order_id: orderId
                                            });
                                            alert(`Успех! Ответ от 1С сохранен в заказ #${orderId}.\nСтатус: ${response.data['1c_status']}\nРазмер PDF: ${response.data.image_length}`);

                                            // Optional: reload page to see changes
                                            if (confirm('Обновить страницу, чтобы увидеть PDF?')) {
                                                window.location.reload();
                                            }
                                        } catch (error: any) {
                                            console.error(error);
                                            alert(`Ошибка: ${error.response?.data?.error || error.message}`);
                                        }
                                    }}
                                    className="px-3 py-1 bg-gray-200 hover:bg-gray-300 text-xs rounded text-gray-700 font-bold"
                                >
                                    Тест отправка 1С
                                </button>
                            )}
                            <button
                                onClick={() => setIsCartOpen(true)}
                                className="relative p-2 text-gray-400 hover:text-gray-500"
                            >
                                <ShoppingCart className="h-6 w-6" />
                                {totalItems > 0 && (
                                    <span className="absolute top-0 right-0 block h-5 w-5 rounded-full bg-red-600 text-white text-xs flex items-center justify-center">
                                        {totalItems}
                                    </span>
                                )}
                            </button>

                            {user ? (
                                <div className="flex items-center space-x-4">
                                    <span className="hidden md:inline text-sm text-gray-700">
                                        {user.company_name || user.email}
                                    </span>
                                    <Link to="/profile" className="text-sm text-gray-500 hover:text-gray-700">
                                        Профиль
                                    </Link>
                                    <button
                                        onClick={handleLogout}
                                        className="text-sm text-red-600 hover:text-red-800"
                                    >
                                        Выход
                                    </button>
                                </div>
                            ) : (
                                <div className="space-x-4">
                                    <button
                                        onClick={() => setIsLoginModalOpen(true)}
                                        className="text-sm font-medium text-white bg-red-600 hover:bg-red-700 px-4 py-2 rounded-md transition-colors"
                                    >
                                        Войти
                                    </button>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </header>

            <CartDrawer isOpen={isCartOpen} onClose={() => setIsCartOpen(false)} />
            <LoginModal isOpen={isLoginModalOpen} onClose={() => setIsLoginModalOpen(false)} />

            <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <Outlet />
            </main>
        </div>
    );
};

export default Layout;
