import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { MapPin, Truck, CheckCircle, Navigation } from 'lucide-react';

const SmartLinkPage = () => {
    const { token } = useParams();
    const queryClient = useQueryClient();
    const [location, setLocation] = useState({ lat: 43.238949, lng: 76.889709 }); // Almaty Default

    // Fetch order by token (public endpoint)
    const { data: order, isLoading, error } = useQuery({
        queryKey: ['smart-link-order', token],
        queryFn: async () => {
            const response = await api.get(`/api/v1/orders/by_token/${token}`);
            return response.data.data;
        }
    });

    const deliverMutation = useMutation({
        mutationFn: () => api.post(`/api/v1/orders/${order.id}/deliver`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['smart-link-order', token] });
        }
    });

    // Simulate location updates
    useEffect(() => {
        const interval = setInterval(() => {
            setLocation(prev => ({
                lat: prev.lat + (Math.random() - 0.5) * 0.001,
                lng: prev.lng + (Math.random() - 0.5) * 0.001
            }));
        }, 3000);
        return () => clearInterval(interval);
    }, []);

    if (isLoading) return <div className="flex justify-center items-center h-screen">Загрузка данных...</div>;
    if (error) return <div className="flex justify-center items-center h-screen text-red-500">Ссылка недействительна</div>;

    const attributes = order.attributes;

    return (
        <div className="min-h-screen bg-gray-50 p-4 sm:p-8">
            <div className="max-w-md mx-auto space-y-6">
                <div className="text-center space-y-2">
                    <h1 className="text-2xl font-bold text-gray-900">DYNAMIX Logistics</h1>
                    <p className="text-sm text-gray-500">Отслеживание доставки</p>
                </div>

                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Truck className="h-5 w-5 text-red-600" />
                            Статус: {attributes.status.toUpperCase()}
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="p-4 bg-gray-100 rounded-lg h-64 flex items-center justify-center relative overflow-hidden">
                            {/* Mock Map */}
                            <div className="absolute inset-0 bg-blue-50 opacity-50" />
                            <div className="z-10 text-center">
                                <Navigation className="h-8 w-8 text-blue-600 mx-auto animate-bounce" />
                                <p className="text-xs text-gray-600 mt-2 font-mono">
                                    {location.lat.toFixed(6)}, {location.lng.toFixed(6)}
                                </p>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <div className="flex items-start gap-3">
                                <MapPin className="h-5 w-5 text-gray-400 mt-0.5" />
                                <div>
                                    <p className="text-sm font-medium text-gray-500">Адрес доставки</p>
                                    <p className="text-gray-900">{attributes.delivery_address}</p>
                                </div>
                            </div>
                            <div className="flex items-start gap-3">
                                <Truck className="h-5 w-5 text-gray-400 mt-0.5" />
                                <div>
                                    <p className="text-sm font-medium text-gray-500">Водитель</p>
                                    <p className="text-gray-900">{attributes.driver_name || 'Не назначен'}</p>
                                    <p className="text-sm text-gray-500">{attributes.driver_car_number}</p>
                                </div>
                            </div>
                        </div>

                        {attributes.status === 'in_transit' && (
                            <Button
                                className="w-full bg-green-600 hover:bg-green-700 h-12 text-lg"
                                onClick={() => deliverMutation.mutate()}
                                disabled={deliverMutation.isPending}
                            >
                                <CheckCircle className="mr-2 h-5 w-5" />
                                Подтвердить доставку
                            </Button>
                        )}

                        {attributes.status === 'delivered' && (
                            <div className="bg-green-50 p-4 rounded-lg text-center text-green-800 font-medium">
                                Груз успешно доставлен
                            </div>
                        )}
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};

export default SmartLinkPage;
