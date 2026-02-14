import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
import { Download, CheckCircle, CreditCard, Truck, Clock, MapPin, FileText, User, Info, AlertCircle, Building } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';

const OrderDetailPage: React.FC = () => {
    const { id } = useParams();
    const { user } = useAuth();
    const queryClient = useQueryClient();
    const [isDriverModalOpen, setIsDriverModalOpen] = useState(false);
    const [driverForm, setDriverForm] = useState({ name: '', phone: '', car: '', time: '' });

    const { data: order, isLoading, error } = useQuery({
        queryKey: ['order', id],
        queryFn: async () => {
            const response = await api.get(`/api/v1/orders/${id}`);
            return response.data.data;
        }
    });

    const mutationOptions = {
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['order', id] })
    };

    const signContractMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/sign_contract`), ...mutationOptions });
    const directorSignMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/director_sign`), ...mutationOptions });
    const payMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/pay`), ...mutationOptions });
    const findDriverMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/find_driver`), ...mutationOptions });

    // Real driver assignment
    const assignDriverMutation = useMutation({
        mutationFn: (data: any) => api.post(`/api/v1/orders/${id}/assign_driver`, data),
        ...mutationOptions,
        onSuccess: () => {
            mutationOptions.onSuccess();
            setIsDriverModalOpen(false);
        }
    });

    const arriveMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/driver_arrived`), ...mutationOptions });
    const transitMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/start_trip`), ...mutationOptions });
    const deliverMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/deliver`), ...mutationOptions });
    // const completeMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/complete`), ...mutationOptions });


    if (isLoading) return <div className="flex justify-center items-center h-64">Загрузка деталей заказа...</div>;
    if (error) return <div className="text-red-500">Ошибка при загрузке заказа</div>;

    const attributes = order.attributes;

    const steps = [
        // Hidden steps: cart, requisites_selected
        { id: 'pending_director_signature', label: 'Подпись Директора', icon: FileText },
        { id: 'pending_signature', label: 'Договор Клиента', icon: FileText },
        { id: 'pending_payment', label: 'Оплата', icon: CreditCard },
        { id: 'paid', label: 'Лист ожидания', icon: Clock },
        { id: 'searching_driver', label: 'Поиск водителя', icon: User },
        { id: 'driver_assigned', label: 'Водитель назначен', icon: Truck },
        { id: 'at_warehouse', label: 'На складе', icon: Building },
        { id: 'in_transit', label: 'В пути', icon: MapPin },
        { id: 'delivered', label: 'Доставлен', icon: CheckCircle },
        // Hidden steps: documents_ready, completed
    ];

    let currentStepIndex = steps.findIndex(s => s.id === attributes.status);

    // Handle hidden statuses mapping to visible steps
    if (attributes.status === 'documents_ready' || attributes.status === 'completed') {
        currentStepIndex = steps.length - 1; // Show as fully completed (last step)
    } else if (attributes.status === 'cart' || attributes.status === 'requisites_selected') {
        currentStepIndex = -1; // Before first step
    }

    const getStatusBadge = (status: string) => {
        const config: Record<string, string> = {
            draft: 'bg-gray-100 text-gray-800',
            pending_director_signature: 'bg-orange-600 text-white',
            pending_signature: 'bg-red-600 text-white',
            pending_payment: 'bg-indigo-600 text-white',
            paid: 'bg-green-100 text-green-800',
            searching_driver: 'bg-purple-100 text-purple-800',
            driver_assigned: 'bg-indigo-100 text-indigo-800',
            at_warehouse: 'bg-yellow-100 text-yellow-800',
            in_transit: 'bg-blue-500 text-white',
            delivered: 'bg-green-500 text-white',
            completed: 'bg-gray-900 text-white',
            cancelled: 'bg-red-100 text-red-800'
        };
        const color = config[status] || 'bg-gray-100';
        return <Badge className={color}>{status.toUpperCase()}</Badge>;
    };

    const downloadFile = async (type: 'invoice' | 'contract') => {
        // Use Base64 Invoice from 1C if available and type is invoice
        if (type === 'invoice' && attributes.invoice_base64) {
            try {
                const byteCharacters = atob(attributes.invoice_base64);
                const byteNumbers = new Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                const byteArray = new Uint8Array(byteNumbers);
                const blob = new Blob([byteArray], { type: 'application/pdf' });
                const url = URL.createObjectURL(blob);
                window.open(url, '_blank');
            } catch (e) {
                console.error("Failed to parse Base64 invoice", e);
                alert("Ошибка при открытии счета от 1С.");
            }
            return;
        }

        try {
            const response = await api.get(`/api/v1/orders/${id}/download_${type}`, {
                responseType: 'blob'
            });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `${type === 'invoice' ? 'Счет' : 'Договор'}_${id}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
        } catch (err) {
            console.error(`Failed to download ${type}`, err);
            alert(`Ошибка при скачивании ${type === 'invoice' ? 'счета' : 'договора'}. Попробуйте еще раз.`);
        }
    };

    const getActionBanner = () => {
        if (!attributes) return null;
        const status = attributes.status;
        const role = user?.role;

        let title = '';
        let description = '';
        let type: 'warning' | 'info' | 'success' | 'default' = 'default';

        switch (status) {
            case 'pending_director_signature':
                if (role === 'client' || role === 'director' || role === 'admin') {
                    title = 'Требуется подписание договора';
                    description = 'Договор сформирован. Пожалуйста, проверьте и подпишите его.';
                    type = 'warning';
                } else {
                    title = 'Ожидание подписания';
                    description = 'Клиент должен подписать договор.';
                    type = 'info';
                }
                break;
            case 'pending_signature':
                if (role === 'client') {
                    title = 'Требуется действие: Подписание договора';
                    description = 'Для начала работы необходимо скачать и подписать договор.';
                    type = 'warning';
                } else {
                    title = 'Ожидание клиента';
                    description = 'Клиент должен подписать договор.';
                    type = 'info';
                }
                break;
            case 'pending_payment':
                if (role === 'client') {
                    title = 'Требуется действие: Оплата заказа';
                    description = 'Договор подписан. Пожалуйста, оплатите счет для начала отгрузки.';
                    type = 'warning';
                } else {
                    title = 'Ожидание оплаты';
                    description = 'Клиент должен оплатить заказ.';
                    type = 'info';
                }
                break;
            case 'paid':
                title = 'Заказ оплачен';
                description = 'Заказ передан логистам для поиска водителя.';
                type = 'success';
                break;
            case 'searching_driver':
                title = 'Поиск водителя';
                description = 'Логисты ищут подходящего водителя через Della.kz.';
                type = 'info';
                break;
            case 'driver_assigned':
                title = 'Водитель назначен';
                description = 'Водитель едет на склад для загрузки.';
                type = 'info';
                break;
            case 'at_warehouse':
                title = 'На складе';
                description = 'Водитель прибыл. Идет процесс погрузки и оформления документов.';
                type = 'info';
                break;
            case 'in_transit':
                title = 'В пути';
                description = 'Груз отправлен к клиенту.';
                type = 'info';
                break;
            default:
                return null;
        }

        const colors = {
            warning: 'bg-amber-50 border-amber-500 text-amber-900',
            info: 'bg-blue-50 border-blue-500 text-blue-900',
            success: 'bg-green-50 border-green-500 text-green-900',
            default: 'bg-gray-50 border-gray-500 text-gray-900'
        };

        return (
            <div className={`border-l-4 p-4 rounded-r shadow-sm flex items-start space-x-3 ${colors[type]}`}>
                <AlertCircle className="w-5 h-5 mt-0.5 flex-shrink-0" />
                <div>
                    <h3 className="font-bold text-sm">{title}</h3>
                    <p className="text-sm mt-1 opacity-90">{description}</p>
                </div>
            </div>
        );
    };

    const WorkflowGuide = () => (
        <div className="space-y-4 text-sm">
            <p>Процесс выполнения заказа состоит из следующих этапов:</p>
            <ol className="list-decimal pl-4 space-y-2 text-gray-700">
                <li><span className="font-semibold">Реквизиты:</span> Выбор компании плательщика.</li>
                <li><span className="font-semibold">Договор:</span> Генерация и подписание договора поставки.</li>
                <li><span className="font-semibold">Оплата:</span> Выставление счета (Invoice) и ожидание оплаты.</li>
                <li><span className="font-semibold">Поиск водителя:</span> Логисты ищут машину через интеграции (Della).</li>
                <li><span className="font-semibold">Склад:</span> Водитель прибывает, загружается, получает накладные.</li>
                <li><span className="font-semibold">В пути:</span> Отслеживание движения груза.</li>
                <li><span className="font-semibold">Завершен:</span> Получение груза, обмен закрывающими документами.</li>
            </ol>
            <div className="bg-gray-50 p-3 rounded text-xs text-gray-500 mt-4">
                Примечание: На каждом этапе система уведомляет соответствующих участников (Клиент, Склад, Водитель, Админ).
            </div>
        </div>
    );

    return (
        <div className="max-w-6xl mx-auto space-y-8 pb-12">
            <div className="flex justify-between items-center">
                <div className="space-y-1">
                    <div className="flex items-center gap-2">
                        <h1 className="text-3xl font-bold tracking-tight">Заказ #{id?.slice(0, 8)}...</h1>
                        <Dialog>
                            <DialogTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 hover:text-gray-600">
                                    <Info className="h-4 w-4" />
                                </Button>
                            </DialogTrigger>
                            <DialogContent>
                                <DialogHeader>
                                    <DialogTitle>Как работает процесс выполнения заказа?</DialogTitle>
                                </DialogHeader>
                                <WorkflowGuide />
                            </DialogContent>
                        </Dialog>
                    </div>
                    <p className="text-muted-foreground">Оформлен {new Date(attributes.created_at).toLocaleDateString()}</p>
                </div>
                {getStatusBadge(attributes.status)}
            </div>

            {getActionBanner()}

            {/* Stepper */}
            {/* Stepper */}
            <div className="relative pt-4">
                {/* Background Line */}
                <div className="absolute top-8 left-0 w-full h-1 bg-gray-100 -z-10 rounded-full" />

                {/* Progress Line (Red) */}
                <div
                    className="absolute top-8 left-0 h-1 bg-red-600 -z-10 transition-all duration-500 rounded-full"
                    style={{ width: `${(currentStepIndex / (steps.length - 1)) * 100}%` }}
                />

                <div className="flex justify-between items-start overflow-visible pb-4 px-2">
                    {steps.map((step, index) => {
                        const isActive = index === currentStepIndex;
                        const isCompleted = index < currentStepIndex;

                        return (
                            <div key={step.id} className="flex flex-col items-center min-w-[60px] relative group">
                                <div className={`w-10 h-10 rounded-full flex items-center justify-center mb-2 z-10 transition-all duration-300 font-bold text-sm border-2 ${isActive
                                    ? 'bg-red-600 border-red-600 text-white scale-125 shadow-lg ring-4 ring-red-100'
                                    : isCompleted
                                        ? 'bg-red-600 border-red-600 text-white'
                                        : 'bg-white border-gray-200 text-gray-300'
                                    }`}>
                                    {isCompleted ? <CheckCircle className="h-5 w-5" /> : <span>{index + 1}</span>}
                                </div>

                                <span className={`text-[10px] sm:text-xs text-center font-medium px-1 leading-tight max-w-[80px] transition-colors ${isActive
                                    ? 'text-red-700 font-bold'
                                    : isCompleted
                                        ? 'text-red-600'
                                        : 'text-gray-400'
                                    }`}>
                                    {step.label}
                                </span>
                            </div>
                        );
                    })}
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div className="md:col-span-2 space-y-6">
                    <Card>
                        <CardHeader>
                            <CardTitle>Состав заказа</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ul className="divide-y divide-gray-200">
                                {attributes.order_items?.map((item: any) => (
                                    <li key={item.id} className="py-4 flex justify-between">
                                        <div className="flex items-center space-x-4">
                                            <div>
                                                <p className="font-medium">{item.product_name}</p>
                                                <p className="text-sm text-gray-500">Кол-во: {item.quantity}</p>
                                            </div>
                                        </div>
                                        <p className="font-medium">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price * item.quantity)}</p>
                                    </li>
                                ))}
                            </ul>
                            <div className="border-t mt-4 pt-4 flex justify-between text-lg font-bold">
                                <span>Итоговая сумма</span>
                                <span className="text-red-600">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(attributes.total_amount)}</span>
                            </div>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Детали доставки</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            <div>
                                <p className="text-sm font-medium text-gray-500">Адрес</p>
                                <p>{attributes.delivery_address}</p>
                            </div>
                            {/* Show Requisite used if available */}
                            {attributes.company_requisite && (
                                <div>
                                    <p className="text-sm font-medium text-gray-500">Компания (Плательщик)</p>
                                    <p>{attributes.company_requisite.company_name} (БИН: {attributes.company_requisite.bin})</p>
                                </div>
                            )}
                            {attributes.delivery_notes && (
                                <div>
                                    <p className="text-sm font-medium text-gray-500">Комментарии</p>
                                    <p>{attributes.delivery_notes}</p>
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                <div className="space-y-6">
                    <Card className="sticky top-24">
                        <CardHeader>
                            <CardTitle>Действия</CardTitle>
                            <CardDescription>Необходимые шаги для обработки заказа</CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            {/* Client Actions */}
                            {attributes.status === 'pending_director_signature' && (user?.role === 'client' || user?.role === 'director' || user?.role === 'admin') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-orange-50 border border-orange-100 rounded-md flex items-start space-x-3">
                                        <FileText className="h-5 w-5 text-orange-600 mt-0.5" />
                                        <p className="text-sm text-orange-700">Договор готов. Скачайте для ознакомления или подпишите для продолжения.</p>
                                    </div>
                                    <Button className="w-full bg-orange-600 hover:bg-orange-700" onClick={() => directorSignMutation.mutate()} disabled={directorSignMutation.isPending}>
                                        {directorSignMutation.isPending ? (
                                            <>
                                                <Clock className="mr-2 h-4 w-4 animate-spin" /> Подписание...
                                            </>
                                        ) : (
                                            <>
                                                <CheckCircle className="mr-2 h-4 w-4" /> Подписать договор
                                            </>
                                        )}
                                    </Button>
                                    <Button variant="outline" className="w-full" onClick={() => downloadFile('contract')}>
                                        <Download className="mr-2 h-4 w-4" /> Скачать договор
                                    </Button>
                                </div>
                            )}

                            {attributes.status === 'pending_signature' && (user?.role === 'client' || user?.role === 'admin') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-red-50 border border-red-100 rounded-md flex items-start space-x-3">
                                        <AlertCircle className="h-5 w-5 text-red-600 mt-0.5" />
                                        <p className="text-sm text-red-700">Директор подписал. Теперь ваша очередь.</p>
                                    </div>
                                    <Button className="w-full bg-red-600 hover:bg-red-700" onClick={() => signContractMutation.mutate()} disabled={signContractMutation.isPending}>
                                        {signContractMutation.isPending ? (
                                            <>
                                                <div className="flex items-center gap-2">
                                                    <Clock className="h-4 w-4 animate-spin" />
                                                    <span>Обработка 1С...</span>
                                                </div>
                                            </>
                                        ) : (
                                            <>
                                                <CheckCircle className="mr-2 h-4 w-4" /> Подписать договор (Клиент)
                                            </>
                                        )}
                                    </Button>
                                    <Button variant="outline" className="w-full" onClick={() => downloadFile('contract')}>
                                        <Download className="mr-2 h-4 w-4" /> Просмотреть договор
                                    </Button>
                                </div>
                            )}

                            {attributes.status === 'pending_payment' && (user?.role === 'client' || user?.role === 'admin') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-blue-50 border border-blue-100 rounded-md flex items-start space-x-3">
                                        <CreditCard className="h-5 w-5 text-blue-600 mt-0.5" />
                                        <p className="text-sm text-blue-700">Ожидается оплата. Скачайте счет и оплатите его.</p>
                                    </div>
                                    <Button
                                        variant="outline"
                                        className="w-full"
                                        onClick={() => downloadFile('invoice')}
                                        disabled={!attributes.invoice_base64} // Disable until 1C returns the invoice
                                    >
                                        <Download className="mr-2 h-4 w-4" />
                                        {attributes.invoice_base64 ? "Скачать счет (1C)" : "Ожидание счета от 1С..."}
                                    </Button>
                                    <Button className="w-full bg-red-600 hover:bg-red-700" onClick={() => payMutation.mutate()} disabled={payMutation.isPending}>
                                        <CreditCard className="mr-2 h-4 w-4" /> Оплатить (Демо)
                                    </Button>
                                </div>
                            )}

                            {/* Logistics / Admin Actions */}
                            {attributes.status === 'paid' && (user?.role === 'admin' || user?.role === 'warehouse') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-green-50 border border-green-100 rounded-md">
                                        <p className="text-sm text-green-700">Заказ оплачен. Необходимо найти водителя.</p>
                                    </div>
                                    <Button className="w-full" onClick={() => findDriverMutation.mutate()} disabled={findDriverMutation.isPending}>
                                        <User className="mr-2 h-4 w-4" /> Начать поиск водителя
                                    </Button>
                                </div>
                            )}

                            {attributes.status === 'searching_driver' && (user?.role === 'admin' || user?.role === 'warehouse') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-purple-50 border border-purple-100 rounded-md">
                                        <p className="text-sm text-purple-700 animate-pulse">Идет активный поиск водителя (Della.kz)...</p>
                                    </div>

                                    <Dialog open={isDriverModalOpen} onOpenChange={setIsDriverModalOpen}>
                                        <DialogTrigger asChild>
                                            <Button className="w-full bg-purple-600 hover:bg-purple-700">
                                                <User className="mr-2 h-4 w-4" /> Водитель найден
                                            </Button>
                                        </DialogTrigger>
                                        <DialogContent>
                                            <DialogHeader>
                                                <DialogTitle>Назначение водителя</DialogTitle>
                                            </DialogHeader>
                                            <div className="space-y-4 py-4">
                                                <div className="space-y-2">
                                                    <Label>Имя водителя</Label>
                                                    <Input
                                                        value={driverForm.name}
                                                        onChange={(e) => setDriverForm({ ...driverForm, name: e.target.value })}
                                                        placeholder="Иван Иванов"
                                                    />
                                                </div>
                                                <div className="space-y-2">
                                                    <Label>Телефон</Label>
                                                    <Input
                                                        value={driverForm.phone}
                                                        onChange={(e) => setDriverForm({ ...driverForm, phone: e.target.value })}
                                                        placeholder="+7 777 123 4567"
                                                    />
                                                </div>
                                                <div className="space-y-2">
                                                    <Label>Гос. номер</Label>
                                                    <Input
                                                        value={driverForm.car}
                                                        onChange={(e) => setDriverForm({ ...driverForm, car: e.target.value })}
                                                        placeholder="123 ABC 02"
                                                    />
                                                </div>
                                                <div className="space-y-2">
                                                    <Label>Время прибытия</Label>
                                                    <Input
                                                        type="time"
                                                        value={driverForm.time}
                                                        onChange={(e) => setDriverForm({ ...driverForm, time: e.target.value })}
                                                    />
                                                </div>
                                                <Button
                                                    className="w-full"
                                                    onClick={() => assignDriverMutation.mutate({
                                                        driver_name: driverForm.name,
                                                        driver_phone: driverForm.phone,
                                                        driver_car_number: driverForm.car,
                                                        driver_arrival_time: driverForm.time
                                                    })}
                                                    disabled={assignDriverMutation.isPending}
                                                >
                                                    Назначить
                                                </Button>
                                            </div>
                                        </DialogContent>
                                    </Dialog>
                                </div>
                            )}

                            {/* Warehouse & Driver Logic */}
                            {attributes.status === 'driver_assigned' && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-indigo-50 border border-indigo-100 rounded-md text-sm">
                                        <p className="font-bold">Водитель:</p>
                                        <p>{attributes.driver_name} ({attributes.driver_car_number})</p>
                                        <p>{attributes.driver_phone}</p>
                                        <p>Ожидается: {attributes.driver_arrival_time}</p>
                                    </div>
                                    {(user?.role === 'warehouse' || user?.role === 'admin') && (
                                        <Button className="w-full bg-indigo-600 hover:bg-indigo-700" onClick={() => arriveMutation.mutate()} disabled={arriveMutation.isPending}>
                                            <Building className="mr-2 h-4 w-4" /> Водитель на складе
                                        </Button>
                                    )}
                                </div>
                            )}

                            {attributes.status === 'at_warehouse' && (user?.role === 'warehouse' || user?.role === 'admin') && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-yellow-50 border border-yellow-100 rounded-md">
                                        <p className="text-sm text-yellow-700">Машина на загрузке.</p>
                                    </div>
                                    <Button className="w-full bg-yellow-600 hover:bg-yellow-700" onClick={() => transitMutation.mutate()} disabled={transitMutation.isPending}>
                                        <Truck className="mr-2 h-4 w-4" /> Загрузка завершена (В путь)
                                    </Button>
                                </div>
                            )}

                            {attributes.status === 'in_transit' && (
                                <div className="space-y-4">
                                    <div className="p-4 bg-blue-50 border border-blue-100 rounded-md">
                                        <p className="text-sm font-bold text-blue-900 mb-2">Smart Link для водителя</p>
                                        <div className="flex items-center gap-2">
                                            <Input readOnly value={`${window.location.origin}/smart-link/${attributes.smart_link_token}`} className="bg-white" />
                                            <Button variant="outline" onClick={() => navigator.clipboard.writeText(`${window.location.origin}/smart-link/${attributes.smart_link_token}`)}>
                                                Copy
                                            </Button>
                                        </div>
                                    </div>
                                    {(user?.role === 'admin' || user?.role === 'driver') && (
                                        <Button className="w-full bg-blue-600 hover:bg-blue-700" onClick={() => deliverMutation.mutate()} disabled={deliverMutation.isPending}>
                                            <CheckCircle className="mr-2 h-4 w-4" /> Подтвердить доставку
                                        </Button>
                                    )}
                                </div>
                            )}

                            {/* Common Actions */}
                            {['paid', 'searching_driver', 'driver_assigned', 'at_warehouse', 'in_transit', 'delivered', 'completed', 'documents_ready'].includes(attributes.status) && (
                                <div className="space-y-3 pt-4 border-t">
                                    <p className="text-sm font-medium text-gray-500">Документы</p>
                                    <Button variant="outline" size="sm" className="w-full justify-start" onClick={() => downloadFile('invoice')}>
                                        <Download className="mr-2 h-4 w-4" /> Скачать счет
                                    </Button>
                                    <Button variant="outline" size="sm" className="w-full justify-start" onClick={() => downloadFile('contract')}>
                                        <Download className="mr-2 h-4 w-4" /> Скачать договор
                                    </Button>
                                </div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Debug Actions Card - Visible to ALL */}
                    <Card className="border-purple-200 bg-purple-50">
                        <CardHeader className="pb-2">
                            <CardTitle className="text-sm text-purple-800">1C Integration Debug</CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-3">
                            <Button
                                variant="secondary"
                                className="w-full bg-white text-purple-700 hover:bg-purple-100 border border-purple-200"
                                onClick={async () => {
                                    try {
                                        const res = await api.post('/api/v1/integrations/one_c/test_trigger', { order_id: id });
                                        alert("Test Trigger Sent! Check Logs.\n\nSimulated Response:\n" + JSON.stringify(res.data, null, 2));
                                    } catch (e) {
                                        alert("Error: " + e);
                                    }
                                }}
                            >
                                Test 1C (Hardcoded)
                            </Button>

                            <Button
                                className="w-full bg-purple-600 hover:bg-purple-700"
                                onClick={async () => {
                                    try {
                                        const res = await api.post('/api/v1/integrations/one_c/real_trigger', { order_id: id });
                                        console.log("Real 1C Trigger Result:", res.data);
                                        alert("REAL 1C Trigger Sent!\n\nPayload Sent:\n" + JSON.stringify(res.data.payload_sent, null, 2) + "\n\nResponse:\n" + res.data.response_body);
                                    } catch (e) {
                                        console.error(e);
                                        alert("Error sending Real Trigger");
                                    }
                                }}
                            >
                                Real Test 1C (Current Order Data)
                            </Button>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
};

export default OrderDetailPage;
