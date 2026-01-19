import { useNavigate } from 'react-router-dom';
import { useState } from 'react';
import { useCart } from '@/context/CartContext';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { ShoppingCart, Trash2, X } from 'lucide-react';
import LoginModal from '@/components/auth/LoginModal';

interface CartDrawerProps {
    isOpen: boolean;
    onClose: () => void;
}

const CartDrawer: React.FC<CartDrawerProps> = ({ isOpen, onClose }) => {
    const { items, totalPrice, updateQuantity, removeFromCart } = useCart();
    const { user } = useAuth();
    const navigate = useNavigate();

    const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);

    if (!isOpen) return null;

    const handleCheckout = () => {
        if (!user) {
            setIsLoginModalOpen(true);
        } else {
            onClose();
            navigate('/checkout');
        }
    };

    return (
        <div className="fixed inset-0 z-50 overflow-hidden">
            <div className="absolute inset-0 bg-black bg-opacity-50 transition-opacity" onClick={onClose} />
            <div className="absolute inset-y-0 right-0 max-w-full flex pl-10">
                <div className="w-screen max-w-md">
                    <div className="h-full flex flex-col bg-white shadow-xl">
                        <div className="flex-1 py-6 overflow-y-auto px-4 sm:px-6">
                            <div className="flex items-start justify-between">
                                <h2 className="text-lg font-medium text-gray-900">Корзина</h2>
                                <div className="ml-3 h-7 flex items-center">
                                    <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
                                        <X className="h-6 w-6" />
                                    </button>
                                </div>
                            </div>

                            <div className="mt-8">
                                {items.length === 0 ? (
                                    <div className="text-center py-12">
                                        <ShoppingCart className="mx-auto h-12 w-12 text-gray-400" />
                                        <p className="mt-4 text-gray-500">Ваша корзина пуста</p>
                                    </div>
                                ) : (
                                    <div className="flow-root">
                                        <ul className="-my-6 divide-y divide-gray-200">
                                            {items.map((item) => (
                                                <li key={item.id} className="py-6 flex">
                                                    <div className="flex-1 flex flex-col">
                                                        <div>
                                                            <div className="flex justify-between text-base font-medium text-gray-900">
                                                                <h3>{item.name}</h3>
                                                                <p className="ml-4">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price * item.quantity)}</p>
                                                            </div>
                                                        </div>
                                                        <div className="flex-1 flex items-end justify-between text-sm">
                                                            <div className="flex items-center space-x-2">
                                                                <label htmlFor={`qty-${item.id}`} className="text-gray-500">Кол-во</label>
                                                                <select
                                                                    id={`qty-${item.id}`}
                                                                    value={item.quantity}
                                                                    onChange={(e) => updateQuantity(item.id, parseInt(e.target.value))}
                                                                    className="rounded-md border-gray-300 text-base focus:outline-none focus:ring-red-500 focus:border-red-500 sm:text-sm"
                                                                >
                                                                    {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) => (
                                                                        <option key={n} value={n}>{n}</option>
                                                                    ))}
                                                                </select>
                                                            </div>
                                                            <button
                                                                type="button"
                                                                onClick={() => removeFromCart(item.id)}
                                                                className="font-medium text-red-600 hover:text-red-500 flex items-center"
                                                            >
                                                                <Trash2 className="h-4 w-4 mr-1" />
                                                                Удалить
                                                            </button>
                                                        </div>
                                                    </div>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                )}
                            </div>
                        </div>

                        {items.length > 0 && (
                            <div className="border-t border-gray-200 py-6 px-4 sm:px-6">
                                <div className="flex justify-between text-base font-medium text-gray-900">
                                    <p>Итого</p>
                                    <p>{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(totalPrice)}</p>
                                </div>
                                <p className="mt-0.5 text-sm text-gray-500">Доставка и налоги рассчитываются при оформлении.</p>
                                <div className="mt-6">
                                    <Button onClick={handleCheckout} className="w-full text-base py-6 bg-red-600 hover:bg-red-700">
                                        Оформить заказ
                                    </Button>
                                </div>
                                <div className="mt-6 flex justify-center text-sm text-center text-gray-500">
                                    <p>
                                        или{' '}
                                        <button type="button" className="text-red-600 font-medium hover:text-red-500" onClick={onClose}>
                                            Продолжить покупки<span aria-hidden="true"> &rarr;</span>
                                        </button>
                                    </p>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
            <LoginModal isOpen={isLoginModalOpen} onClose={() => setIsLoginModalOpen(false)} />
        </div>
    );
};

export default CartDrawer;
