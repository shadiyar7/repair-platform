
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { FileText, ArrowLeft } from 'lucide-react';

const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('ru-KZ', {
        style: 'currency',
        currency: 'KZT',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
    }).format(value);
};

const getStatusBadge = (status: string) => {
    const statusMap: Record<string, { label: string, color: string }> = {
        cart: { label: 'Корзина', color: 'bg-gray-100 text-gray-800' },
        contract_review: { label: 'Ознакомление с договором', color: 'bg-blue-100 text-blue-800' },
        pending_director_signature: { label: 'Ожидает подписи директора', color: 'bg-purple-100 text-purple-800' },
        payment_review: { label: 'Проверка оплаты', color: 'bg-yellow-100 text-yellow-800' },
        paid: { label: 'Оплачено', color: 'bg-green-100 text-green-800' },
        searching_driver: { label: 'Поиск водителя', color: 'bg-indigo-100 text-indigo-800' },
        driver_assigned: { label: 'Водитель назначен', color: 'bg-teal-100 text-teal-800' },
        at_warehouse: { label: 'На складе', color: 'bg-orange-100 text-orange-800' },
        in_transit: { label: 'В пути', color: 'bg-blue-100 text-blue-800' },
        delivered: { label: 'Доставлен', color: 'bg-green-100 text-green-800' },
        completed: { label: 'Завершен', color: 'bg-emerald-100 text-emerald-800' },
        cancelled: { label: 'Отменен', color: 'bg-red-100 text-red-800' },
    };
    const config = statusMap[status] || { label: status, color: 'bg-gray-100 text-gray-800' };
    return <Badge className={config.color}>{config.label}</Badge>;
};

const DirectorOrdersPage = () => {
    const navigate = useNavigate();

    const { data: ordersData, isLoading } = useQuery({
        queryKey: ['director', 'all_orders'],
        queryFn: async () => {
            const res = await api.get('/api/v1/orders');
            return res.data;
        }
    });

    const orders = Array.isArray(ordersData?.data) ? ordersData.data : [];

    return (
        <div className="container mx-auto p-6 space-y-8">
            <div className="flex items-center gap-4 mb-6">
                <Button variant="outline" size="icon" onClick={() => navigate('/director')}>
                    <ArrowLeft className="h-4 w-4" />
                </Button>
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Все заказы</h1>
                    <p className="text-gray-500 mt-1">Полный список заказов компании</p>
                </div>
            </div>

            <div className="bg-white rounded-lg shadow border p-4">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Номер заказа</TableHead>
                            <TableHead>Дата создания</TableHead>
                            <TableHead>Клиент / БИН</TableHead>
                            <TableHead>Сумма</TableHead>
                            <TableHead>Статус</TableHead>
                            <TableHead className="text-right">Действия</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {isLoading ? (
                            <TableRow>
                                <TableCell colSpan={6} className="text-center h-24">Загрузка...</TableCell>
                            </TableRow>
                        ) : orders.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={6} className="text-center h-24">Заказов не найдено.</TableCell>
                            </TableRow>
                        ) : (
                            orders.map((order: any) => {
                                const attrs = order.attributes;
                                const companyName = attrs.company_requisite?.company_name || 'Частное лицо';
                                const bin = attrs.company_requisite?.bin;

                                return (
                                    <TableRow key={order.id} className="hover:bg-gray-50">
                                        <TableCell className="font-medium">#{order.id}</TableCell>
                                        <TableCell>
                                            {new Date(attrs.created_at).toLocaleDateString('ru-RU', {
                                                day: '2-digit', month: '2-digit', year: 'numeric',
                                                hour: '2-digit', minute: '2-digit'
                                            })}
                                        </TableCell>
                                        <TableCell>
                                            <div className="font-medium">{companyName}</div>
                                            {bin && <div className="text-xs text-gray-500">БИН: {bin}</div>}
                                        </TableCell>
                                        <TableCell className="font-semibold text-green-600">
                                            {formatCurrency(parseFloat(attrs.total_amount))}
                                        </TableCell>
                                        <TableCell>{getStatusBadge(attrs.status)}</TableCell>
                                        <TableCell className="text-right">
                                            <Button
                                                variant="outline"
                                                size="sm"
                                                onClick={() => navigate(`/orders/${order.id}`)}
                                                className="gap-2"
                                            >
                                                <FileText className="h-4 w-4" />
                                                Детали
                                            </Button>
                                        </TableCell>
                                    </TableRow>
                                );
                            })
                        )}
                    </TableBody>
                </Table>
            </div>
        </div>
    );
};

export default DirectorOrdersPage;
