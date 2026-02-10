import React, { useState, useEffect, useMemo } from 'react';
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
    Tabs,
    TabsList,
    TabsTrigger,
} from "@/components/ui/tabs";
import { Checkbox } from "@/components/ui/checkbox";
import { RefreshCw, ShoppingCart, FileText, MapPin, Plus, Minus, Filter } from 'lucide-react';
import { useCart } from '@/context/CartContext';
import { useNavigate } from 'react-router-dom';

const WAREHOUSES = [
    { id: "000000001", name: "Павлодар", region: "северо-восток" }, // Main
    { id: "000000003", name: "Атырау", region: "запад" },
    { id: "000000005", name: "Аягоз", region: "восток / юго-восток" },
    { id: "000000004", name: "Караганда", region: "центр" },
    { id: "000000002", name: "Шымкент", region: "юг" }
];

const CatalogNewPage: React.FC = () => {
    const navigate = useNavigate();
    const { addToCart, items, updateQuantity } = useCart();
    const [selectedWarehouseId, setSelectedWarehouseId] = useState("000000001");
    const [warehouseData, setWarehouseData] = useState<any>(null);
    const [isLoading, setIsLoading] = useState(true);

    // UI State
    const [activeTab, setActiveTab] = useState('wheelsets');
    const [thicknessFilter, setThicknessFilter] = useState<string | null>(null);
    const [ageFilter, setAgeFilter] = useState<string | null>(null);

    // CP Selection State
    const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());

    // Constants from CatalogPage
    const thicknessRanges = ['30-34', '35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '64-69', 'СОНК'];
    const ageRanges = ['1-5 лет', '6-10 лет', '11-15 лет', '16-20 лет', '21-25 лет'];

    useEffect(() => {
        fetchStocks(selectedWarehouseId);
    }, [selectedWarehouseId]);

    const fetchStocks = async (warehouseId: string) => {
        setIsLoading(true);
        setSelectedItems(new Set());
        setThicknessFilter(null); // Reset filters on warehouse change
        setAgeFilter(null);

        try {
            const response = await api.get(`/api/v1/integrations/one_c/stocks?warehouse_id=${warehouseId}`);
            if (response.data) {
                setWarehouseData(response.data);
            }
        } catch (error) {
            console.error("Failed to fetch stocks:", error);
            setWarehouseData(null);
        } finally {
            setIsLoading(false);
        }
    };

    // Filter Logic
    const filteredItems = useMemo(() => {
        if (!warehouseData?.items) return [];

        return warehouseData.items.filter((item: any) => {
            // Tab filtering matches CatalogPage.tsx logic
            if (activeTab === 'wheelsets') {
                const isWheelset = item.category === 'Колесные пары';
                if (!isWheelset) return false;
                if (thicknessFilter && item.characteristics?.thickness !== thicknessFilter) return false;
                return true;
            }

            if (activeTab === 'casting') {
                const isCasting = item.category === 'Литье';
                const isOther = item.category === 'Прочие запчасти';
                if (!isCasting && !isOther) return false;

                if (ageFilter) {
                    if (item.characteristics?.age !== ageFilter) return false;
                }
                return true;
            }

            return false;
        });
    }, [warehouseData, activeTab, thicknessFilter, ageFilter]);

    // Selection Logic
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
        if (filteredItems.length === 0) return;

        // If all filtered items are selected, unselect them. Otherwise select all filtered.
        const allFilteredSkus = filteredItems.map((i: any) => i.sku);
        const allSelected = allFilteredSkus.every((sku: string) => selectedItems.has(sku));

        const newSelection = new Set(selectedItems);
        if (allSelected) {
            allFilteredSkus.forEach((sku: string) => newSelection.delete(sku));
        } else {
            allFilteredSkus.forEach((sku: string) => newSelection.add(sku));
        }
        setSelectedItems(newSelection);
    };

    // Cart Logic
    const getItemQuantity = (productId: string) => {
        if (!productId) return 0;
        return items.find(item => item.id === productId)?.quantity || 0;
    };

    const handleAddToCart = (item: any) => {
        if (!item.id) {
            console.error("Item has no ID, cannot add to cart", item);
            return;
        }
        // CartContext expects { id, attributes: { name, price, image_url } }
        addToCart({
            id: item.id,
            attributes: {
                name: item.name,
                price: item.price,
                image_url: item.image // StocksController returns 'image', CartContext expects image_url in attributes
            }
        });
    };

    const handleBulkAddToCart = () => {
        if (!warehouseData?.items) return;
        warehouseData.items.forEach((item: any) => {
            if (selectedItems.has(item.sku)) {
                // Check if already in cart to avoid double add
                const qty = getItemQuantity(item.id);
                if (qty === 0) {
                    handleAddToCart(item);
                }
            }
        });
    };

    // CP Logic
    const handleGetCP = async () => {
        if (selectedItems.size === 0) {
            alert("Выберите товары для КП");
            return;
        }

        const itemsPayload = warehouseData.items
            .filter((i: any) => selectedItems.has(i.sku))
            .map((i: any) => ({ id: i.id, quantity: 1 }));

        try {
            const response = await api.post('/api/v1/commercial_proposals', { items: itemsPayload }, {
                responseType: 'blob'
            });

            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `KP_Dynamix_${new Date().toISOString().split('T')[0]}.pdf`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error: any) {
            console.error("Failed to generate CP", error);
            if (error.response && error.response.status === 401) {
                alert("Пожалуйста, авторизуйтесь для скачивания КП");
            } else {
                alert("Ошибка генерации КП");
            }
        }
    };

    const currentWarehouseName = WAREHOUSES.find(w => w.id === selectedWarehouseId)?.name;

    return (
        <div className="space-y-6 container mx-auto py-8">
            <div className="flex flex-col space-y-2">
                <h1 className="text-3xl font-bold tracking-tight text-gray-900">Каталог (Live 1C)</h1>
                <p className="text-gray-500">Актуальные остатки напрямую из интеграции с 1С.</p>
            </div>

            {/* Global Warehouse Selector (Pills) */}
            <div className="bg-white p-4 rounded-lg border shadow-sm space-y-3">
                <label className="text-sm font-medium text-gray-700 flex items-center">
                    <MapPin className="w-4 h-4 mr-2 text-red-600" />
                    Выберите склад:
                </label>
                <div className="flex flex-wrap gap-2">
                    {WAREHOUSES.map((wh) => (
                        <Button
                            key={wh.id}
                            variant={selectedWarehouseId === wh.id ? "default" : "outline"}
                            size="sm"
                            onClick={() => setSelectedWarehouseId(wh.id)}
                            className={`rounded-full ${selectedWarehouseId === wh.id ? "bg-red-600 hover:bg-red-700" : "hover:bg-gray-100"}`}
                        >
                            {wh.name}
                        </Button>
                    ))}
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
                    <div className="bg-blue-50/50 p-3 rounded-lg border border-blue-100 flex items-center justify-between text-xs text-blue-600">
                        <div className="flex items-center">
                            <RefreshCw className="w-3 h-3 mr-2" />
                            Обновлено: {warehouseData?.last_synced_at ? new Date(warehouseData.last_synced_at).toLocaleString() : 'Только что'}
                        </div>
                        <div>
                            Склад: <b>{warehouseData?.warehouse?.name || currentWarehouseName}</b>
                        </div>
                    </div>

                    <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                        <TabsList className="grid w-full max-w-2xl grid-cols-2 mb-8">
                            <TabsTrigger value="wheelsets">Колесные пары</TabsTrigger>
                            <TabsTrigger value="casting">Литье и прочие</TabsTrigger>
                        </TabsList>

                        {/* Filters & Actions */}
                        <div className="space-y-6">
                            <div className="flex flex-wrap items-center justify-between gap-4">
                                {/* Filter Chips */}
                                <div className="flex flex-wrap items-center gap-4 bg-gray-50 p-4 rounded-lg border flex-1">
                                    <div className="flex items-center text-sm font-medium text-gray-600 mr-2">
                                        <Filter className="w-4 h-4 mr-2" />
                                        Фильтры:
                                    </div>
                                    {activeTab === 'wheelsets' && (
                                        <div className="flex flex-wrap gap-2">
                                            <Button variant={thicknessFilter === null ? "secondary" : "ghost"} size="sm" onClick={() => setThicknessFilter(null)} className={thicknessFilter === null ? "bg-red-100 text-red-700" : ""}>Все</Button>
                                            {thicknessRanges.map(r => (
                                                <Button key={r} variant={thicknessFilter === r ? "secondary" : "ghost"} size="sm" onClick={() => setThicknessFilter(r)} className={thicknessFilter === r ? "bg-red-100 text-red-700" : ""}>{r}</Button>
                                            ))}
                                        </div>
                                    )}
                                    {activeTab === 'casting' && (
                                        <div className="flex flex-wrap gap-2">
                                            <Button variant={ageFilter === null ? "secondary" : "ghost"} size="sm" onClick={() => setAgeFilter(null)} className={ageFilter === null ? "bg-red-100 text-red-700" : ""}>Все</Button>
                                            {ageRanges.map(r => (
                                                <Button key={r} variant={ageFilter === r ? "secondary" : "ghost"} size="sm" onClick={() => setAgeFilter(r)} className={ageFilter === r ? "bg-red-100 text-red-700" : ""}>{r}</Button>
                                            ))}
                                        </div>
                                    )}
                                </div>

                                {/* CP / Cart Actions */}
                                <div className="flex gap-2 items-center bg-white p-4 rounded-lg border shadow-sm">
                                    <div className="text-sm text-gray-600 mr-2">
                                        Выбрано: <b>{selectedItems.size}</b>
                                    </div>
                                    <Button variant="outline" onClick={handleGetCP} disabled={selectedItems.size === 0} className="border-red-200 hover:bg-red-50 text-red-700">
                                        <FileText className="w-4 h-4 mr-2" />
                                        КП
                                    </Button>
                                    <Button variant="secondary" onClick={handleBulkAddToCart} disabled={selectedItems.size === 0}>
                                        <ShoppingCart className="w-4 h-4 mr-2" />
                                        В корзину
                                    </Button>
                                    <Button className="bg-red-600 hover:bg-red-700 shadow-lg shadow-red-200" onClick={() => navigate('/cart')}>
                                        Корзина ({items.reduce((acc, i) => acc + i.quantity, 0)})
                                    </Button>
                                </div>
                            </div>

                            {/* Table */}
                            <div className="bg-white rounded-xl border shadow-sm overflow-hidden">
                                <Table>
                                    <TableHeader>
                                        <TableRow className="bg-gray-50/50 hover:bg-gray-50/50">
                                            <TableHead className="w-[50px]">
                                                <Checkbox
                                                    checked={filteredItems.length > 0 && filteredItems.every((i: any) => selectedItems.has(i.sku))}
                                                    onChange={toggleAll}
                                                />
                                            </TableHead>
                                            <TableHead>Наименование</TableHead>
                                            <TableHead>Характеристики</TableHead>
                                            <TableHead>Артикул</TableHead>
                                            <TableHead className="text-right">Цена</TableHead>
                                            <TableHead className="text-right">Остаток</TableHead>
                                            <TableHead className="text-right w-[150px]">Корзина</TableHead>
                                        </TableRow>
                                    </TableHeader>
                                    <TableBody>
                                        {filteredItems.length > 0 ? (
                                            filteredItems.map((item: any) => {
                                                const quantity = getItemQuantity(item.id);
                                                return (
                                                    <TableRow key={item.sku} className="group hover:bg-gray-50/50 transition-colors">
                                                        <TableCell>
                                                            <Checkbox
                                                                checked={selectedItems.has(item.sku)}
                                                                onChange={() => toggleSelection(item.sku)}
                                                            />
                                                        </TableCell>
                                                        <TableCell className="font-medium">{item.name}</TableCell>
                                                        <TableCell>
                                                            <div className="flex flex-wrap gap-1">
                                                                {item.characteristics?.thickness && (
                                                                    <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">
                                                                        {item.characteristics.thickness} мм
                                                                    </Badge>
                                                                )}
                                                                {item.characteristics?.age && (
                                                                    <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                                                                        {item.characteristics.age}
                                                                    </Badge>
                                                                )}
                                                                {item.characteristics?.year && (
                                                                    <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">
                                                                        {item.characteristics.year}
                                                                    </Badge>
                                                                )}
                                                            </div>
                                                        </TableCell>
                                                        <TableCell className="font-mono text-xs text-gray-500">{item.sku}</TableCell>
                                                        <TableCell className="text-right font-semibold text-red-600">
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
                                                <TableCell colSpan={7} className="text-center py-12 text-gray-500">
                                                    Нет товаров по выбранным фильтрам
                                                </TableCell>
                                            </TableRow>
                                        )}
                                    </TableBody>
                                </Table>
                            </div>
                        </div>
                    </Tabs>
                </>
            )}
        </div>
    );
};

export default CatalogNewPage;
