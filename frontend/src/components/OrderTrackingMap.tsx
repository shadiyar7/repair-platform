import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-routing-machine/dist/leaflet-routing-machine.css';
import 'leaflet-routing-machine';
import { Clock, AlertTriangle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import api from '@/lib/api';

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

interface OrderTrackingMapProps {
    order: {
        id: number;
        status: string;
        delivery_address: string;
        driver_name?: string;
        driver_car_number?: string;
        current_lat?: number | null;
        current_lng?: number | null;
        warehouse_name?: string;
        smart_link_token?: string; // Add token for polling
    };
    className?: string; // Add className for custom styling
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
            if (onRouteFound) onRouteFound(e);
        });

        routingControl.addTo(map);

        return () => {
            try {
                map.removeControl(routingControl);
            } catch (e) {
                console.warn("Error removing routing control", e);
            }
        };
    }, [map, start.lat, start.lng, end.lat, end.lng]);

    return null;
};

const OrderTrackingMap: React.FC<OrderTrackingMapProps> = ({ order: initialOrder, className }) => {
    const [orderData, setOrderData] = useState(initialOrder);
    const [destinationCoords, setDestinationCoords] = useState<L.LatLng | null>(null);
    const [eta, setEta] = useState<string | null>(null);

    // Initial Geocoding
    useEffect(() => {
        if (orderData.delivery_address) {
            geocodeAddress(orderData.delivery_address);
        }
    }, [orderData.delivery_address]);

    // Polling Logic
    useEffect(() => {
        if (!initialOrder.smart_link_token) return;

        const fetchUpdates = async () => {
            try {
                const res = await api.get(`/api/v1/smart_links/${initialOrder.smart_link_token}`);
                setOrderData(prev => ({ ...prev, ...res.data }));
            } catch (error) {
                console.error("Failed to poll order updates", error);
            }
        };

        // Poll every 10 seconds
        const interval = setInterval(fetchUpdates, 10000);
        return () => clearInterval(interval);
    }, [initialOrder.smart_link_token]);

    const geocodeAddress = async (address: string) => {
        try {
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
            setDestinationCoords(new L.LatLng(43.238949, 76.889709));
        }
    };

    const handleRouteFound = (e: any) => {
        console.log("Route found:", e);
        const routes = e.routes;
        if (routes && routes.length > 0) {
            const summary = routes[0].summary;
            // Remove traffic buffer to match driver's view
            const minutes = Math.round(summary.totalTime / 60);

            let timeString = '';
            const hours = Math.floor(minutes / 60);
            const mins = minutes % 60;

            if (hours > 0) timeString += `${hours} ч `;
            timeString += `${mins} мин`;

            console.log("Calculated ETA (Raw):", timeString);
            setEta(timeString);
        }
    };

    const driverPosition = orderData.current_lat && orderData.current_lng
        ? new L.LatLng(orderData.current_lat, orderData.current_lng)
        : null;

    const mapCenter = driverPosition || new L.LatLng(43.238949, 76.889709);

    return (
        <Card className={`overflow-hidden border-2 border-blue-100 shadow-md ${className}`}>
            <CardContent className="p-0 relative h-full">
                {/* Enhanced Floating Status Card */}
                <div className="absolute top-4 left-4 z-[500] bg-white/95 backdrop-blur shadow-2xl rounded-xl p-4 border border-blue-100 max-w-[280px] space-y-3">
                    <div className="flex items-center gap-3 border-b border-gray-100 pb-2">
                        <div className="bg-blue-100 p-2 rounded-full">
                            <Clock className="h-5 w-5 text-blue-600" />
                        </div>
                        <div>
                            <p className="text-xs text-gray-500 uppercase font-bold tracking-wider">Прибытие через</p>
                            <p className="text-2xl font-black text-blue-900 leading-none">
                                {eta ? eta : <span className="text-lg text-gray-400 animate-pulse">Расчет...</span>}
                            </p>
                        </div>
                    </div>

                    <div className="space-y-1">
                        <div className="flex justify-between text-xs">
                            <span className="text-gray-500">Водитель:</span>
                            <span className="font-semibold text-gray-900 text-right">{orderData.driver_name || 'Не назначен'}</span>
                        </div>
                        <div className="flex justify-between text-xs">
                            <span className="text-gray-500">Авто:</span>
                            <span className="font-semibold text-gray-900">{orderData.driver_car_number || '---'}</span>
                        </div>
                    </div>
                </div>

                <MapContainer center={mapCenter} zoom={13} style={{ height: '100%', width: '100%' }}>
                    <TileLayer
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    />

                    {driverPosition && (
                        <Marker position={driverPosition} icon={truckIcon}>
                            <Popup>Водитель</Popup>
                        </Marker>
                    )}

                    {destinationCoords && (
                        <Marker position={destinationCoords}>
                            <Popup>Место доставки</Popup>
                        </Marker>
                    )}

                    {driverPosition && destinationCoords && (
                        <RoutingMachine start={driverPosition} end={destinationCoords} onRouteFound={handleRouteFound} />
                    )}
                </MapContainer>

                {/* Disclaimer Footer */}
                <div className="absolute bottom-0 left-0 right-0 bg-white/90 backdrop-blur p-2 z-[400] border-t flex items-center justify-center gap-2 text-xs text-orange-600 text-center">
                    <AlertTriangle className="h-3 w-3 flex-shrink-0" />
                    <span>
                        Информация обновляется в реальном времени. Возможны задержки из-за качества связи.
                    </span>
                </div>
            </CardContent>
        </Card>
    );
};

export default OrderTrackingMap;
