import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog';
import { Truck, MapPin, Clock, DollarSign, User, Phone } from 'lucide-react';
// import { useAuth } from '@/context/AuthContext';

const SupervisorDashboard: React.FC = () => {
    // const { user } = useAuth(); // Unused
    const queryClient = useQueryClient();
    const [selectedOrder, setSelectedOrder] = useState<any>(null);
    const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);

    // Form State
    const [formData, setFormData] = useState({
        driver_name: '',
        driver_phone: '',
        driver_car_number: '',
        driver_arrival_date: '',
        driver_arrival_time: '',
        delivery_price: '',
        driver_comment: ''
    });

    const { data: ordersData, isLoading } = useQuery({
        queryKey: ['orders'],
        queryFn: async () => {
            const res = await api.get('/api/v1/orders');
            return res.data;
        },
        refetchInterval: 10000 // Refresh every 10s
    });

    const assignDriverMutation = useMutation({
        mutationFn: (data: any) => api.post(`/api/v1/orders/${selectedOrder.id}/assign_driver`, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['orders'] });
            setIsAssignModalOpen(false);
            alert('Водитель успешно назначен!');
        },
        onError: (err: any) => {
            alert('Ошибка назначения: ' + (err.response?.data?.error || 'Неизвестная ошибка'));
        }
    });

    const handleAssignClick = (order: any) => {
        const now = new Date();
        const date = now.toISOString().split('T')[0];
        const time = now.toTimeString().slice(0, 5);

        setSelectedOrder(order);
        setFormData({
            driver_name: '',
            driver_phone: '',
            driver_car_number: '',
            driver_arrival_date: date,
            driver_arrival_time: time,
            delivery_price: '',
            driver_comment: ''
        });
        setIsAssignModalOpen(true);
    };

    const handleSubmit = () => {
        if (!formData.driver_name || !formData.driver_phone || !formData.driver_arrival_date || !formData.driver_arrival_time || !formData.delivery_price) {
            alert('Заполните обязательные поля');
            return;
        }

        assignDriverMutation.mutate({
            driver_name: formData.driver_name,
            driver_phone: formData.driver_phone,
            driver_car_number: formData.driver_car_number,
            driver_arrival_time: `${formData.driver_arrival_date} ${formData.driver_arrival_time}`,
            delivery_price: formData.delivery_price,
            driver_comment: formData.driver_comment
        });
    };

    // Filter only orders waiting for driver
    const ordersList = Array.isArray(ordersData?.data) ? ordersData.data : [];

    // Filter orders waiting for driver (including legacy statuses to be safe)
    const activeOrders = ordersList.filter((order: any) =>
        ['searching_driver', 'payment_review', 'paid'].includes(order.attributes.status)
    );

    if (isLoading) return <div className="p-8 text-center">Загрузка заявок...</div>;

    return (
        <div className="container mx-auto py-8">
            <h1 className="text-3xl font-bold mb-2">Рабочий стол Супервайзера</h1>
            <p className="text-gray-500 mb-8">Заявки, требующие назначения водителя</p>

            {activeOrders.length === 0 ? (
                <div className="text-center py-12 bg-white rounded-lg border border-dashed">
                    <Truck className="mx-auto h-12 w-12 text-gray-300" />
                    <h3 className="mt-2 text-sm font-semibold text-gray-900">Нет активных заявок</h3>
                    <p className="mt-1 text-sm text-gray-500">Сейчас нет заказов в статусе "Поиск водителя".</p>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {activeOrders.map((order: any) => (
                        <Card key={order.id} className="border-l-4 border-l-blue-500 shadow-sm hover:shadow-md transition-shadow">
                            <CardHeader className="pb-3">
                                <div className="flex justify-between items-start">
                                    <Badge variant="secondary" className="mb-2">#{order.id}</Badge>
                                    <Badge className="bg-blue-100 text-blue-800 hover:bg-blue-100">Поиск водителя</Badge>
                                </div>
                                <CardTitle className="text-lg">Заказ из: {order.attributes.origin_city}</CardTitle>
                                <CardDescription className="line-clamp-2">
                                    Куда: {order.attributes.city}, {order.attributes.delivery_address}
                                </CardDescription>
                            </CardHeader>
                            <CardContent className="pb-4 space-y-3 text-sm">
                                <div className="flex items-center text-gray-600">
                                    <MapPin className="mr-2 h-4 w-4" />
                                    <span>{order.attributes.city}</span>
                                </div>
                                <div className="flex items-center text-gray-600">
                                    <Clock className="mr-2 h-4 w-4" />
                                    <span>Создан: {new Date(order.attributes.created_at).toLocaleString('ru-RU')}</span>
                                </div>
                                {order.attributes.order_items && (
                                    <div className="pt-2 border-t">
                                        <p className="font-medium mb-1">Груз:</p>
                                        <ul className="list-disc pl-4 text-xs text-gray-500 space-y-1">
                                            {order.attributes.order_items.map((item: any) => (
                                                <li key={item.id}>
                                                    {item.product_name} x {item.quantity}
                                                </li>
                                            ))}
                                        </ul>
                                    </div>
                                )}
                            </CardContent>
                            <CardFooter>
                                <Button className="w-full bg-blue-600 hover:bg-blue-700" onClick={() => handleAssignClick(order)}>
                                    <Truck className="mr-2 h-4 w-4" /> Найти водителя
                                </Button>
                            </CardFooter>
                        </Card >
                    ))}
                </div >
            )}

            <Dialog open={isAssignModalOpen} onOpenChange={setIsAssignModalOpen}>
                <DialogContent className="max-w-lg">
                    <DialogHeader>
                        <DialogTitle>Назначение водителя (Заказ #{selectedOrder?.id})</DialogTitle>
                        <DialogDescription>
                            Заполните данные водителя и цену доставки. Клиент получит уведомление.
                        </DialogDescription>
                    </DialogHeader>

                    <div className="grid gap-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="driver_name">Имя водителя *</Label>
                                <div className="relative">
                                    <User className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                                    <Input
                                        id="driver_name"
                                        className="pl-9"
                                        placeholder="Иван Иванов"
                                        value={formData.driver_name}
                                        onChange={(e) => setFormData({ ...formData, driver_name: e.target.value })}
                                    />
                                </div>
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="driver_phone">Телефон *</Label>
                                <div className="relative">
                                    <Phone className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                                    <Input
                                        id="driver_phone"
                                        className="pl-9"
                                        placeholder="+7 777 ..."
                                        value={formData.driver_phone}
                                        onChange={(e) => setFormData({ ...formData, driver_phone: e.target.value })}
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="driver_car">Гос. номер (Опционально)</Label>
                            <Input
                                id="driver_car"
                                placeholder="123 ABC 02"
                                value={formData.driver_car_number}
                                onChange={(e) => setFormData({ ...formData, driver_car_number: e.target.value })}
                            />
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="arrival_date">Дата прибытия *</Label>
                                <Input
                                    id="arrival_date"
                                    type="date"
                                    value={formData.driver_arrival_date}
                                    onChange={(e) => setFormData({ ...formData, driver_arrival_date: e.target.value })}
                                />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="arrival_time">Время *</Label>
                                <Input
                                    id="arrival_time"
                                    type="time"
                                    value={formData.driver_arrival_time}
                                    onChange={(e) => setFormData({ ...formData, driver_arrival_time: e.target.value })}
                                />
                            </div>
                            <div className="space-y-2 col-span-2">
                                <Label htmlFor="price">Цена доставки (KZT) *</Label>
                                <div className="relative">
                                    <DollarSign className="absolute left-2.5 top-2.5 h-4 w-4 text-gray-500" />
                                    <Input
                                        id="price"
                                        type="number"
                                        className="pl-9"
                                        placeholder="5000"
                                        value={formData.delivery_price}
                                        onChange={(e) => setFormData({ ...formData, delivery_price: e.target.value })}
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="comment">Комментарий (Виден только складу)</Label>
                            <Input
                                id="comment"
                                placeholder="Например: Заезд с заднего двора"
                                value={formData.driver_comment}
                                onChange={(e) => setFormData({ ...formData, driver_comment: e.target.value })}
                            />
                        </div>
                    </div>

                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsAssignModalOpen(false)}>Отмена</Button>
                        <Button onClick={handleSubmit} disabled={assignDriverMutation.isPending} className="bg-blue-600 text-white">
                            {assignDriverMutation.isPending ? 'Назначение...' : 'Назначить и уведомить'}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div >
    );
};

export default SupervisorDashboard;
