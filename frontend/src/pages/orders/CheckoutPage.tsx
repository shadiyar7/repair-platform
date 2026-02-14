import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import { useCart } from '@/context/CartContext';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { ShoppingBag, ArrowLeft, Plus } from 'lucide-react';
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select"

interface CompanyRequisite {
    id: string;
    company_name: string;
    bin: string;
    legal_address: string;
}

const CheckoutPage: React.FC = () => {
    const { items, totalPrice, clearCart } = useCart();
    const { user } = useAuth();
    const navigate = useNavigate();
    const [isLoading, setIsLoading] = useState(false);
    const [requisites, setRequisites] = useState<CompanyRequisite[]>([]);
    const [selectedRequisiteId, setSelectedRequisiteId] = useState<string>('');

    const [formData, setFormData] = useState({
        city: '',
        delivery_address: '',
        // delivery_notes removed as per request
    });

    const CITIES = [
        "Алматы", "Астана", "Шымкент", "Караганда", "Актобе", "Тараз", "Павлодар",
        "Усть-Каменогорск", "Семей", "Атырау", "Костанай", "Кызылорда", "Уральск",
        "Петропавловск", "Актау", "Темиртау", "Туркестан", "Кокшетау", "Тараз", "Талдыкорган"
    ];

    useEffect(() => {
        if (user && user.role === 'client') {
            const fetchRequisites = async () => {
                try {
                    const response = await api.get('/api/v1/company_requisites');
                    const data = response.data.data;
                    const formatted = Array.isArray(data)
                        ? data.map((item: any) => ({ id: item.id, ...item.attributes }))
                        : [];
                    setRequisites(formatted);
                    if (formatted.length > 0) {
                        setSelectedRequisiteId(formatted[0].id);
                    }
                } catch (error) {
                    console.error('Failed to fetch requisites', error);
                }
            };
            fetchRequisites();
        }
    }, [user]);

    if (items.length === 0) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4">
                <ShoppingBag className="h-16 w-16 text-gray-300" />
                <h2 className="text-2xl font-semibold">Ваша корзина пуста</h2>
                <Button onClick={() => navigate('/catalog')} className="bg-red-600 hover:bg-red-700">Вернуться в каталог</Button>
            </div>
        );
    }

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        if (user?.role === 'client' && !selectedRequisiteId) {
            alert('Пожалуйста, выберите компанию для оформления заказа');
            setIsLoading(false);
            return;
        }

        if (!formData.city) {
            alert('Пожалуйста, выберите город');
            setIsLoading(false);
            return;
        }

        try {
            const orderData = {
                order: {
                    city: formData.city,
                    delivery_address: formData.delivery_address,
                    company_requisite_id: selectedRequisiteId,
                    order_items_attributes: items.map(item => ({
                        product_id: item.id,
                        quantity: item.quantity
                    }))
                }
            };

            const response = await api.post('/api/v1/orders', orderData);
            const orderId = response.data.data.id;

            // Automatically trigger checkout transition
            await api.post(`/api/v1/orders/${orderId}/checkout`);

            clearCart();
            navigate(`/orders/${orderId}`);
        } catch (err) {
            console.error('Order creation failed', err);
            alert('Не удалось создать заказ. Пожалуйста, попробуйте еще раз.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <div className="flex items-center space-x-4">
                <Button variant="ghost" size="icon" onClick={() => navigate(-1)}>
                    <ArrowLeft className="h-5 w-5" />
                </Button>
                <h1 className="text-3xl font-bold tracking-tight">Оформление заказа</h1>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div className="md:col-span-2 space-y-6">
                    {/* Company Requisites Selection (Client Only) */}
                    {user?.role === 'client' && (
                        <Card>
                            <CardHeader>
                                <CardTitle>Реквизиты компании</CardTitle>
                                <CardDescription>На какую компанию выставить счет?</CardDescription>
                            </CardHeader>
                            <CardContent>
                                {requisites.length === 0 ? (
                                    <div className="text-center py-4">
                                        <p className="text-sm text-gray-500 mb-4">У вас нет добавленных реквизитов.</p>
                                        <Button onClick={() => navigate('/profile')} variant="outline" className="w-full">
                                            <Plus className="mr-2 h-4 w-4" /> Добавить реквизиты
                                        </Button>
                                    </div>
                                ) : (
                                    <RadioGroup value={selectedRequisiteId} onValueChange={setSelectedRequisiteId}>
                                        <div className="space-y-3">
                                            {requisites.map((req) => (
                                                <div key={req.id} className={`flex items-start space-x-3 p-3 rounded-md border ${selectedRequisiteId === req.id ? 'border-red-600 bg-red-50' : 'border-gray-200'}`}>
                                                    <RadioGroupItem value={req.id} id={req.id} className="mt-1" />
                                                    <div className="flex-1">
                                                        <Label htmlFor={req.id} className="font-medium cursor-pointer">
                                                            {req.company_name}
                                                        </Label>
                                                        <p className="text-xs text-gray-500">БИН: {req.bin}</p>
                                                        <p className="text-xs text-gray-500">{req.legal_address}</p>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </RadioGroup>
                                )}
                            </CardContent>
                        </Card>
                    )}

                    <Card>
                        <CardHeader>
                            <CardTitle>Информация о доставке</CardTitle>
                            <CardDescription>Куда нам доставить ваш заказ?</CardDescription>
                        </CardHeader>
                        <form id="checkout-form" onSubmit={handleSubmit}>
                            <CardContent className="space-y-4">
                                <div className="space-y-2">
                                    <Label>Город</Label>
                                    <Select
                                        value={formData.city}
                                        onValueChange={(value) => setFormData({ ...formData, city: value })}
                                    >
                                        <SelectTrigger>
                                            <SelectValue placeholder="Выберите город" />
                                        </SelectTrigger>
                                        <SelectContent className="max-h-[300px]">
                                            {CITIES.map(city => (
                                                <SelectItem key={city} value={city}>{city}</SelectItem>
                                            ))}
                                        </SelectContent>
                                    </Select>
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="delivery_address">Адрес (Улица, дом, офис/квартира)</Label>
                                    <Input
                                        id="delivery_address"
                                        placeholder="ул. Казыбек би, д. 16, оф. 4"
                                        value={formData.delivery_address}
                                        onChange={(e) => setFormData({ ...formData, delivery_address: e.target.value })}
                                        required
                                    />
                                </div>
                            </CardContent>
                        </form>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Ваш заказ</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ul className="divide-y divide-gray-200">
                                {items.map((item) => (
                                    <li key={item.id} className="py-4 flex justify-between">
                                        <div>
                                            <p className="font-medium">{item.name}</p>
                                            <p className="text-sm text-gray-500">{item.quantity} × {new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price)}</p>
                                        </div>
                                        <p className="font-medium">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price * item.quantity)}</p>
                                    </li>
                                ))}
                            </ul>
                        </CardContent>
                    </Card>
                </div>

                <div className="space-y-6">
                    <Card className="sticky top-24">
                        <CardHeader>
                            <CardTitle>Итого</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div className="flex justify-between text-base">
                                <span>Сумма</span>
                                <span>{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(totalPrice)}</span>
                            </div>
                            <div className="flex justify-between text-base">
                                <span>Доставка</span>
                                <span className="text-green-600 font-medium">Бесплатно</span>
                            </div>
                            <div className="border-t pt-4 flex justify-between text-xl font-bold">
                                <span>К оплате</span>
                                <span className="text-red-600">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(totalPrice)}</span>
                            </div>
                        </CardContent>
                        <CardFooter>
                            <Button
                                type="submit"
                                form="checkout-form"
                                className="w-full py-6 text-lg bg-red-600 hover:bg-red-700"
                                disabled={isLoading}
                            >
                                {isLoading ? 'Обработка...' : 'Оформить заказ'}
                            </Button>
                        </CardFooter>
                    </Card>
                </div>
            </div>
        </div>
    );
};

export default CheckoutPage;
