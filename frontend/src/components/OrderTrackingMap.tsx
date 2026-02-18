import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-routing-machine/dist/leaflet-routing-machine.css';
import 'leaflet-routing-machine';
import { Clock, AlertTriangle } from 'lucide-react';
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
    }
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
            if (onRouteFound) onRouteFound(summary);
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

const OrderTrackingMap: React.FC<OrderTrackingMapProps> = ({ order }) => {
    const [destinationCoords, setDestinationCoords] = useState<L.LatLng | null>(null);
    const [eta, setEta] = useState<string | null>(null);

    // Initial Geocoding
    useEffect(() => {
        if (order.delivery_address) {
            geocodeAddress(order.delivery_address);
        }
    }, [order.delivery_address]);

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

    const handleRouteFound = (summary: any) => {
        const minutes = Math.round(summary.totalTime / 60);
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;

        let timeString = '';
        if (hours > 0) timeString += `${hours} ч `;
        timeString += `${mins} мин`;

        setEta(timeString);
    };

    const driverPosition = order.current_lat && order.current_lng
        ? new L.LatLng(order.current_lat, order.current_lng)
        : null;

    const mapCenter = driverPosition || new L.LatLng(43.238949, 76.889709);

    return (
        <Card className="overflow-hidden border-2 border-blue-100 shadow-md">
            <CardContent className="p-0 relative h-[500px]">
                {/* Map Overlay Info */}
                <div className="absolute top-4 left-4 z-[400] bg-white/90 backdrop-blur p-3 rounded-lg shadow-lg max-w-xs">
                    <div className="flex items-center gap-2 mb-1">
                        <Clock className="h-5 w-5 text-blue-600" />
                        <span className="font-bold text-lg">
                            {eta ? `~${eta}` : 'Расчет...'}
                        </span>
                    </div>
                    <p className="text-sm text-gray-600">
                        {order.driver_name} · {order.driver_car_number}
                    </p>
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
                <div className="absolute bottom-0 left-0 right-0 bg-white/90 backdrop-blur p-2 z-[400] border-t flex items-center justify-center gap-2 text-xs text-orange-600">
                    <AlertTriangle className="h-3 w-3" />
                    <span>
                        Информация обновляется каждые 5 минут. Возможны задержки из-за качества связи в пути.
                    </span>
                </div>
            </CardContent>
        </Card>
    );
};

export default OrderTrackingMap;
