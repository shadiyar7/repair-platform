import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { toast } from "sonner";
import { NCALayer } from "@/lib/ncalayer";
import { Label } from '@/components/ui/label';
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
import { Download, CheckCircle, CreditCard, Truck, Clock, MapPin, FileText, User, Info, AlertCircle, Building, Navigation, Loader, Loader2 } from 'lucide-react';
import { useAuth } from '@/context/AuthContext';
import OrderTrackingMap from '@/components/OrderTrackingMap';

const SimulationText = () => {
    const [index, setIndex] = useState(0);
    const messages = [
        "Связываемся с биржей грузоперевозок...",
        "Анализируем доступные машины поблизости...",
        "Проверяем рейтинг водителей...",
        "Торгуемся за лучшую цену доставки...",
        "Ожидаем подтверждения от водителя..."
    ];

    useEffect(() => {
        const interval = setInterval(() => {
            setIndex((prev) => (prev + 1) % messages.length);
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    return (
        <div className="animate-pulse text-blue-700 font-medium transition-all duration-500">
            {messages[index]}
        </div>
    );
};

const OrderDetailPage: React.FC = () => {
    const { id } = useParams();
    const { user } = useAuth();
    const queryClient = useQueryClient();
    const [isDriverModalOpen, setIsDriverModalOpen] = useState(false);
    const [driverForm, setDriverForm] = useState(() => {
        const now = new Date();
        const date = now.toISOString().split('T')[0];
        const time = now.toTimeString().slice(0, 5); // HH:MM
        return {
            name: '',
            phone: '',
            car: '',
            date,
            time,
            comment: ''
        };
    });

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
    // const directorSignMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/director_sign`), ...mutationOptions });
    // const payMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/pay`), ...mutationOptions });
    // const findDriverMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/find_driver`), ...mutationOptions });
    const confirmPaymentMutation = useMutation({ mutationFn: () => api.post(`/api/v1/orders/${id}/confirm_payment`), ...mutationOptions });

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


    const [isIdocsSigning, setIsIdocsSigning] = useState(false);

    const handleIdocsSign = async () => {
        setIsIdocsSigning(true);
        try {
            // 1. Connect to NCALayer
            await NCALayer.connect();

            // 2. Prepare Document on Backend
            toast.loading("Подготовка документа...", { id: "idocs-sign" });
            const prepareRes = await api.post(`/api/v1/orders/${id}/idocs/prepare`);
            console.log('IDocs prepare response:', prepareRes.data);
            const { contentToSign, documentId, idempotencyTicket } = prepareRes.data;

            // 3. Sign in Browser
            toast.loading("Ожидание подписи (проверьте окно NCALayer)...", { id: "idocs-sign" });
            console.log('Calling NCALayer with content length:', contentToSign?.length);
            const signature = await NCALayer.createCms(contentToSign);

            // 4. Send Signature to Backend
            toast.loading("Отправка подписанного документа...", { id: "idocs-sign" });
            await api.post(`/api/v1/orders/${id}/idocs/sign`, {
                documentId,
                signature,
                idempotencyTicket   // required by iDocs quick-sign/save
            });

            toast.success("Документ успешно подписан и отправлен!", { id: "idocs-sign" });
            queryClient.invalidateQueries({ queryKey: ['order', id] });

        } catch (error: any) {
            console.error("IDocs Sign Error", error);
            toast.error(error.message || "Ошибка при подписании", { id: "idocs-sign" });
        } finally {
            setIsIdocsSigning(false);
        }
    };

    if (isLoading) return <div className="flex justify-center items-center h-64">Загрузка деталей заказа...</div>;
    if (error) return <div className="text-red-500">Ошибка при загрузке заказа</div>;

    const attributes = order.attributes;

    const steps = [
        // Hidden statuses: cart, requisites_selected
        { id: 'pending_director_signature', label: 'Подпись Директора', icon: FileText },
        { id: 'pending_signature', label: 'Подписание договора', icon: FileText },
        { id: 'pending_payment', label: 'Оплата', icon: CreditCard },
        // Hidden visually: payment_review, paid (Merged into Payment or Driver Search flow)
        { id: 'searching_driver', label: 'Поиск водителя', icon: User },
        { id: 'driver_assigned', label: 'Водитель назначен', icon: Truck },
        { id: 'at_warehouse', label: 'На складе', icon: Building },
        { id: 'in_transit', label: 'В пути', icon: MapPin },
        { id: 'delivered', label: 'Доставлен', icon: CheckCircle },
    ];

    let currentStepIndex = steps.findIndex(s => s.id === attributes.status);

    // Handle hidden statuses mapping to visible steps
    if (attributes.status === 'documents_ready' || attributes.status === 'completed') {
        currentStepIndex = steps.length - 1;
    } else if (attributes.status === 'cart' || attributes.status === 'requisites_selected') {
        currentStepIndex = -1;
    } else if (attributes.status === 'payment_review' || attributes.status === 'paid') {
        // If in review/paid, show as "Payment" completed (or transition to Search visually)
        // Since user wants "immediate", these states shouldn't persist long, 
        // but if they do, we map them to "Searching Driver" (as current pending step) 
        // OR map them to "Payment" (as completed step). 
        // Let's map to 'searching_driver' index so it shows Payment as Done and Search as Active?
        // No, if status is 'paid', it means Payment is Done. Next is Search.
        currentStepIndex = steps.findIndex(s => s.id === 'searching_driver');
    }

    const getStatusBadge = (status: string) => {
        const config: Record<string, string> = {
            draft: 'bg-gray-100 text-gray-800',
            pending_director_signature: 'bg-orange-600 text-white',
            pending_signature: 'bg-red-600 text-white',
            pending_payment: 'bg-indigo-600 text-white',
            payment_review: 'bg-yellow-500 text-white',
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

        // Friendly Label Logic
        let label = status.toUpperCase();
        if (status === 'pending_director_signature') label = 'ПОДПИСАНИЕ КОМПАНИЕЙ';
        if (status === 'pending_signature') label = 'ОЖИДАНИЕ ВАШЕЙ ПОДПИСИ';

        return <Badge className={color}>{label}</Badge>;
    };

    const downloadFile = async (type: 'invoice' | 'contract') => {
        // ... (Download logic remains the same)
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
                // Client sees passive message
                if (role === 'client') {
                    title = 'Ожидание подписи компании';
                    description = 'Мы подписываем ваш договор. Обычно это занимает не более 15 минут.';
                    type = 'info';
                }
                // Director/Admin see active action
                else if (role === 'director' || role === 'admin') {
                    title = 'Требуется подписание договора';
                    description = 'Договор сформирован. Пожалуйста, проверьте и подпишите его.';
                    type = 'warning';
                } else {
                    title = 'Ожидание подписания';
                    description = 'Руководство подписывает договор.';
                    type = 'info';
                }
                break;
            case 'pending_signature':
                if (role === 'client') {
                    title = 'Требуется действие: Подписание договора';
                    description = 'Компания подписала договор. Теперь ваша очередь.';
                    type = 'warning';
                } else {
                    title = 'Ожидание клиента';
                    description = 'Клиент должен подписать договор.';
                    type = 'info';
                }
                break;
            // ... (other cases remain the same)
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
                <li><span className="font-semibold">Договор:</span> Генерация и двустороннее подписание.</li>
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

            {/* Conditional Layout for 'in_transit' vs Standard */}
            {attributes.status === 'in_transit' ? (
                <div className="space-y-6">
                    {/* LARGE MAP SECTION */}
                    <div className="flex flex-col gap-4">
                        <div className="h-[75vh] w-full rounded-xl overflow-hidden shadow-2xl border-2 border-blue-500 relative bg-gray-100">
                            <OrderTrackingMap
                                order={{
                                    id: order.id,
                                    status: attributes.status,
                                    delivery_address: attributes.delivery_address,
                                    driver_name: attributes.driver_name,
                                    driver_car_number: attributes.driver_car_number,
                                    current_lat: attributes.current_lat,
                                    current_lng: attributes.current_lng,
                                    warehouse_name: attributes.warehouse_name,
                                    smart_link_token: attributes.smart_link_token
                                }}
                                className="h-full w-full border-0 shadow-none rounded-none"
                            />

                            {/* Overlay Status Badge */}
                            <div className="absolute top-4 right-4 z-[400]">
                                <Badge className="bg-blue-600 hover:bg-blue-700 text-lg py-1 px-4 shadow-lg animate-pulse">
                                    ГРУЗ В ПУТИ
                                </Badge>
                            </div>
                        </div>
                    </div>

                    {/* COMPACT DETAILS GRID */}
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {/* Driver Info & Action */}
                        <Card className="bg-blue-50 border-blue-200">
                            <CardHeader className="pb-2">
                                <CardTitle className="text-lg text-blue-900 flex items-center gap-2">
                                    <Truck className="h-5 w-5" />
                                    Водитель
                                </CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="space-y-2 mb-4">
                                    <p className="font-bold text-lg">{attributes.driver_name}</p>
                                    <p className="text-gray-600 font-mono bg-white px-2 py-1 rounded w-fit border">{attributes.driver_car_number}</p>
                                    <p className="text-sm text-gray-500">{attributes.driver_phone}</p>
                                </div>

                                {(user?.role === 'admin' || user?.role === 'driver' || user?.role === 'warehouse') && (
                                    <div className="pt-2 border-t border-blue-200">
                                        <p className="text-xs font-bold text-blue-900 mb-2">Ссылка для водителя</p>
                                        <div className="flex items-center gap-2">
                                            <Input readOnly value={`${window.location.origin}/track/${attributes.smart_link_token}`} className="bg-white text-xs h-8" />
                                            <Button variant="outline" size="sm" className="h-8" onClick={() => navigator.clipboard.writeText(`${window.location.origin}/track/${attributes.smart_link_token}`)}>
                                                Copy
                                            </Button>
                                        </div>
                                    </div>
                                )}

                                {(user?.role === 'admin' || user?.role === 'driver') && (
                                    <Button className="w-full mt-4 bg-green-600 hover:bg-green-700" onClick={() => deliverMutation.mutate()} disabled={deliverMutation.isPending}>
                                        <CheckCircle className="mr-2 h-4 w-4" /> Подтвердить доставку
                                    </Button>
                                )}
                            </CardContent>
                        </Card>

                        {/* Order Composition (Compact) */}
                        <Card>
                            <CardHeader className="pb-2">
                                <CardTitle className="text-lg">Состав заказа</CardTitle>
                            </CardHeader>
                            <CardContent>
                                <div className="max-h-40 overflow-y-auto mb-2 space-y-2 pr-2">
                                    {attributes.order_items?.map((item: any) => (
                                        <div key={item.id} className="flex justify-between text-sm">
                                            <span>{item.product_name} x{item.quantity}</span>
                                            <span className="font-medium text-gray-600">{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price * item.quantity)}</span>
                                        </div>
                                    ))}
                                </div>
                                <div className="border-t pt-2 flex justify-between font-bold">
                                    <span>Итого</span>
                                    <span>{new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(attributes.total_amount)}</span>
                                </div>
                            </CardContent>
                        </Card>

                        {/* Delivery Details (Compact) */}
                        <Card>
                            <CardHeader className="pb-2">
                                <CardTitle className="text-lg">Адрес доставки</CardTitle>
                            </CardHeader>
                            <CardContent className="text-sm space-y-3">
                                <div>
                                    <p className="font-semibold flex items-center gap-2 text-gray-600 mb-1">
                                        <MapPin className="h-4 w-4" /> Куда
                                    </p>
                                    <p>{attributes.delivery_address}</p>
                                </div>
                                {attributes.delivery_notes && (
                                    <div className="bg-yellow-50 p-2 rounded border border-yellow-100 text-yellow-800 text-xs">
                                        Note: {attributes.delivery_notes}
                                    </div>
                                )}
                            </CardContent>
                        </Card>
                    </div>
                </div>
            ) : (
                /* STANDARD LAYOUT for all other statuses */
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
                                {getActionBanner()}

                                {/* DEBUG BUTTON - Global for Admin/Warehouse */}
                                {(user?.role === 'admin' || user?.role === 'warehouse') && (
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        className="w-full mb-4 text-xs text-blue-600 border-blue-200 bg-blue-50"
                                        onClick={() => {
                                            if (!attributes.invoice_base64) {
                                                alert("В текущем заказе нет сохраненного счета (Base64). Нажмите 'Тест 1С', чтобы получить его.");
                                                return;
                                            }

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
                                                console.error(e);
                                                alert("Ошибка при открытии счета (Base64).");
                                            }
                                        }}
                                    >
                                        <FileText className="mr-1 h-3.5 w-3.5" />
                                        DEBUG: Открыть Счет (Текущий заказ)
                                    </Button>
                                )}

                                {/* Director / Admin: iDocs Signature — visible for any order */}
                                {(user?.role === 'director' || user?.role === 'admin') && (
                                    <div className="space-y-4">
                                        <div className="p-4 bg-orange-50 border border-orange-100 rounded-md flex items-start space-x-3">
                                            <FileText className="h-5 w-5 text-orange-600 mt-0.5" />
                                            <div>
                                                <p className="text-sm font-semibold text-orange-800">Подписание ЭЦП (iDocs)</p>
                                                <p className="text-xs text-orange-600 mt-0.5">Статус: <span className="font-mono">{attributes.status}</span></p>
                                            </div>
                                        </div>
                                        <Button
                                            className="w-full bg-blue-600 hover:bg-blue-700"
                                            onClick={handleIdocsSign}
                                            disabled={isIdocsSigning}
                                        >
                                            {isIdocsSigning ? (
                                                <>
                                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                                    Подписание через NCALayer...
                                                </>
                                            ) : "Подписать и отправить (iDocs)"}
                                        </Button>
                                    </div>
                                )}

                                {/* ... Other status actions ... */}
                                {/* Placeholder removed */}

                                {/* RE-IMPLEMENTING STANDARD ACTION BUTTONS FOR NON-TRANSIT STATUSES */}
                                {attributes.status === 'pending_signature' && (user?.role === 'client' || user?.role === 'admin') && (
                                    <div className="space-y-4">
                                        <Button className="w-full bg-red-600 hover:bg-red-700" onClick={() => signContractMutation.mutate()} disabled={signContractMutation.isPending}>
                                            <CheckCircle className="mr-2 h-4 w-4" /> Подписать договор (Клиент)
                                        </Button>
                                    </div>
                                )}

                                {attributes.status === 'pending_payment' && (user?.role === 'client' || user?.role === 'admin') && (
                                    <div className="space-y-4">
                                        <Button variant="outline" className="w-full" onClick={() => downloadFile('invoice')} disabled={!attributes.invoice_base64}>
                                            <Download className="mr-2 h-4 w-4" /> Скачать счет
                                        </Button>
                                        <Dialog>
                                            <DialogTrigger asChild>
                                                <Button className="w-full bg-blue-600 hover:bg-blue-700">
                                                    <FileText className="mr-2 h-4 w-4" /> Прикрепить чек
                                                </Button>
                                            </DialogTrigger>
                                            <DialogContent>
                                                {/* File Upload Form - Simplified for brevity in this insertion, ideally componentized */}
                                                <DialogHeader><DialogTitle>Загрузка чека</DialogTitle></DialogHeader>
                                                <p>Пожалуйста, загрузите чек об оплате.</p>
                                                <Input type="file" onChange={(e) => {
                                                    const file = e.target.files?.[0];
                                                    if (file) {
                                                        const fd = new FormData();
                                                        fd.append('file', file);
                                                        fd.append('amount', String(attributes.total_amount));
                                                        api.post(`/api/v1/orders/${id}/upload_receipt`, fd).then(() => queryClient.invalidateQueries({ queryKey: ['order', id] }));
                                                    }
                                                }} />
                                            </DialogContent>
                                        </Dialog>
                                    </div>
                                )}

                                {attributes.status === 'searching_driver' && (
                                    <div className="space-y-6">
                                        {/* Simulation UI: Searching Driver */}
                                        <div className="relative p-8 bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-100 rounded-xl overflow-hidden shadow-sm">
                                            <div className="absolute top-0 right-0 p-4 opacity-10">
                                                <Truck className="h-32 w-32 text-blue-600" />
                                            </div>

                                            <div className="relative z-10 flex flex-col items-center justify-center text-center space-y-4">
                                                <div className="relative">
                                                    <div className="absolute inset-0 bg-blue-400 rounded-full opacity-20 animate-ping"></div>
                                                    <div className="relative bg-white p-4 rounded-full shadow-md border-2 border-blue-100">
                                                        <Loader className="h-8 w-8 text-blue-600 animate-spin" />
                                                    </div>
                                                </div>

                                                <div>
                                                    <h3 className="text-xl font-semibold text-blue-900 mb-2">Поиск водителя</h3>
                                                    <div className="h-6 overflow-hidden">
                                                        <SimulationText />
                                                    </div>
                                                    <p className="text-xs text-blue-500 mt-2 max-w-sm mx-auto">
                                                        Мы уже уведомили доступных водителей через Della.kz. В среднем поиск занимает 15-30 минут.
                                                    </p>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Minimalistic Payment Status Sidebar/Badge */}
                                        <div className="flex items-center justify-end space-x-2">
                                            <div className={`flex items-center space-x-2 px-3 py-1.5 rounded-full text-xs font-medium border ${attributes.is_verified
                                                ? 'bg-green-50 text-green-700 border-green-200'
                                                : 'bg-yellow-50 text-yellow-700 border-yellow-200'
                                                }`}>
                                                {attributes.is_verified ? (
                                                    <>
                                                        <CheckCircle className="h-3.5 w-3.5 mr-1" />
                                                        Оплата подтверждена
                                                    </>
                                                ) : (
                                                    <>
                                                        <Clock className="h-3.5 w-3.5 mr-1" />
                                                        Оплата проверяется (Бухгалтерия)
                                                    </>
                                                )}
                                            </div>

                                            {/* View Check Button (Always available if receipt exists) */}
                                            {attributes.payment_receipt_url && (
                                                <Button variant="ghost" size="sm" className="h-8 text-xs text-muted-foreground" onClick={() => window.open(attributes.payment_receipt_url, '_blank')}>
                                                    <FileText className="mr-1 h-3.5 w-3.5" /> Чек
                                                </Button>
                                            )}

                                            {/* Admin Confirmation Button (Only if not verified yet) */}
                                            {!attributes.is_verified && (user?.role === 'admin' || user?.role === 'warehouse') && (
                                                <Button
                                                    variant="ghost"
                                                    size="sm"
                                                    className="h-8 text-xs text-green-600 hover:text-green-700 hover:bg-green-50"
                                                    onClick={() => confirmPaymentMutation.mutate()}
                                                    disabled={confirmPaymentMutation.isPending}
                                                >
                                                    Подтвердить
                                                </Button>
                                            )}
                                        </div>

                                        {/* Driver Assignment Block for Admin/Warehouse */}
                                        {(user?.role === 'admin' || user?.role === 'warehouse') && (
                                            <Dialog open={isDriverModalOpen} onOpenChange={setIsDriverModalOpen}>
                                                <DialogTrigger asChild>
                                                    <Button className="w-full bg-purple-600 hover:bg-purple-700">
                                                        <User className="mr-2 h-4 w-4" /> Водитель найден (Назначить вручную)
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
                                                        <div className="grid grid-cols-2 gap-4">
                                                            <div className="space-y-2">
                                                                <Label>Дата прибытия</Label>
                                                                <Input
                                                                    type="date"
                                                                    value={driverForm.date}
                                                                    onChange={(e) => setDriverForm({ ...driverForm, date: e.target.value })}
                                                                />
                                                            </div>
                                                            <div className="space-y-2">
                                                                <Label>Время</Label>
                                                                <Input
                                                                    type="time"
                                                                    value={driverForm.time}
                                                                    onChange={(e) => setDriverForm({ ...driverForm, time: e.target.value })}
                                                                />
                                                            </div>
                                                        </div>
                                                        <Button
                                                            className="w-full mt-4"
                                                            onClick={() => assignDriverMutation.mutate({
                                                                driver_name: driverForm.name,
                                                                driver_phone: driverForm.phone,
                                                                driver_car_number: driverForm.car,
                                                                driver_arrival_time: `${driverForm.date} ${driverForm.time}`,
                                                                driver_comment: driverForm.comment
                                                            })}
                                                            disabled={assignDriverMutation.isPending}
                                                        >
                                                            {assignDriverMutation.isPending ? 'Назначение...' : 'Назначить водителя'}
                                                        </Button>
                                                        <div className="space-y-2">
                                                            <Label>Комментарий по машине</Label>
                                                            <textarea
                                                                className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                                                placeholder="Например: Большая фура, заезд с заднего двора"
                                                                value={driverForm.comment}
                                                                onChange={(e) => setDriverForm({ ...driverForm, comment: e.target.value })}
                                                            />
                                                        </div>
                                                        <Button
                                                            className="w-full"
                                                            onClick={() => assignDriverMutation.mutate({
                                                                driver_name: driverForm.name,
                                                                driver_phone: driverForm.phone,
                                                                driver_car_number: driverForm.car,
                                                                driver_arrival_time: driverForm.time,
                                                                driver_comment: driverForm.comment
                                                            })}
                                                            disabled={assignDriverMutation.isPending}
                                                        >
                                                            {assignDriverMutation.isPending ? 'Назначение...' : 'Назначить водителя'}
                                                        </Button>
                                                    </div>
                                                </DialogContent>
                                            </Dialog>
                                        )}

                                    </div>
                                )}

                                {attributes.status === 'driver_assigned' && (
                                    <div className="space-y-4">
                                        <div className="p-4 bg-indigo-50 border border-indigo-100 rounded-md text-sm">
                                            <p className="font-bold">Водитель:</p>
                                            <p>{attributes.driver_name} ({attributes.driver_car_number})</p>
                                            <p>{attributes.driver_phone}</p>
                                        </div>
                                        {(user?.role === 'warehouse' || user?.role === 'admin') && (
                                            <Button className="w-full bg-indigo-600 hover:bg-indigo-700" onClick={() => arriveMutation.mutate()}>
                                                <Truck className="mr-2 h-4 w-4" /> Водитель прибыл
                                            </Button>
                                        )}
                                    </div>
                                )}

                                {attributes.status === 'at_warehouse' && (
                                    <div className="space-y-4">
                                        <div className="p-4 bg-yellow-50 text-yellow-800 text-sm rounded">Машина на загрузке</div>
                                        {(user?.role === 'warehouse' || user?.role === 'admin') && (
                                            <Button className="w-full bg-green-600 hover:bg-green-700" onClick={() => transitMutation.mutate()}>
                                                <Navigation className="mr-2 h-4 w-4" /> Начать поездку
                                            </Button>
                                        )}
                                    </div>
                                )}

                                {attributes.status === 'delivered' && (
                                    <div className="p-4 bg-green-50 text-green-800 font-bold rounded text-center">
                                        Заказ доставлен!
                                    </div>
                                )}

                                {/* Common Doc Downloads */}
                                <div className="space-y-2 pt-4 border-t">
                                    <Button variant="ghost" size="sm" className="w-full justify-start" onClick={() => downloadFile('invoice')}>
                                        <FileText className="mr-2 h-4 w-4" /> Счет на оплату
                                    </Button>
                                    <Button variant="ghost" size="sm" className="w-full justify-start" onClick={() => downloadFile('contract')}>
                                        <FileText className="mr-2 h-4 w-4" /> Договор
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    </div>
                </div>
            )}
        </div>
    );
};

export default OrderDetailPage;
