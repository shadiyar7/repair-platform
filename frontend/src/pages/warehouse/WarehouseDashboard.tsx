import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Package, Truck, Clock, CheckCircle } from 'lucide-react';

const WarehouseDashboard: React.FC = () => {
    const queryClient = useQueryClient();

    const { data: orders, isLoading, error } = useQuery({
        queryKey: ['warehouse-orders'],
        queryFn: async () => {
            const response = await api.get('/api/v1/orders');
            return response.data.data;
        }
    });

    const updateStatusMutation = useMutation({
        mutationFn: ({ id, action }: { id: string, action: string }) =>
            api.post(`/api/v1/orders/${id}/${action}`),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['warehouse-orders'] })
    });

    if (isLoading) return <div className="flex justify-center items-center h-64">Загрузка панели склада...</div>;
    if (error) return <div className="text-red-500">Ошибка при загрузке заказов</div>;

    // Filter orders relevant for warehouse
    const ordersList = Array.isArray(orders) ? orders : [];
    const relevantOrders = ordersList.filter((order: any) =>
        ['paid', 'searching_driver', 'driver_assigned', 'at_warehouse'].includes(order.attributes.status)
    );

    const getStatusBadge = (status: string) => {
        const statusMap: Record<string, { label: string, color: string }> = {
            paid: { label: 'Оплачено', color: 'bg-green-100 text-green-800' },
            searching_driver: { label: 'Поиск водителя', color: 'bg-purple-100 text-purple-800' },
            driver_assigned: { label: 'Водитель назначен', color: 'bg-indigo-100 text-indigo-800' },
            at_warehouse: { label: 'На складе', color: 'bg-orange-100 text-orange-800' },
        };
        const config = statusMap[status] || { label: status, color: 'bg-gray-100' };
        return <Badge className={config.color}>{config.label.toUpperCase()}</Badge>;
    };

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div className="flex justify-between items-center">
                <h1 className="text-3xl font-bold tracking-tight">Панель склада</h1>
                <div className="flex items-center space-x-2 text-sm text-muted-foreground">
                    <Package className="h-4 w-4" />
                    <span>{relevantOrders?.length || 0} активных заказов</span>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6">
                {relevantOrders?.length === 0 ? (
                    <Card className="p-12 text-center">
                        <Package className="mx-auto h-12 w-12 text-gray-300" />
                        <h3 className="mt-4 text-lg font-medium">Нет заказов для обработки</h3>
                        <p className="mt-2 text-gray-500">Новые заказы появятся здесь после оплаты.</p>
                    </Card>
                ) : (
                    relevantOrders?.map((order: any) => {
                        const token = order.attributes.smart_link_token;
                        const trackingUrl = `${window.location.origin}/track/${token}`;

                        return (
                            <Card key={order.id} className="overflow-hidden">
                                <div className="p-6">
                                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                                        <div className="space-y-1">
                                            <div className="flex items-center space-x-2">
                                                <span className="font-bold text-lg">Заказ #{order.id}</span>
                                                {getStatusBadge(order.attributes.status)}
                                            </div>
                                            <p className="text-sm text-gray-500">
                                                Клиент: {order.attributes.company_name || 'Частное лицо'}
                                            </p>
                                            <p className="text-sm text-gray-500">
                                                Товары: {order.attributes.order_items?.map((i: any) => `${i.product_name} (x${i.quantity})`).join(', ')}
                                            </p>
                                        </div>

                                        <div className="flex flex-wrap gap-2 items-center">
                                            {/* SMART LINK ACTIONS */}
                                            {token ? (
                                                <div className="flex gap-2 mr-4">
                                                    <Button
                                                        variant="secondary"
                                                        size="sm"
                                                        onClick={() => {
                                                            navigator.clipboard.writeText(trackingUrl);
                                                            alert("Ссылка скопирована!");
                                                        }}
                                                    >
                                                        📋 Скопировать ссылку
                                                    </Button>
                                                    <Button
                                                        className="bg-green-500 hover:bg-green-600 text-white"
                                                        size="sm"
                                                        onClick={() => {
                                                            const text = `Отслеживайте ваш заказ здесь: ${trackingUrl}`;
                                                            window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
                                                        }}
                                                    >
                                                        📱 WhatsApp
                                                    </Button>
                                                </div>
                                            ) : (
                                                <Button
                                                    variant="outline"
                                                    size="sm"
                                                    className="mr-4"
                                                    onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'generate_smart_link' })}
                                                >
                                                    🔗 Создать SmartLink
                                                </Button>
                                            )}

                                            {/* STATUS ACTIONS */}
                                            {order.attributes.status === 'paid' && (
                                                <Button
                                                    className="bg-red-600 hover:bg-red-700"
                                                    onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'find_driver' })}
                                                    disabled={updateStatusMutation.isPending}
                                                >
                                                    <Truck className="mr-2 h-4 w-4" />
                                                    Начать поиск водителя
                                                </Button>
                                            )}

                                            {order.attributes.status === 'searching_driver' && (
                                                <Button
                                                    variant="outline"
                                                    onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'assign_driver_debug' })}
                                                    disabled={updateStatusMutation.isPending}
                                                >
                                                    <Clock className="mr-2 h-4 w-4" />
                                                    Назначить водителя (Демо)
                                                </Button>
                                            )}

                                            {order.attributes.status === 'driver_assigned' && (
                                                <Button
                                                    className="bg-orange-600 hover:bg-orange-700"
                                                    onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'driver_arrived' })}
                                                    disabled={updateStatusMutation.isPending}
                                                >
                                                    <Package className="mr-2 h-4 w-4" />
                                                    Отметить прибытие на склад
                                                </Button>
                                            )}

                                            {order.attributes.status === 'driver_arrived' && (
                                                <Button
                                                    className="bg-blue-600 hover:bg-blue-700"
                                                    onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'start_trip' })}
                                                    disabled={updateStatusMutation.isPending}
                                                >
                                                    <Truck className="mr-2 h-4 w-4" />
                                                    Отправить в путь
                                                </Button>
                                            )}

                                            {order.attributes.status === 'at_warehouse' && (
                                                <div className="flex items-center text-orange-600 font-medium px-4 py-2 bg-orange-50 rounded-md">
                                                    <CheckCircle className="mr-2 h-4 w-4" />
                                                    Готов к выдаче
                                                </div>
                                            )}
                                        </div>
                                    </div>
                                </div>
                            </Card>
                        )
                    })
                )}
            </div>
        </div>
    );
};

export default WarehouseDashboard;
