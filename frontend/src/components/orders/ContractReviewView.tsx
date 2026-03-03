import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { FileText, Download, AlertCircle, Trash2 } from 'lucide-react';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";

interface OrderItem {
    id: string;
    product_name: string;
    quantity: number;
    assigned_uids: string[];
}

interface ContractReviewViewProps {
    order: {
        id: string;
        contract_url: string;
        order_items: OrderItem[];
    };
    onConfirm: () => void;
    onCancel: () => void;
    isConfirming: boolean;
    isCanceling?: boolean;
}

const ContractReviewView: React.FC<ContractReviewViewProps> = ({ order, onConfirm, onCancel, isConfirming, isCanceling }) => {
    const [isCancelModalOpen, setIsCancelModalOpen] = useState(false);
    const [cancelText, setCancelText] = useState('');

    const handleCancelSubmit = () => {
        if (cancelText.trim().toUpperCase() === 'ОТМЕНИТЬ') {
            onCancel();
            setIsCancelModalOpen(false);
            setCancelText('');
        }
    };

    return (
        <div className="space-y-8 animate-in fade-in duration-500">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold flex items-center gap-2">
                        <FileText className="h-6 w-6 text-red-600" />
                        Ознакомление с договором
                    </h2>
                    <p className="text-muted-foreground mt-1">Пожалуйста, проверьте текст договора и назначенные уникальные коды товаров.</p>
                </div>
                <div className="flex gap-2">
                    <Button
                        variant="outline"
                        onClick={() => setIsCancelModalOpen(true)}
                        className="flex items-center gap-2 text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200"
                        disabled={isCanceling}
                    >
                        <Trash2 className="h-4 w-4" />
                        Отменить заказ
                    </Button>
                    <Button
                        variant="outline"
                        onClick={() => order.contract_url && window.open(order.contract_url, '_blank')}
                        className="flex items-center gap-2"
                        disabled={!order.contract_url}
                    >
                        <Download className="h-4 w-4" />
                        Скачать договор
                    </Button>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 space-y-6">
                    {/* PDF Viewer */}
                    <Card className="overflow-hidden border-2 border-gray-100 shadow-lg">
                        <CardHeader className="bg-gray-50 border-b py-3">
                            <CardTitle className="text-sm font-medium flex items-center gap-2">
                                <FileText className="h-4 w-4" />
                                Документ
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="p-0">
                            {order.contract_url ? (
                                <iframe
                                    src={`${order.contract_url}#toolbar=0&navpanes=0`}
                                    className="w-full h-[600px] border-none"
                                    title="Contract Viewer"
                                />
                            ) : (
                                <div className="h-[400px] flex items-center justify-center bg-gray-50 text-gray-400">
                                    Договор еще формируется...
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* UID Table */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Спецификация и UID</CardTitle>
                            <CardDescription>Уникальные коды (UID) закрепленные за вашим заказом</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>Товар</TableHead>
                                        <TableHead className="text-center">Кол-во</TableHead>
                                        <TableHead>Назначенные UID</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {order.order_items.map((item) => (
                                        <TableRow key={item.id}>
                                            <TableCell className="font-medium">{item.product_name}</TableCell>
                                            <TableCell className="text-center">{item.quantity}</TableCell>
                                            <TableCell>
                                                <div className="flex flex-wrap gap-1">
                                                    {item.assigned_uids?.map((uid, idx) => (
                                                        <span key={idx} className="inline-flex items-center px-2 py-0.5 rounded text-xs font-mono bg-blue-50 text-blue-700 border border-blue-100">
                                                            {uid}
                                                        </span>
                                                    ))}
                                                    {(!item.assigned_uids || item.assigned_uids.length === 0) && (
                                                        <span className="text-gray-400 italic text-xs">Коды не назначены</span>
                                                    )}
                                                </div>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        </CardContent>
                    </Card>
                </div>

                <div className="space-y-6">
                    <Card className="border-red-200 bg-red-50 sticky top-24">
                        <CardHeader>
                            <CardTitle className="text-red-900 flex items-center gap-2">
                                <AlertCircle className="h-5 w-5" />
                                Подтверждение
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <p className="text-sm text-red-800 leading-relaxed font-medium">
                                Я ознакомился с договором и уникальные кода всех товаров меня устраивают, и я согласен
                            </p>
                            <Button
                                className="w-full py-8 text-lg bg-red-600 hover:bg-red-700 shadow-xl hover:shadow-2xl transition-all whitespace-normal h-auto leading-tight"
                                onClick={onConfirm}
                                disabled={isConfirming || !order.contract_url}
                            >
                                {isConfirming ? "Обработка..." : "Я ознакомился с договором и уникальные кода всех товаров меня устраивают, и я согласен"}
                            </Button>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Cancel Order Modal */}
            <Dialog open={isCancelModalOpen} onOpenChange={setIsCancelModalOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle className="text-red-600">Отмена заказа</DialogTitle>
                        <DialogDescription>
                            Вы уверены, что хотите отменить этот заказ? Это действие необратимо. Уникальные коды товаров будут отвязаны и возвращены на склад.
                        </DialogDescription>
                    </DialogHeader>
                    <div className="py-4 space-y-4">
                        <p className="text-sm border-l-4 border-red-500 bg-red-50 p-3 rounded text-red-800">
                            Для подтверждения отмены, пожалуйста, введите слово <span className="font-bold tracking-widest bg-white px-1 ml-1 rounded">ОТМЕНИТЬ</span>
                        </p>
                        <Input
                            value={cancelText}
                            onChange={(e) => setCancelText(e.target.value)}
                            placeholder="ОТМЕНИТЬ"
                            className="w-full"
                        />
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsCancelModalOpen(false)}>Назад</Button>
                        <Button
                            variant="destructive"
                            onClick={handleCancelSubmit}
                            disabled={cancelText.trim().toUpperCase() !== 'ОТМЕНИТЬ' || isCanceling}
                        >
                            {isCanceling ? "Отмена..." : "Подтвердить отмену"}
                        </Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default ContractReviewView;
