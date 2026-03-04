import React, { createContext, useContext, useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from './AuthContext';
import api from '@/lib/api';

export interface GlobalDiscount {
    percent: number;
    active: boolean;
    valid_until: string | null;
}

export interface CartItem {
    id: string;
    name: string;
    price: number;
    quantity: number;
    image_url: string;
    warehouseId?: string;
}

interface CartContextType {
    items: CartItem[];
    addToCart: (product: any) => void;
    removeFromCart: (productId: string) => void;
    updateQuantity: (productId: string, quantity: number) => void;
    clearCart: () => void;
    totalItems: number;
    totalPrice: number;
    isCartOpen: boolean;
    setIsCartOpen: (isOpen: boolean) => void;
    isBuyback: boolean;
    setIsBuyback: (isBuyback: boolean) => void;
    globalDiscount: GlobalDiscount | null;
    discountAmount: number;
    basePrice: number;
    vatAmount: number;
    finalPrice: number;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const CartProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const { user } = useAuth();
    const [items, setItems] = useState<CartItem[]>([]);
    const [globalDiscount, setGlobalDiscount] = useState<GlobalDiscount | null>(null);

    useEffect(() => {
        api.get('/api/v1/global_discount')
            .then(res => setGlobalDiscount(res.data))
            .catch(err => console.error("Failed to fetch global discount", err));
    }, []);

    const cartKey = user ? `cart_${user.id}` : 'cart_guest';

    useEffect(() => {
        const storedCart = localStorage.getItem(cartKey);
        if (storedCart) {
            setItems(JSON.parse(storedCart));
        } else {
            setItems([]);
        }
    }, [cartKey]);

    useEffect(() => {
        localStorage.setItem(cartKey, JSON.stringify(items));
    }, [items, cartKey]);

    const addToCart = (product: any) => {
        setItems((prevItems) => {
            const existingItem = prevItems.find((item) => item.id === product.id);
            if (existingItem) {
                return prevItems.map((item) =>
                    item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
                );
            }

            const newItem = {
                id: product.id,
                name: product.attributes.name,
                price: parseFloat(product.attributes.price),
                quantity: 1,
                image_url: product.attributes.image_url,
                warehouseId: product.attributes.warehouseId
            };
            toast.success(`${newItem.name} добавлен в корзину`);
            return [...prevItems, newItem];
        });
    };

    const removeFromCart = (productId: string) => {
        setItems((prevItems) => prevItems.filter((item) => item.id !== productId));
    };

    const updateQuantity = (productId: string, quantity: number) => {
        if (quantity <= 0) {
            removeFromCart(productId);
            return;
        }
        setItems((prevItems) =>
            prevItems.map((item) =>
                item.id === productId ? { ...item, quantity } : item
            )
        );
    };

    // Drawer State
    const [isCartOpen, setIsCartOpen] = useState(false);
    const [isBuyback, setIsBuyback] = useState(false);

    useEffect(() => {
        const storedBuyback = localStorage.getItem(`${cartKey}_buyback`);
        if (storedBuyback) {
            setIsBuyback(JSON.parse(storedBuyback));
        } else {
            setIsBuyback(false);
        }
    }, [cartKey]);

    useEffect(() => {
        localStorage.setItem(`${cartKey}_buyback`, JSON.stringify(isBuyback));
    }, [isBuyback, cartKey]);

    const clearCart = () => {
        setItems([]);
        setIsBuyback(false);
        toast.info("Корзина очищена");
    };

    const totalItems = items.reduce((sum, item) => sum + item.quantity, 0);
    const basePrice = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const discountAmount = globalDiscount?.active && globalDiscount.percent > 0
        ? basePrice * (globalDiscount.percent / 100)
        : 0;

    const discountedBase = basePrice - discountAmount;
    const vatAmount = discountedBase * 0.16;
    const finalPrice = discountedBase + vatAmount;

    return (
        <CartContext.Provider value={{
            items,
            addToCart,
            removeFromCart,
            updateQuantity,
            clearCart,
            totalItems,
            totalPrice: basePrice, // Keep totalPrice alias for backwards compatibility
            basePrice,
            isCartOpen,
            setIsCartOpen,
            isBuyback,
            setIsBuyback,
            globalDiscount,
            discountAmount,
            vatAmount,
            finalPrice
        }}>
            {children}
        </CartContext.Provider>
    );
};

export const useCart = () => {
    const context = useContext(CartContext);
    if (context === undefined) {
        throw new Error('useCart must be used within a CartProvider');
    }
    return context;
};
