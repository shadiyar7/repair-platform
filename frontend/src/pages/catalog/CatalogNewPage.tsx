import React, { useState, useEffect } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { RefreshCw, ShoppingCart, FileText } from 'lucide-react';
import { useCart } from '@/context/CartContext';
import { useNavigate } from 'react-router-dom';

const WAREHOUSES = [
    { id: "000000001", name: "Павлодар (Основной)" },
    { id: "000000003", name: "Атырау" },
    { id: "000000005", name: "Аягоз" },
    { id: "000000004", name: "Караганда" },
    { id: "000000002", name: "Шымкент" }
];

const CatalogNewPage: React.FC = () => {
    const navigate = useNavigate();
    const { addToCart } = useCart();
    const [selectedWarehouse, setSelectedWarehouse] = useState("000000001");
    const [warehouseData, setWarehouseData] = useState<any>(null);
    const [isLoading, setIsLoading] = useState(true);

    // Selection state
    const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());

    useEffect(() => {
        fetchStocks(selectedWarehouse);
    }, [selectedWarehouse]);

    const fetchStocks = async (warehouseId: string) => {
        setIsLoading(true);
        // Clear selection on warehouse change
        setSelectedItems(new Set());

        try {
            const response = await api.get(`/api/v1/integrations/one_c/stocks?warehouse_id=${warehouseId}`);
            if (response.data) {
                setWarehouseData(response.data);
            }
        } catch (error) {
            console.error("Failed to fetch stocks:", error);
            // Fallback for demo if needed, but preferably show error
            setWarehouseData(null);
        } finally {
            setIsLoading(false);
        }
    };

    const toggleSelection = (sku: string) => {
        const newSelection = new Set(selectedItems);
        if (newSelection.has(sku)) {
            newSelection.delete(sku);
        } else {
            newSelection.add(sku);
        }
        setSelectedItems(newSelection);
    };

    const toggleAll = () => {
        if (selectedItems.size === warehouseData?.items?.length) {
            setSelectedItems(new Set());
        } else {
            const allSkus = warehouseData?.items?.map((i: any) => i.sku) as string[];
            setSelectedItems(new Set(allSkus));
        }
    };

    const handleAddToCart = (item: any) => {
        addToCart({
            id: item.id, // Ensure backend sends ID
            name: item.name,
            price: parseFloat(item.price),
            sku: item.sku,
            image: null
        });
    };

    const handleBulkAddToCart = () => {
        if (!warehouseData?.items) return;
        warehouseData.items.forEach((item: any) => {
            if (selectedItems.has(item.sku)) {
                handleAddToCart(item);
            }
        });
        // Optional: show toast
    };

    const handleGetCP = async () => {
        if (selectedItems.size === 0) {
            alert("Выберите товары для КП");
            return;
        }

        const itemsPayload = warehouseData.items
            .filter((i: any) => selectedItems.has(i.sku))
            .map((i: any) => ({ id: i.id, quantity: 1 })); // Default qty 1 for CP, user didn't specify qty input logic

        try {
            const response = await api.post('/api/v1/commercial_proposals', { items: itemsPayload }, {
                responseType: 'blob'
            });

            // Create blob link to download
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', 'KP_Dynamix.pdf');
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error) {
            console.error("Failed to generate CP", error);
            alert("Ошибка генерации КП");
        }
    };

    return (
        <div className="space-y-6 container mx-auto py-8">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-gray-900">Каталог (1С Live)</h1>
                    <p className="text-gray-500">Актуальные остатки напрямую из 1С</p>
                </div>

                <div className="flex items-center gap-4">
                    <Select onValueChange={setSelectedWarehouse} defaultValue={selectedWarehouse}>
                        <SelectTrigger className="w-[250px]">
                            <SelectValue placeholder="Выберите склад" />
                        </SelectTrigger>
                        <SelectContent>
                            {WAREHOUSES.map((wh) => (
                                <SelectItem key={wh.id} value={wh.id}>
                                    {wh.name} {wh.id === "000000001" && "(Main)"}
                                </SelectItem>
                            ))}
                        </SelectContent>
                    </Select>
                </div>
            </div>

            {/* Actions Bar */}
            <div className="flex flex-wrap gap-2 items-center justify-between bg-white p-4 rounded-lg border shadow-sm">
                <div className="text-sm text-gray-600">
                    Выбрано позиций: <b>{selectedItems.size}</b>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={handleGetCP} disabled={selectedItems.size === 0}>
                        <FileText className="w-4 h-4 mr-2" />
                        Скачать КП
                    </Button>
                    <Button variant="secondary" onClick={handleBulkAddToCart} disabled={selectedItems.size === 0}>
                        <ShoppingCart className="w-4 h-4 mr-2" />
                        В корзину
                    </Button>
                    <Button className="bg-red-600 hover:bg-red-700" onClick={() => navigate('/cart')}>
                        Оформить заказ
                    </Button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-12">
                    <span className="loading-spinner text-red-600">Загрузка данных из 1С...</span>
                </div>
            ) : (
                <>
                    {/* Status Banner */}
                    <div className="bg-blue-50 p-4 rounded-lg border border-blue-100 flex items-center justify-between text-sm">
                        <div className="flex items-center text-blue-800">
                            <RefreshCw className="w-4 h-4 mr-2" />
                            Синхронизация: {warehouseData?.last_synced_at ? new Date(warehouseData.last_synced_at).toLocaleString() : 'Никогда'}
                        </div>
                        <div className="text-blue-600">
                            Склад: <b>{warehouseData?.warehouse?.name || selectedWarehouse}</b>
                        </div>
                    </div>

                    {/* Stock Table */}
                    <div className="bg-white rounded-lg border shadow-sm overflow-hidden mt-6">
                        <Table>
                            <TableHeader>
                                <TableRow className="bg-gray-50/50">
                                    <TableHead className="w-[50px]">
                                        <Checkbox
                                            checked={selectedItems.size > 0 && selectedItems.size === warehouseData?.items?.length}
                                            onChange={toggleAll}
                                        />
                                    </TableHead>
                                    <TableHead>Артикул</TableHead>
                                    <TableHead>Наименование</TableHead>
                                    <TableHead className="text-right">Цена</TableHead>
                                    <TableHead className="text-right">Остаток</TableHead>
                                    <TableHead className="text-right">Действия</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {warehouseData?.items?.length > 0 ? (
                                    warehouseData.items.map((item: any) => (
                                        <TableRow key={item.sku}>
                                            <TableCell>
                                                <Checkbox
                                                    checked={selectedItems.has(item.sku)}
                                                    onChange={() => toggleSelection(item.sku)}
                                                />
                                            </TableCell>
                                            <TableCell className="font-mono text-xs">{item.sku}</TableCell>
                                            <TableCell className="font-medium">{item.name}</TableCell>
                                            <TableCell className="text-right">
                                                {new Intl.NumberFormat('ru-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price)}
                                            </TableCell>
                                            <TableCell className="text-right">
                                                <span className={parseFloat(item.quantity) > 0 ? "text-green-600 font-bold" : "text-red-500"}>
                                                    {parseFloat(item.quantity)} шт.
                                                </span>
                                            </TableCell>
                                            <TableCell className="text-right">
                                                <Button size="sm" variant="ghost" className="h-8 w-8 p-0" onClick={() => handleAddToCart(item)}>
                                                    <ShoppingCart className="w-4 h-4" />
                                                </Button>
                                            </TableCell>
                                        </TableRow>
                                    ))
                                ) : (
                                    <TableRow>
                                        <TableCell colSpan={6} className="text-center py-8 text-gray-500">
                                            Нет данных или товаров на этом складе
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </div>
                </>
            )}
        </div>
    );
};

export default CatalogNewPage;
