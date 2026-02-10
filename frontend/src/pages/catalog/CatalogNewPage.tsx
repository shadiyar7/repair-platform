import React, { useState, useEffect } from 'react';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
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
import { RefreshCw, ShoppingCart, FileText, MapPin, Plus, Minus } from 'lucide-react';
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
    const { addToCart, items, updateQuantity } = useCart(); // Added items, updateQuantity
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
            id: item.id,
            name: item.name,
            price: parseFloat(item.price),
            sku: item.sku,
            image: null // 1C doesn't provide images yet
        });
    };

    const getItemQuantity = (productId: string) => {
        return items.find(item => item.id === productId)?.quantity || 0;
    };

    const handleBulkAddToCart = () => {
        if (!warehouseData?.items) return;
        warehouseData.items.forEach((item: any) => {
            if (selectedItems.has(item.sku)) {
                // Check if already in cart to avoid double add or just rely on addToCart logic
                const qty = getItemQuantity(item.id);
                if (qty === 0) {
                    handleAddToCart(item);
                }
            }
        });
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
            link.setAttribute('download', `KP_Dynamix_${new Date().toISOString().split('T')[0]}.pdf`);
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
                    <h1 className="text-3xl font-bold tracking-tight text-gray-900">Каталог (Live)</h1>
                    <p className="text-gray-500">Актуальные остатки напрямую из 1С</p>
                </div>

                <div className="flex items-center gap-4">
                    <div className="flex items-center bg-white p-2 rounded-lg border shadow-sm">
                        <MapPin className="w-4 h-4 mr-2 text-red-600" />
                        <Select onValueChange={setSelectedWarehouse} defaultValue={selectedWarehouse}>
                            <SelectTrigger className="w-[250px] border-none shadow-none focus:ring-0">
                                <SelectValue placeholder="Выберите склад" />
                            </SelectTrigger>
                            <SelectContent>
                                {WAREHOUSES.map((wh) => (
                                    <SelectItem key={wh.id} value={wh.id}>
                                        {wh.name}
                                    </SelectItem>
                                ))}
                            </SelectContent>
                        </Select>
                    </div>
                </div>
            </div>

            {/* Actions Bar */}
            <div className="flex flex-wrap gap-2 items-center justify-between bg-white p-4 rounded-lg border shadow-sm sticky top-0 z-10">
                <div className="text-sm text-gray-600 flex items-center">
                    <CheckSquareIcon checked={selectedItems.size > 0 && selectedItems.size === warehouseData?.items?.length} onClick={toggleAll} />
                    <span className="ml-2">Выбрано: <b>{selectedItems.size}</b></span>
                </div>
                <div className="flex gap-2">
                    <Button variant="outline" onClick={handleGetCP} disabled={selectedItems.size === 0} className="border-red-200 hover:bg-red-50 text-red-700">
                        <FileText className="w-4 h-4 mr-2" />
                        Скачать КП
                    </Button>
                    <Button variant="secondary" onClick={handleBulkAddToCart} disabled={selectedItems.size === 0}>
                        <ShoppingCart className="w-4 h-4 mr-2" />
                        В корзину (Выбранное)
                    </Button>
                    <Button className="bg-red-600 hover:bg-red-700 shadow-lg shadow-red-200" onClick={() => navigate('/cart')}>
                        Корзина ({items.reduce((acc, i) => acc + i.quantity, 0)})
                    </Button>
                </div>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-24">
                    <div className="flex flex-col items-center gap-4">
                        <div className="loading-spinner text-red-600 w-8 h-8 border-4 border-red-600 border-t-transparent rounded-full animate-spin"></div>
                        <span className="text-gray-500">Синхронизация с 1С...</span>
                    </div>
                </div>
            ) : (
                <>
                    {/* Status Banner */}
                    <div className="bg-blue-50/50 p-3 rounded-lg border border-blue-100 flex items-center justify-between text-xs text-blue-600 mb-4">
                        <div className="flex items-center">
                            <RefreshCw className="w-3 h-3 mr-2" />
                            Данные обновлены: {warehouseData?.last_synced_at ? new Date(warehouseData.last_synced_at).toLocaleString() : 'Только что'}
                        </div>
                        <div>
                            Склад: <b>{warehouseData?.warehouse?.name || selectedWarehouse}</b>
                        </div>
                    </div>

                    {/* Stock Table */}
                    <div className="bg-white rounded-xl border shadow-sm get-started-card overflow-hidden">
                        <Table>
                            <TableHeader>
                                <TableRow className="bg-gray-50/50 hover:bg-gray-50/50">
                                    <TableHead className="w-[50px]">
                                        <Checkbox
                                            checked={selectedItems.size > 0 && selectedItems.size === warehouseData?.items?.length}
                                            onChange={toggleAll}
                                        />
                                    </TableHead>
                                    <TableHead>Наименование</TableHead>
                                    <TableHead>Артикул</TableHead>
                                    <TableHead className="text-right">Цена</TableHead>
                                    <TableHead className="text-right">Остаток</TableHead>
                                    <TableHead className="text-right w-[150px]">В корзину</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {warehouseData?.items?.length > 0 ? (
                                    warehouseData.items.map((item: any) => {
                                        const quantity = getItemQuantity(item.id);
                                        return (
                                            <TableRow key={item.sku} className="group hover:bg-gray-50/50 transition-colors">
                                                <TableCell>
                                                    <Checkbox
                                                        checked={selectedItems.has(item.sku)}
                                                        onChange={() => toggleSelection(item.sku)}
                                                    />
                                                </TableCell>
                                                <TableCell className="font-medium">
                                                    <div className="flex flex-col">
                                                        <span>{item.name}</span>
                                                        {/* Characteristics Badges */}
                                                        {item.characteristics && (
                                                            <div className="flex flex-wrap gap-1 mt-1">
                                                                {Object.entries(item.characteristics).map(([key, val]) => (
                                                                    <Badge key={key} variant="secondary" className="text-[10px] px-1 py-0 h-4 bg-gray-100 text-gray-600 font-normal">
                                                                        {key}: {String(val)}
                                                                    </Badge>
                                                                ))}
                                                            </div>
                                                        )}
                                                    </div>
                                                </TableCell>
                                                <TableCell className="font-mono text-xs text-gray-500">{item.sku}</TableCell>
                                                <TableCell className="text-right font-semibold text-gray-900">
                                                    {new Intl.NumberFormat('ru-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(item.price)}
                                                </TableCell>
                                                <TableCell className="text-right">
                                                    <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${parseFloat(item.quantity) > 0 ? "bg-green-50 text-green-700" : "bg-red-50 text-red-700"}`}>
                                                        {parseFloat(item.quantity) > 0 ? `${parseFloat(item.quantity)} шт.` : "Нет"}
                                                    </span>
                                                </TableCell>
                                                <TableCell className="text-right">
                                                    {quantity > 0 ? (
                                                        <div className="flex items-center justify-end space-x-1">
                                                            <Button
                                                                variant="outline"
                                                                size="icon"
                                                                className="h-8 w-8 rounded-full border-gray-200"
                                                                onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, quantity - 1); }}
                                                            >
                                                                <Minus className="h-3 w-3" />
                                                            </Button>
                                                            <span className="w-6 text-center text-sm font-medium">{quantity}</span>
                                                            <Button
                                                                variant="outline"
                                                                size="icon"
                                                                className="h-8 w-8 rounded-full border-gray-200"
                                                                onClick={(e) => { e.stopPropagation(); updateQuantity(item.id, quantity + 1); }}
                                                            >
                                                                <Plus className="h-3 w-3" />
                                                            </Button>
                                                        </div>
                                                    ) : (
                                                        <Button
                                                            size="sm"
                                                            variant="ghost"
                                                            className="h-8 w-8 p-0 rounded-full hover:bg-red-50 hover:text-red-600"
                                                            onClick={(e) => { e.stopPropagation(); handleAddToCart(item); }}
                                                        >
                                                            <ShoppingCart className="w-5 h-5" />
                                                        </Button>
                                                    )}
                                                </TableCell>
                                            </TableRow>
                                        )
                                    })
                                ) : (
                                    <TableRow>
                                        <TableCell colSpan={6} className="text-center py-12 text-gray-500">
                                            Нет товаров на данном складе
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

// Helper for select all checkbox icon
const CheckSquareIcon = ({ checked, onClick }: { checked: boolean, onClick: () => void }) => (
    <div onClick={onClick} className={`w-4 h-4 mr-2 border rounded cursor-pointer flex items-center justify-center ${checked ? 'bg-primary border-primary text-white' : 'border-gray-300'}`}>
        {checked && <div className="w-2 h-2 bg-current rounded-[1px]" />}
    </div>
);

export default CatalogNewPage;
