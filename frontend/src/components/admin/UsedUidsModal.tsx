import React from 'react';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
} from "@/components/ui/dialog";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { useQuery } from '@tanstack/react-query';
import api from '@/lib/api';
import { Badge } from '@/components/ui/badge';
import { Loader2 } from 'lucide-react';
import { Link } from 'react-router-dom';

interface UsedUidsModalProps {
    productId: string | null;
    isOpen: boolean;
    onClose: () => void;
}

interface UidHistoryEntry {
    uid: string;
    order_id: string;
    client_name: string;
    price: number;
    order_status: string;
    assigned_at: string;
}

const statusMap: Record<string, { label: string; color: string }> = {
    cart: { label: 'Корзина', color: 'bg-gray-100 text-gray-800' },
    contract_review: { label: 'Ознакомление', color: 'bg-blue-100 text-blue-800' },
    pending_director_signature: { label: 'Подпись Директора', color: 'bg-cyan-100 text-cyan-800' },
    pending_signature: { label: 'Подписание', color: 'bg-purple-100 text-purple-800' },
    pending_payment: { label: 'Оплата', color: 'bg-yellow-100 text-yellow-800' },
    payment_review: { label: 'Проверка Оплаты', color: 'bg-orange-100 text-orange-800' },
    paid: { label: 'Оплачен', color: 'bg-green-100 text-green-800' },
    searching_driver: { label: 'Поиск Водителя', color: 'bg-indigo-100 text-indigo-800' },
    driver_assigned: { label: 'Водитель Назначен', color: 'bg-teal-100 text-teal-800' },
    at_warehouse: { label: 'На Складе', color: 'bg-orange-100 text-orange-800' },
    in_transit: { label: 'В Пути', color: 'bg-pink-100 text-pink-800' },
    delivered: { label: 'Доставлен', color: 'bg-green-100 text-green-800' },
    documents_ready: { label: 'Документы Готовы', color: 'bg-blue-100 text-blue-800' },
    completed: { label: 'Завершен', color: 'bg-emerald-100 text-emerald-800' },
    cancelled: { label: 'Отменен', color: 'bg-red-100 text-red-800' }
};

export const UsedUidsModal: React.FC<UsedUidsModalProps> = ({ productId, isOpen, onClose }) => {
    const { data: response, isLoading, error } = useQuery({
        queryKey: ['usedUids', productId],
        queryFn: async () => {
            const res = await api.get(`/api/v1/admin/products/${productId}/used_uids`);
            return res.data;
        },
        enabled: !!productId && isOpen
    });

    const formatCurrency = (amount: number) => {
        return new Intl.NumberFormat('ru-RU', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(amount);
    };

    return (
        <Dialog open={isOpen} onOpenChange={(open) => !open && onClose()}>
            <DialogContent className="max-w-5xl max-h-[85vh] overflow-hidden flex flex-col">
                <DialogHeader>
                    <DialogTitle>
                        История UID
                        {response?.data?.product_name && <span className="text-gray-500 font-normal"> — {response.data.product_name}</span>}
                        {response?.data?.total_used !== undefined && (
                            <Badge variant="secondary" className="ml-3">
                                Всего использовано: {response.data.total_used}
                            </Badge>
                        )}
                    </DialogTitle>
                </DialogHeader>
                <div className="flex-1 overflow-y-auto mt-4 px-1 pb-4">
                    {isLoading ? (
                        <div className="flex bg-white/50 z-10 justify-center items-center h-64">
                            <Loader2 className="h-10 w-10 animate-spin text-blue-500" />
                        </div>
                    ) : error ? (
                        <div className="text-center text-red-500 py-12 bg-red-50 rounded-lg">
                            Ошибка загрузки истории UID
                        </div>
                    ) : response?.data?.history?.length === 0 ? (
                        <div className="text-center text-gray-500 py-12 bg-gray-50 rounded-lg">
                            Этот товар еще не был добавлен ни в один заказ (история пуста).
                        </div>
                    ) : (
                        <div className="rounded-md border shadow-sm">
                            <Table>
                                <TableHeader className="sticky top-0 bg-gray-50 shadow-sm z-10">
                                    <TableRow>
                                        <TableHead className="w-[160px]">UID</TableHead>
                                        <TableHead className="w-[100px]">Заказ</TableHead>
                                        <TableHead>Клиент</TableHead>
                                        <TableHead className="w-[140px]">Цена</TableHead>
                                        <TableHead className="w-[160px]">Статус</TableHead>
                                        <TableHead className="text-right w-[160px]">Назначен</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {response?.data?.history?.map((entry: UidHistoryEntry, index: number) => {
                                        const statusObj = statusMap[entry.order_status] || { label: entry.order_status, color: 'bg-gray-100 text-gray-800' };
                                        return (
                                            <TableRow key={`${entry.uid}-${index}`}>
                                                <TableCell className="font-mono text-xs">{entry.uid}</TableCell>
                                                <TableCell>
                                                    <Link
                                                        to={`/admin/orders/${entry.order_id}`}
                                                        onClick={onClose}
                                                        className="text-blue-600 hover:text-blue-800 hover:underline font-medium"
                                                    >
                                                        #{entry.order_id}
                                                    </Link>
                                                </TableCell>
                                                <TableCell className="max-w-[200px] truncate" title={entry.client_name}>
                                                    {entry.client_name}
                                                </TableCell>
                                                <TableCell className="font-medium">{formatCurrency(entry.price)}</TableCell>
                                                <TableCell>
                                                    <Badge className={`border-none ${statusObj.color}`}>
                                                        {statusObj.label}
                                                    </Badge>
                                                </TableCell>
                                                <TableCell className="text-right text-xs text-gray-500">
                                                    {new Date(entry.assigned_at).toLocaleString('ru-RU', {
                                                        day: '2-digit',
                                                        month: '2-digit',
                                                        year: 'numeric',
                                                        hour: '2-digit',
                                                        minute: '2-digit'
                                                    })}
                                                </TableCell>
                                            </TableRow>
                                        );
                                    })}
                                </TableBody>
                            </Table>
                        </div>
                    )}
                </div>
            </DialogContent>
        </Dialog>
    );
};
