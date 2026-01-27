import React, { useState, useEffect } from 'react';
import api from '@/lib/api';
import { Badge } from '@/components/ui/badge';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { RefreshCw } from 'lucide-react';

const CatalogNewPage: React.FC = () => {
    const [warehouseData, setWarehouseData] = useState<any>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [mockMode, setMockMode] = useState(false);

    useEffect(() => {
        const fetchStocks = async () => {
            // Mock Data Fallback logic if backend is empty
            const MOCK_DATA = {
                warehouse: "Атырау (Mock)",
                last_synced_at: new Date().toISOString(),
                items: [
                    { sku: "WHEEL-001", quantity: "500.0", synced_at: new Date().toISOString() },
                    { sku: "FRAME-022", quantity: "120.0", synced_at: new Date().toISOString() },
                    { sku: "BEAR-777", quantity: "0.0", synced_at: new Date().toISOString() },
                ]
            };

            try {
                // Fetch from new 1C integration endpoint
                const response = await api.get('/api/v1/integrations/one_c/stocks');

                if (response.data && response.data.items && response.data.items.length > 0) {
                    setWarehouseData(response.data);
                } else {
                    console.log("Empty response from 1C endpoint, using Mock data");
                    setWarehouseData(MOCK_DATA);
                    setMockMode(true);
                }
            } catch (error) {
                console.error("Failed to fetch 1C stocks:", error);
                setWarehouseData(MOCK_DATA); // Fallback to mock on error too for demo
                setMockMode(true);
            } finally {
                setIsLoading(false);
            }
        };

        fetchStocks();
    }, []);

    return (
        <div className="space-y-6">
            <div className="flex flex-col space-y-2">
                <h1 className="text-3xl font-bold tracking-tight text-gray-900">Склад 1С (Live)</h1>
                <p className="text-gray-500">Данные получают напрямую из интеграции с 1С.</p>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-12">
                    <span className="loading-spinner text-red-600">Загрузка данных из 1С...</span>
                </div>
            ) : (
                <>
                    {/* Status Banner */}
                    <div className="bg-blue-50 p-4 rounded-lg border border-blue-100 flex items-center justify-between">
                        <div>
                            <h3 className="font-semibold text-blue-900 flex items-center">
                                <RefreshCw className="w-4 h-4 mr-2" />
                                Статус Синхронизации
                            </h3>
                            <p className="text-sm text-blue-700 mt-1">
                                Склад: <strong>{warehouseData?.warehouse}</strong> <br />
                                Последнее обновление: {warehouseData?.last_synced_at ? new Date(warehouseData.last_synced_at).toLocaleString() : 'Никогда'}
                            </p>
                        </div>
                        {mockMode && (
                            <Badge variant="destructive">MOCK DATA MODE</Badge>
                        )}
                    </div>

                    {/* Stock Table */}
                    <div className="bg-white rounded-lg border shadow-sm overflow-hidden mt-6">
                        <Table>
                            <TableHeader>
                                <TableRow className="bg-gray-50/50">
                                    <TableHead>Артикул (SKU)</TableHead>
                                    <TableHead>Наименование (из 1С)</TableHead>
                                    <TableHead className="text-right">Остаток</TableHead>
                                    <TableHead className="text-right">Время актуальности</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {warehouseData?.items?.map((item: any, idx: number) => (
                                    <TableRow key={idx}>
                                        <TableCell className="font-mono">{item.sku}</TableCell>
                                        <TableCell>Товар #{item.sku} (Placeholder Name)</TableCell>
                                        <TableCell className="text-right font-bold">
                                            <span className={parseFloat(item.quantity) > 0 ? "text-green-600" : "text-red-500"}>
                                                {parseFloat(item.quantity).toFixed(0)} шт.
                                            </span>
                                        </TableCell>
                                        <TableCell className="text-right text-sm text-gray-500">
                                            {item.synced_at ? new Date(item.synced_at).toLocaleTimeString() : '-'}
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    </div>
                </>
            )}
        </div>
    );
};

export default CatalogNewPage;
