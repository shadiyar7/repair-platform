import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import api from '@/lib/api';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { ChevronRight, Package } from 'lucide-react';
import { cn } from '@/lib/utils';

const OrdersPage: React.FC = () => {
    const { data: orders = [], isLoading, error } = useQuery({
        queryKey: ['orders'],
        queryFn: async () => {
            const response = await api.get('/api/v1/orders');
            // Safely return array whether it's wrapped in data or not
            return Array.isArray(response.data.data) ? response.data.data : [];
        }
    });

    if (isLoading) return <div className="flex justify-center items-center h-64">Загрузка заказов...</div>;
    if (error) return <div className="text-red-500">Ошибка при загрузке заказов</div>;

    const getStatusBadge = (status: string) => {
        const statusMap: Record<string, { label: string, color: string }> = {
            cart: { label: 'Корзина', color: 'bg-gray-100 text-gray-800' },
            contract_review: { label: 'Ознакомление', color: 'bg-blue-600 text-white shadow-[0_0_10px_rgba(37,99,235,0.2)]' },
            pending_director_signature: { label: 'Подпись директора', color: 'bg-orange-600 text-white' },
            pending_signature: { label: 'Ожидает подписи', color: 'bg-red-600 text-white' },
            pending_payment: { label: 'Ожидает оплаты', color: 'bg-indigo-600 text-white' },
            payment_review: { label: 'Проверка оплаты', color: 'bg-yellow-500 text-white' },
            paid: { label: 'Оплачено', color: 'bg-green-100 text-green-800' },
            searching_driver: { label: 'Поиск водителя', color: 'bg-purple-100 text-purple-800' },
            driver_assigned: { label: 'Водитель назначен', color: 'bg-indigo-100 text-indigo-800' },
            at_warehouse: { label: 'На складе', color: 'bg-yellow-100 text-yellow-800' },
            in_transit: { label: 'В пути', color: 'bg-blue-500 text-white' },
            delivered: { label: 'Доставлено', color: 'bg-green-500 text-white' },
            documents_ready: { label: 'Документы готовы', color: 'bg-green-100 text-green-800' },
            completed: { label: 'Завершено', color: 'bg-gray-900 text-white' },
            cancelled: { label: 'Отменено', color: 'bg-red-100 text-red-800' }
        };
        const config = statusMap[status] || { label: status, color: 'bg-gray-100' };
        return (
            <Badge
                variant="outline"
                className={cn(
                    "border-none shadow-sm pointer-events-none whitespace-nowrap",
                    config.color
                )}
            >
                {config.label.toUpperCase()}
            </Badge>
        );
    };

    return (
        <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-3xl font-bold tracking-tight">Мои заказы</h1>

            {orders?.length === 0 ? (
                <Card className="p-12 text-center">
                    <Package className="mx-auto h-12 w-12 text-gray-400" />
                    <h3 className="mt-4 text-lg font-medium">Заказов пока нет</h3>
                    <p className="mt-2 text-gray-500">Начните покупки в нашем каталоге, чтобы оформить свой первый заказ.</p>
                    <Button asChild className="mt-6 bg-red-600 hover:bg-red-700">
                        <Link to="/catalog">Перейти в каталог</Link>
                    </Button>
                </Card>
            ) : (
                <div className="space-y-4">
                    {orders?.map((order: any) => (
                        <Link key={order.id} to={`/orders/${order.id}`}>
                            <Card className="hover:shadow-md transition-shadow cursor-pointer">
                                <CardContent className="p-6">
                                    <div className="flex items-center justify-between">
                                        <div className="flex items-center space-x-4">
                                            <div className="h-10 w-10 bg-red-50 rounded-full flex items-center justify-center text-red-600">
                                                <Package className="h-5 w-5" />
                                            </div>
                                            <div>
                                                <p className="font-bold text-lg">Заказ #{order.id}</p>
                                                <p className="text-sm text-gray-500">{new Date(order.attributes.created_at).toLocaleDateString()}</p>
                                            </div>
                                        </div>
                                        <div className="flex items-center space-x-4">
                                            <div className="text-right mr-4">
                                                <p className="font-bold text-red-600">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(order.attributes.total_amount)}</p>
                                                <p className="text-xs text-gray-500">{order.attributes.order_items?.length} поз.</p>
                                            </div>
                                            {getStatusBadge(order.attributes.status)}
                                            <ChevronRight className="h-5 w-5 text-gray-400" />
                                        </div>
                                    </div>
                                </CardContent>
                            </Card>
                        </Link>
                    ))}
                </div>
            )}
        </div>
    );
};

export default OrdersPage;
