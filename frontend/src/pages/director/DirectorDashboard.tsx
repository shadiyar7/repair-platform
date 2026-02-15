
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import {
    BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer,
    LineChart, Line, PieChart, Pie, Cell
} from 'recharts';
import {
    TrendingUp, DollarSign, CheckCircle,
    AlertCircle, Activity, PenTool, FileText
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { toast } from 'sonner';

// --- Helper ---
const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('ru-KZ', {
        style: 'currency',
        currency: 'KZT',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0,
    }).format(value);
};

// --- Components ---

const KPICard = ({ title, value, icon: Icon, description }: { title: string, value: string | number, icon: any, description?: string }) => (
    <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">{title}</CardTitle>
            <Icon className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
            <div className="text-2xl font-bold">{value}</div>
            {description && <p className="text-xs text-muted-foreground">{description}</p>}
        </CardContent>
    </Card>
);

const SignaturesList = () => {
    const queryClient = useQueryClient();
    const { data: ordersData, isLoading } = useQuery({
        queryKey: ['orders', 'pending_director_signature'],
        queryFn: () => api.get('/api/v1/orders')
    });

    const signMutation = useMutation({
        mutationFn: (id: string) => api.post(`/api/v1/orders/${id}/director_sign`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['orders'] });
            toast.success("Документ подписан успешно");
        }
    });

    // Filter for pending_director_signature
    const rawOrders = ordersData?.data?.data;
    const ordersList = Array.isArray(rawOrders) ? rawOrders : [];
    const orders = ordersList.filter((o: any) => o.attributes.status === 'pending_director_signature');

    if (isLoading) return <div>Загрузка...</div>;

    return (
        <div className="space-y-4">
            {orders.length === 0 ? (
                <div className="text-center py-10 text-gray-500">
                    <CheckCircle className="h-12 w-12 mx-auto mb-3 text-green-500" />
                    <h3 className="text-lg font-medium">Все документы подписаны</h3>
                    <p>Нет ожидающих заявок.</p>
                </div>
            ) : (
                orders.map((order: any) => {
                    const attrs = order.attributes;
                    const companyName = attrs.company_requisite?.company_name || 'Частное лицо';
                    const bin = attrs.company_requisite?.bin;

                    return (
                        <Card key={order.id} className="border-l-4 border-l-blue-500 shadow-sm hover:shadow-md transition-shadow">
                            <CardContent className="p-6">
                                <div className="flex flex-col md:flex-row justify-between gap-4 mb-4">
                                    <div>
                                        <div className="flex items-center gap-2 mb-2">
                                            <h3 className="text-lg font-bold text-gray-800">Заказ #{order.id}</h3>
                                            <Badge variant="outline" className="bg-blue-50 text-blue-700">На подпись</Badge>
                                        </div>
                                        <div className="text-sm text-gray-600 space-y-1">
                                            <p><span className="font-medium">Клиент:</span> {companyName} {bin ? `(БИН: ${bin})` : ''}</p>
                                            <p><span className="font-medium">Город:</span> {attrs.city || 'Не указан'}</p>
                                            <p><span className="font-medium">Адрес доставки:</span> {attrs.delivery_address || 'Не указан'}</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-sm text-gray-500 mb-1">Сумма заказа</p>
                                        <p className="text-2xl font-bold text-green-600">{formatCurrency(parseFloat(attrs.total_amount))}</p>
                                    </div>
                                </div>

                                {/* Items List */}
                                <div className="bg-gray-50 p-4 rounded-lg mb-4 text-sm">
                                    <h4 className="font-semibold mb-2 text-gray-700">Товары в заказе:</h4>
                                    <ul className="space-y-2">
                                        {attrs.order_items?.map((item: any) => (
                                            <li key={item.id} className="flex justify-between border-b last:border-0 pb-2 last:pb-0 border-gray-200">
                                                <span>{item.product_name} <span className="text-gray-500">({item.sku})</span></span>
                                                <div className="text-right">
                                                    <span className="font-medium">{item.quantity} шт.</span>
                                                    {item.warehouse && <span className="block text-xs text-gray-500">Склад: {item.warehouse}</span>}
                                                </div>
                                            </li>
                                        ))}
                                    </ul>
                                </div>

                                <div className="flex flex-wrap justify-end gap-3">
                                    {attrs.contract_url && (
                                        <Button
                                            variant="outline"
                                            onClick={() => window.open(attrs.contract_url, '_blank')}
                                        >
                                            <FileText className="mr-2 h-4 w-4" />
                                            Скачать договор
                                        </Button>
                                    )}
                                    <Button
                                        onClick={() => signMutation.mutate(order.id)}
                                        disabled={signMutation.isPending}
                                        className="bg-blue-600 hover:bg-blue-700"
                                    >
                                        <PenTool className="mr-2 h-4 w-4" />
                                        {signMutation.isPending ? 'Подписание...' : 'Подписать ЭЦП'}
                                    </Button>
                                </div>
                            </CardContent>
                        </Card>
                    );
                })
            )}
        </div>
    );
};

const AnalyticsDashboard = () => {
    const { data: analyticsData, isLoading } = useQuery({
        queryKey: ['analytics'],
        queryFn: async () => {
            const res = await api.get('/api/v1/analytics/dashboard');
            return res.data;
        }
    });

    if (isLoading) return <div className="h-96 flex items-center justify-center"><Activity className="animate-spin h-8 w-8 text-blue-600" /></div>;

    const { kpi, charts } = analyticsData || { kpi: {}, charts: {} };

    const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

    return (
        <div className="space-y-6">
            {/* KPIs */}
            <div className="grid gap-4 md:grid-cols-3">
                <KPICard
                    title="Общая выручка"
                    value={formatCurrency(kpi.total_revenue || 0)}
                    icon={DollarSign}
                    description="За все время"
                />
                <KPICard
                    title="Активные заказы"
                    value={kpi.active_orders || 0}
                    icon={Activity}
                    description="В работе прямо сейчас"
                />
                <KPICard
                    title="Средний чек"
                    value={formatCurrency(kpi.avg_check || 0)}
                    icon={TrendingUp}
                    description="Средняя стоимость заказа"
                />
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">

                {/* Sales Trend Chart */}
                <Card className="col-span-4">
                    <CardHeader>
                        <CardTitle>Динамика продаж</CardTitle>
                        <CardDescription>Выручка за последние 7 дней</CardDescription>
                    </CardHeader>
                    <CardContent className="pl-2">
                        <div className="h-[300px]">
                            <ResponsiveContainer width="100%" height="100%">
                                <LineChart data={charts.sales_trend}>
                                    <XAxis dataKey="date" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
                                    <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value: any) => `${value / 1000}k`} />
                                    <Tooltip formatter={(value: any) => formatCurrency(Number(value))} />
                                    <Line type="monotone" dataKey="amount" stroke="#2563eb" strokeWidth={2} activeDot={{ r: 8 }} />
                                </LineChart>
                            </ResponsiveContainer>
                        </div>
                    </CardContent>
                </Card>

                {/* Top Products */}
                <Card className="col-span-3">
                    <CardHeader>
                        <CardTitle>Топ продуктов</CardTitle>
                        <CardDescription>По количеству продаж</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="h-[300px]">
                            <ResponsiveContainer width="100%" height="100%">
                                <BarChart data={charts.top_products} layout="vertical" margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                                    <XAxis type="number" hide />
                                    <YAxis dataKey="name" type="category" width={100} fontSize={10} />
                                    <Tooltip />
                                    <Bar dataKey="quantity" fill="#3b82f6" radius={[0, 4, 4, 0]} />
                                </BarChart>
                            </ResponsiveContainer>
                        </div>
                    </CardContent>
                </Card>
            </div>

            {/* Category Split */}
            <Card className="col-span-4">
                <CardHeader>
                    <CardTitle>Структура выручки</CardTitle>
                    <CardDescription>По категориям товаров</CardDescription>
                </CardHeader>
                <CardContent className="flex justify-center">
                    <div className="h-[300px] w-full max-w-md">
                        <ResponsiveContainer width="100%" height="100%">
                            <PieChart>
                                <Pie
                                    data={charts.category_split}
                                    cx="50%"
                                    cy="50%"
                                    innerRadius={60}
                                    outerRadius={80}
                                    paddingAngle={5}
                                    dataKey="value"
                                >
                                    {charts.category_split?.map((_entry: any, index: number) => (
                                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                                    ))}
                                </Pie>
                                <Tooltip formatter={(value: any) => formatCurrency(Number(value))} />
                                <Legend />
                            </PieChart>
                        </ResponsiveContainer>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
};



const DirectorDashboard = () => {
    const [activeTab, setActiveTab] = React.useState('signatures');

    return (
        <div className="container mx-auto p-6 space-y-8">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Кабинет Директора</h1>
                    <p className="text-gray-500 mt-1">Управление подписями и аналитика</p>
                </div>
                <div className="text-sm text-gray-500 bg-gray-100 px-3 py-1 rounded-full">
                    DYNAMIX Executive Suite
                </div>
            </div>

            <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
                <TabsList className="grid w-[400px] grid-cols-2">
                    <TabsTrigger value="signatures" className="gap-2">
                        <PenTool className="h-4 w-4" /> На подпись
                    </TabsTrigger>
                    <TabsTrigger value="analytics" className="gap-2">
                        <TrendingUp className="h-4 w-4" /> Аналитика (BI)
                    </TabsTrigger>
                </TabsList>

                <TabsContent value="signatures" className="space-y-4">
                    <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg flex items-start gap-3">
                        <AlertCircle className="h-5 w-5 text-blue-600 mt-0.5" />
                        <div>
                            <h4 className="font-semibold text-blue-900">Требуется действие</h4>
                            <p className="text-sm text-blue-700">Подпишите договоры, чтобы запустить процесс оплаты и доставки.</p>
                        </div>
                    </div>
                    <SignaturesList />
                </TabsContent>

                <TabsContent value="analytics">
                    <AnalyticsDashboard />
                </TabsContent>
            </Tabs>
        </div>
    );
};

export default DirectorDashboard;
