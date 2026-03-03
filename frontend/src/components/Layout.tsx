import React, { useState } from 'react';
import { Outlet, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { useCart } from '@/context/CartContext';
import { ShoppingCart, Menu, X } from 'lucide-react';
import CartDrawer from '@/components/cart/CartDrawer';
import LoginModal from '@/components/auth/LoginModal';

const Layout: React.FC = () => {
    const { user, logout } = useAuth();
    const { totalItems, isCartOpen, setIsCartOpen } = useCart();
    const navigate = useNavigate();
    const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    const handleLogout = () => {
        logout();
        navigate('/');
        setIsMobileMenuOpen(false);
    };

    const toggleMobileMenu = () => setIsMobileMenuOpen(!isMobileMenuOpen);

    const navLinks = [
        {
            to: "/",
            label: "Каталог",
            show: !user || !['supervisor', 'director', 'warehouse', 'driver'].includes(user.role)
        },
        {
            to: "/orders",
            label: (user?.role === 'admin' ? "Админ-панель" : "Мои заказы"),
            show: user?.role === 'client' || user?.role === 'admin'
        },
        {
            to: "/warehouse",
            label: "Панель склада",
            show: user?.role === 'warehouse'
        },
        {
            to: "/driver",
            label: "Панель водителя",
            show: user?.role === 'driver'
        },
        {
            to: "/supervisor",
            label: "Кабинет Супервайзера",
            show: user?.role === 'supervisor'
        },
        {
            to: "/director",
            label: "Кабинет Директора",
            show: user?.role === 'director' || user?.role === 'admin'
        },
        {
            to: "/director/orders",
            label: "Все заказы",
            show: user?.role === 'director' || user?.role === 'admin'
        },
        {
            to: "/admin/warehouses",
            label: "Склады",
            show: user?.role === 'admin'
        },
        {
            to: "/admin/users",
            label: "Сотрудники",
            show: user?.role === 'admin'
        }
    ];

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col">
            <header className="bg-white shadow-sm sticky top-0 z-40">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-20">
                        <div className="flex">
                            <div className="flex-shrink-0 flex items-center">
                                <Link to="/" className="flex items-center overflow-hidden h-20 w-48">
                                    <img
                                        src="/logo.jpg"
                                        alt="DYNAMIX"
                                        className="h-full w-full object-contain scale-[2.2] transform origin-center"
                                    />
                                </Link>
                            </div>
                            {/* Desktop Nav */}
                            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                                {navLinks.filter(l => l.show).map(link => (
                                    <Link
                                        key={link.to}
                                        to={link.to}
                                        className="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
                                    >
                                        {link.label}
                                    </Link>
                                ))}
                            </div>
                        </div>

                        <div className="flex items-center space-x-2">
                            {/* Mobile menu button */}
                            <button
                                onClick={toggleMobileMenu}
                                className="sm:hidden p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none"
                            >
                                {isMobileMenuOpen ? (
                                    <X className="block h-6 w-6" aria-hidden="true" />
                                ) : (
                                    <Menu className="block h-6 w-6" aria-hidden="true" />
                                )}
                            </button>

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
                                <div className="hidden sm:flex items-center space-x-4">
                                    <span className="text-sm text-gray-700 font-medium">
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
                                <div className="hidden sm:block space-x-4">
                                    <button
                                        onClick={() => setIsLoginModalOpen(true)}
                                        className="text-sm font-medium text-white bg-red-600 hover:bg-red-700 px-4 py-2 rounded-md transition-colors"
                                    >
                                        Войти
                                    </button>
                                </div>
                            )}

                            {/* Mobile Login Button when not logged in */}
                            {!user && (
                                <button
                                    onClick={() => setIsLoginModalOpen(true)}
                                    className="sm:hidden text-xs font-medium text-red-600 border border-red-600 px-2 py-1 rounded-md"
                                >
                                    Вход
                                </button>
                            )}
                        </div>
                    </div>
                </div>

                {/* Mobile Menu Panel */}
                {isMobileMenuOpen && (
                    <div className="sm:hidden bg-white border-t border-gray-100 shadow-xl animate-in slide-in-from-top duration-200">
                        <div className="pt-2 pb-3 space-y-1 px-4">
                            {navLinks.filter(l => l.show).map(link => (
                                <Link
                                    key={link.to}
                                    to={link.to}
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-600 hover:bg-gray-50 hover:border-gray-300 hover:text-gray-800"
                                >
                                    {link.label}
                                </Link>
                            ))}
                            {user && (
                                <div className="pt-4 pb-1 border-t border-gray-200 mt-4">
                                    <div className="flex items-center px-3">
                                        <div className="text-base font-medium text-gray-800">{user.email}</div>
                                    </div>
                                    <div className="mt-3 space-y-1">
                                        <Link
                                            to="/profile"
                                            onClick={() => setIsMobileMenuOpen(false)}
                                            className="block px-3 py-2 text-base font-medium text-gray-500 hover:text-gray-800 hover:bg-gray-100"
                                        >
                                            Мой профиль
                                        </Link>
                                        <button
                                            onClick={handleLogout}
                                            className="block w-full text-left px-3 py-2 text-base font-medium text-red-600 hover:text-red-800 hover:bg-red-50"
                                        >
                                            Выйти
                                        </button>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                )}
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
