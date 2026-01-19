import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Truck, MapPin, Package, CheckCircle, Navigation, FileText } from 'lucide-react';

const DriverDashboard: React.FC = () => {
    const queryClient = useQueryClient();

    const { data: orders, isLoading, error } = useQuery({
        queryKey: ['driver-orders'],
        queryFn: async () => {
            const response = await api.get('/api/v1/orders');
            return response.data.data;
        }
    });

    const updateStatusMutation = useMutation({
        mutationFn: ({ id, action }: { id: string, action: string }) =>
            api.post(`/api/v1/orders/${id}/${action}`),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['driver-orders'] })
    });

    if (isLoading) return <div className="flex justify-center items-center h-64">Загрузка панели водителя...</div>;
    if (error) return <div className="text-red-500">Ошибка при загрузке заказов</div>;

    // Filter orders relevant for driver
    const relevantOrders = orders?.filter((order: any) =>
        ['at_warehouse', 'in_transit', 'delivered'].includes(order.attributes.status)
    );

    const getStatusBadge = (status: string) => {
        const statusMap: Record<string, { label: string, color: string }> = {
            at_warehouse: { label: 'На складе', color: 'bg-orange-100 text-orange-800' },
            in_transit: { label: 'В пути', color: 'bg-blue-100 text-blue-800' },
            delivered: { label: 'Доставлено', color: 'bg-green-100 text-green-800' },
        };
        const config = statusMap[status] || { label: status, color: 'bg-gray-100' };
        return <Badge className={config.color}>{config.label.toUpperCase()}</Badge>;
    };

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            <div className="flex justify-between items-center">
                <h1 className="text-3xl font-bold tracking-tight">Панель водителя</h1>
                <div className="flex items-center space-x-2 text-sm text-muted-foreground">
                    <Truck className="h-4 w-4" />
                    <span>{relevantOrders?.length || 0} назначенных доставок</span>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-6">
                {relevantOrders?.length === 0 ? (
                    <Card className="p-12 text-center">
                        <Truck className="mx-auto h-12 w-12 text-gray-300" />
                        <h3 className="mt-4 text-lg font-medium">Нет активных доставок</h3>
                        <p className="mt-2 text-gray-500">Новые доставки появятся здесь после готовности на складе.</p>
                    </Card>
                ) : (
                    relevantOrders?.map((order: any) => (
                        <Card key={order.id} className="overflow-hidden border-l-4 border-l-red-500">
                            <div className="p-6">
                                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                                    <div className="flex-1 space-y-4">
                                        <div className="flex items-center space-x-2">
                                            <span className="font-bold text-xl">Заказ #{order.id}</span>
                                            {getStatusBadge(order.attributes.status)}
                                        </div>

                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                            <div className="flex items-start space-x-2">
                                                <Package className="h-5 w-5 text-gray-400 mt-0.5" />
                                                <div>
                                                    <p className="text-sm font-medium">Место забора</p>
                                                    <p className="text-sm text-gray-600">Главный склад (Алматы)</p>
                                                </div>
                                            </div>
                                            <div className="flex items-start space-x-2">
                                                <MapPin className="h-5 w-5 text-red-500 mt-0.5" />
                                                <div>
                                                    <p className="text-sm font-medium">Адрес доставки</p>
                                                    <p className="text-sm text-gray-600">{order.attributes.delivery_address}</p>
                                                </div>
                                            </div>
                                        </div>

                                        {order.attributes.delivery_notes && (
                                            <div className="bg-gray-50 p-3 rounded-md text-sm text-gray-600 italic">
                                                "{order.attributes.delivery_notes}"
                                            </div>
                                        )}
                                    </div>

                                    <div className="flex flex-col gap-2 min-w-[200px]">
                                        {order.attributes.status === 'at_warehouse' && (
                                            <Button
                                                className="w-full bg-red-600 hover:bg-red-700"
                                                onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'pick_up' })}
                                                disabled={updateStatusMutation.isPending}
                                            >
                                                <Navigation className="mr-2 h-4 w-4" />
                                                Забрать и начать доставку
                                            </Button>
                                        )}

                                        {order.attributes.status === 'in_transit' && (
                                            <Button
                                                className="w-full bg-green-600 hover:bg-green-700"
                                                onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'deliver' })}
                                                disabled={updateStatusMutation.isPending}
                                            >
                                                <CheckCircle className="mr-2 h-4 w-4" />
                                                Отметить как доставлено
                                            </Button>
                                        )}

                                        {order.attributes.status === 'delivered' && (
                                            <Button
                                                className="w-full bg-gray-900 hover:bg-black"
                                                onClick={() => updateStatusMutation.mutate({ id: order.id, action: 'complete' })}
                                                disabled={updateStatusMutation.isPending}
                                            >
                                                <FileText className="mr-2 h-4 w-4" />
                                                Подписать финальные документы
                                            </Button>
                                        )}

                                        <Button variant="outline" className="w-full" onClick={() => window.location.href = `/orders/${order.id}`}>
                                            Подробнее
                                        </Button>
                                    </div>
                                </div>
                            </div>
                        </Card>
                    ))
                )}
            </div>
        </div>
    );
};

export default DriverDashboard;
