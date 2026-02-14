import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import api from '@/lib/api';
import { MapPin, Navigation, User, Phone, Loader } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

const SmartLinkPage: React.FC = () => {
    const { token } = useParams();
    const [order, setOrder] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [status, setStatus] = useState('initializing');

    useEffect(() => {
        const fetchOrder = async () => {
            try {
                // Ensure this endpoint exists and parses token correctly
                const response = await api.get(`/api/v1/orders/by_token/${token}`);
                setOrder(response.data.data.attributes);
            } catch (err) {
                console.error(err);
                setError('Неверная ссылка или заказ не найден');
            } finally {
                setLoading(false);
            }
        };
        fetchOrder();
    }, [token]);

    useEffect(() => {
        if (!navigator.geolocation) {
            setStatus('geolocation_not_supported');
            return;
        }

        const success = (position: GeolocationPosition) => {
            const { latitude, longitude } = position.coords;
            setLocation({ lat: latitude, lng: longitude });
            setStatus('tracking');

            // Send to backend
            api.post(`/api/v1/smart_links/${token}/location`, {
                lat: latitude,
                lng: longitude
            }).catch(e => console.error("Failed to update location", e));
        };

        const error = () => {
            setStatus('permission_denied');
        };

        const watchId = navigator.geolocation.watchPosition(success, error, {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 0
        });

        return () => navigator.geolocation.clearWatch(watchId);
    }, [token]);

    if (loading) return <div className="flex h-screen items-center justify-center"><Loader className="animate-spin h-8 w-8 text-blue-600" /></div>;
    if (error) return <div className="p-8 text-center text-red-600 font-bold">{error}</div>;

    return (
        <div className="min-h-screen bg-gray-50 p-4 font-sans">
            <div className="max-w-md mx-auto space-y-6">

                {/* Header */}
                <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex items-center justify-between">
                    <div>
                        <h1 className="text-xl font-bold text-gray-900">DYNAMIX Driver</h1>
                        <p className="text-xs text-gray-500">Система доставки</p>
                    </div>
                    <Badge variant={status === 'tracking' ? 'default' : 'destructive'} className={status === 'tracking' ? 'bg-green-500' : ''}>
                        {status === 'tracking' ? 'GPS Активен' : 'Нет сигнала'}
                    </Badge>
                </div>

                {/* Status Card */}
                <Card className="border-blue-200 bg-blue-50">
                    <CardHeader className="pb-2">
                        <CardTitle className="text-blue-900 text-lg flex items-center gap-2">
                            <Navigation className="h-5 w-5" /> Текущий статус
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <p className="font-medium text-blue-800 text-lg">В ПУТИ (In Transit)</p>
                        <p className="text-sm text-blue-600 mt-1">Данные о местоположении передаются диспетчеру.</p>

                        {location && (
                            <div className="mt-3 text-xs font-mono bg-white/50 p-2 rounded text-blue-800">
                                Lat: {location.lat.toFixed(6)} <br />
                                Lng: {location.lng.toFixed(6)}
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Order Details */}
                <Card>
                    <CardHeader>
                        <CardTitle>Детали заказа</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="flex items-start gap-3">
                            <Navigation className="h-5 w-5 text-gray-400 mt-1" />
                            <div>
                                <p className="text-xs text-gray-500 font-bold uppercase">Пункт назначения</p>
                                <p className="font-medium text-gray-900">{order.city}</p>
                                <p className="text-sm text-gray-600">{order.delivery_address}</p>
                            </div>
                        </div>

                        <div className="flex items-start gap-3 pt-3 border-t">
                            <User className="h-5 w-5 text-gray-400 mt-1" />
                            <div>
                                <p className="text-xs text-gray-500 font-bold uppercase">Получатель</p>
                                {/* Assuming user name is not directly in attributes, falling back to delivery details or static */}
                                <p className="font-medium text-gray-900">Клиент</p>
                            </div>
                        </div>

                        {order.delivery_notes && (
                            <div className="pt-3 border-t">
                                <p className="text-xs text-gray-500 font-bold uppercase mb-1">Комментарий к доставке</p>
                                <p className="text-sm text-gray-700 bg-gray-50 p-2 rounded">{order.delivery_notes}</p>
                            </div>
                        )}
                    </CardContent>
                </Card>

                {/* Actions */}
                <div className="grid grid-cols-2 gap-4">
                    <Button variant="outline" className="w-full" onClick={() => window.open(`https://yandex.kz/maps/?text=${order.city} ${order.delivery_address}`, '_blank')}>
                        <MapPin className="mr-2 h-4 w-4" /> Навигатор
                    </Button>
                    <Button className="w-full bg-green-600 hover:bg-green-700">
                        <Phone className="mr-2 h-4 w-4" /> Позвонить
                    </Button>
                </div>

                <p className="text-center text-xs text-gray-400 mt-8">
                    Не закрывайте эту вкладку во время доставки.
                </p>
            </div>
        </div>
    );
};

export default SmartLinkPage;
