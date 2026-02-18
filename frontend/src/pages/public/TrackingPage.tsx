import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-routing-machine/dist/leaflet-routing-machine.css';
import 'leaflet-routing-machine';
import api from '@/lib/api';
import { Loader2, Truck, Clock, MapPin } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';

// Fix Leaflet default icon issue
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const truckIcon = new L.Icon({
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/75/75836.png', // Truck icon
    iconSize: [40, 40],
    iconAnchor: [20, 20],
});

interface OrderData {
    id: number;
    status: string;
    city: string;
    delivery_address: string;
    driver_name: string;
    driver_phone: string;
    driver_car_number: string;
    current_lat: number | null;
    current_lng: number | null;
    warehouse_name?: string;
}

// Routing Machine Component
const RoutingMachine = ({ start, end, onRouteFound }: { start: L.LatLng; end: L.LatLng, onRouteFound?: (summary: any) => void }) => {
    const map = useMap();

    useEffect(() => {
        if (!map) return;

        const routingControl = L.Routing.control({
            waypoints: [start, end],
            routeWhileDragging: false,
            showAlternatives: false,
            fitSelectedRoutes: true,
            lineOptions: {
                styles: [{ color: '#2563EB', weight: 5, opacity: 0.8 }],
                extendToWaypoints: false,
                missingRouteTolerance: 0
            },
            show: false, // Hide turn-by-turn list
            addWaypoints: false,
            draggableWaypoints: false,
            // Use OSRM demo server (free)
            serviceUrl: 'https://router.project-osrm.org/route/v1'
        } as any);

        routingControl.on('routesfound', function (e: any) {
            const routes = e.routes;
            const summary = routes[0].summary;
            // summary.totalTime is in seconds
            if (onRouteFound) onRouteFound(summary);
        });

        routingControl.addTo(map);

        return () => {
            // Remove control safely
            try {
                map.removeControl(routingControl);
            } catch (e) {
                console.warn("Error removing routing control", e);
            }
        };
    }, [map, start.lat, start.lng, end.lat, end.lng]); // Primitive dependencies to avoid loop

    return null;
};

const TrackingPage: React.FC = () => {
    const { token } = useParams<{ token: string }>();
    const [order, setOrder] = useState<OrderData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [isDriver, setIsDriver] = useState(false);
    const [destinationCoords, setDestinationCoords] = useState<L.LatLng | null>(null);
    const [eta, setEta] = useState<string | null>(null);

    // Initial Fetch
    useEffect(() => {
        const fetchOrder = async () => {
            try {
                const res = await api.get(`/api/v1/smart_links/${token}`);
                setOrder(res.data);

                // If address exists, try to geocode it for routing destination
                if (res.data.delivery_address && !destinationCoords) {
                    geocodeAddress(res.data.delivery_address);
                }

                const urlParams = new URLSearchParams(window.location.search);
                if (urlParams.get('role') === 'driver') {
                    setIsDriver(true);
                }

            } catch (err) {
                setError('Order not found or link expired');
            } finally {
                setLoading(false);
            }
        };

        fetchOrder();

        // Polling for updates every 30s
        const interval = setInterval(fetchOrder, 30000);
        return () => clearInterval(interval);
    }, [token]);

    // Driver: GPS Tracking
    useEffect(() => {
        if (!isDriver) return;

        const watchId = navigator.geolocation.watchPosition(
            (position) => {
                const { latitude, longitude } = position.coords;
                // Update local state immediately for smooth UI
                setOrder(prev => prev ? { ...prev, current_lat: latitude, current_lng: longitude } : null);

                // Send to backend
                api.post(`/api/v1/smart_links/${token}/location`, {
                    lat: latitude,
                    lng: longitude
                }).catch(console.error);
            },
            (err) => console.error("GPS Error:", err),
            { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
        );

        return () => navigator.geolocation.clearWatch(watchId);
    }, [isDriver, token]);

    const geocodeAddress = async (address: string) => {
        try {
            // Use Nominatim (OpenStreetMap) for free geocoding
            const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(address)}`);
            const data = await response.json();
            if (data && data.length > 0) {
                setDestinationCoords(new L.LatLng(parseFloat(data[0].lat), parseFloat(data[0].lon)));
            } else {
                console.warn("Address not found, using default Almaty center");
                setDestinationCoords(new L.LatLng(43.238949, 76.889709));
            }
        } catch (e) {
            console.error("Geocoding failed", e);
            // Fallback
            setDestinationCoords(new L.LatLng(43.238949, 76.889709));
        }
    };

    const handleRouteFound = (summary: any) => {
        // totalTime is in seconds
        const minutes = Math.round(summary.totalTime / 60);
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;

        let timeString = '';
        if (hours > 0) timeString += `${hours} ч `;
        timeString += `${mins} мин`;

        setEta(timeString);
    };

    if (loading) return <div className="flex justify-center items-center h-screen"><Loader2 className="animate-spin h-8 w-8" /></div>;
    if (error) return <div className="flex justify-center items-center h-screen text-red-500">{error}</div>;
    if (!order) return null;

    const driverPosition = order.current_lat && order.current_lng
        ? new L.LatLng(order.current_lat, order.current_lng)
        : null;

    // Default center: Driver pos or City center (Almaty)
    const mapCenter = driverPosition || new L.LatLng(43.238949, 76.889709);

    return (
        <div className="flex flex-col h-screen bg-gray-100">
            {/* Header / Info Panel */}
            <div className="bg-white p-4 shadow-md z-10 flex flex-col gap-4">
                <div className="flex justify-between items-start">
                    <div>
                        <h1 className="text-xl font-bold flex items-center gap-2">
                            <Clock className="h-5 w-5 text-blue-600" />
                            {eta ? `Прибудет через ~${eta}` : 'Расчет времени...'}
                        </h1>
                        <p className="text-sm text-gray-500 mt-1">Водитель: {order.driver_name} · {order.driver_car_number}</p>
                    </div>

                    <div className="flex items-center gap-2">
                        {isDriver ? (
                            <Badge className="bg-green-500 animate-pulse">GPS ON</Badge>
                        ) : (
                            <Button variant="outline" size="sm" onClick={() => setIsDriver(true)}>
                                Включить GPS
                            </Button>
                        )}
                    </div>
                </div>

                {/* Status Bar */}
                <div className="flex items-center gap-2 text-sm text-gray-600">
                    <MapPin className="h-4 w-4" />
                    <span className="truncate max-w-[300px]">{order.delivery_address}</span>
                </div>
            </div>

            {/* Map Area */}
            <div className="flex-1 relative">
                <MapContainer center={mapCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
                    <TileLayer
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    />

                    {/* Driver Marker */}
                    {driverPosition && (
                        <Marker position={driverPosition} icon={truckIcon}>
                            <Popup>
                                Водитель здесь
                            </Popup>
                        </Marker>
                    )}

                    {/* Destination Marker */}
                    {destinationCoords && (
                        <Marker position={destinationCoords}>
                            <Popup>Доставка сюда</Popup>
                        </Marker>
                    )}

                    {/* Route Line */}
                    {driverPosition && destinationCoords && (
                        <RoutingMachine start={driverPosition} end={destinationCoords} onRouteFound={handleRouteFound} />
                    )}
                </MapContainer>
            </div>

            {/* Simple Footer/Card for details */}
            <div className="fixed bottom-4 left-4 right-4 z-[500] pointer-events-none">
                <Card className="bg-white/90 backdrop-blur pointer-events-auto shadow-lg">
                    <CardContent className="p-4 flex items-center gap-4">
                        <div className="p-2 bg-blue-100 rounded-full">
                            <Truck className="h-6 w-6 text-blue-600" />
                        </div>
                        <div>
                            <p className="font-semibold">{order.status === 'in_transit' ? 'Заказ в пути' : 'Статус: ' + order.status}</p>
                            <p className="text-xs text-muted-foreground">Обновлено: {new Date().toLocaleTimeString()}</p>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
};

export default TrackingPage;
