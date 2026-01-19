import React, { useState, useMemo, useEffect } from 'react';
import { useCart } from '@/context/CartContext';
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
import { ShoppingCart, Plus, Minus, MapPin, Filter } from 'lucide-react';

const CatalogPage: React.FC = () => {
    const { addToCart, items, updateQuantity } = useCart();
    const [activeTab, setActiveTab] = useState('wheelsets');
    const [selectedWarehouse, setSelectedWarehouse] = useState('Атырау');
    const [thicknessFilter, setThicknessFilter] = useState<string | null>(null);
    const [ageFilter, setAgeFilter] = useState<string | null>(null);

    const warehouses = [
        { name: 'Атырау', region: 'запад' },
        { name: 'Кушмурун', region: 'север' },
        { name: 'Павлодар', region: 'северо-восток' },
        { name: 'Аягоз', region: 'восток / юго-восток' },
        { name: 'Шымкент', region: 'юг' }
    ];

    const thicknessRanges = ['30-34', '35-39', '40-44', '45-49', '50-54', '55-59', '60-64', '64-69', 'СОНК'];
    const ageRanges = ['1-5 лет', '6-10 лет', '11-15 лет', '16-20 лет', '21-25 лет'];

    const [products, setProducts] = useState<any[]>([]);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        const fetchProducts = async () => {
            try {
                const response = await api.get('/api/v1/products');
                // Creating a structure compatible with the existing code
                // Expecting response.data.data to be an array of JSON:API objects
                if (response.data && response.data.data) {
                    setProducts(response.data.data);
                }
            } catch (error) {
                console.error("Failed to fetch products:", error);
            } finally {
                setIsLoading(false);
            }
        };

        fetchProducts();
    }, []);
    // ----------------------------

    const filteredProducts = useMemo(() => {
        return products.filter((p: any) => {
            const attrs = p.attributes;
            const matchesWarehouse = attrs.warehouse_location === selectedWarehouse;
            if (!matchesWarehouse) return false;

            if (activeTab === 'wheelsets') {
                const isWheelset = attrs.category === 'Колесные пары';
                if (!isWheelset) return false;
                if (thicknessFilter && attrs.characteristics?.thickness !== thicknessFilter) return false;
                return true;
            }

            if (activeTab === 'casting') {
                const isCasting = attrs.category === 'Литье';
                const isOther = attrs.category === 'Прочие запчасти';

                // Show both Casting and Other in this tab? The user grouped them in "Литье и прочие"
                if (!isCasting && !isOther) return false;

                if (ageFilter) {
                    // Only apply age filter to items that HAVE age. 
                    // If item is 'Autoscepka' or 'Other', it doesn't have age.
                    // If user selects age filter, should we hide items without age? Usually yes.
                    if (attrs.characteristics?.age !== ageFilter) return false;
                }

                return true;
            }

            return false;
        });
    }, [products, activeTab, selectedWarehouse, thicknessFilter, ageFilter]);

    const getItemQuantity = (productId: string) => {
        return items.find(item => item.id === productId)?.quantity || 0;
    };

    return (
        <div className="space-y-6">
            <div className="flex flex-col space-y-2">
                <h1 className="text-3xl font-bold tracking-tight text-gray-900">Каталог продукции</h1>
                <p className="text-gray-500">Выберите склад и категорию для просмотра доступных запчастей.</p>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-12">
                    <span className="loading-spinner text-red-600">Загрузка каталога...</span>
                </div>
            ) : (
                <>
                    {/* Global Warehouse Selector */}
                    <div className="bg-white p-4 rounded-lg border shadow-sm space-y-3">
                        <label className="text-sm font-medium text-gray-700 flex items-center">
                            <MapPin className="w-4 h-4 mr-2 text-red-600" />
                            Выберите склад:
                        </label>
                        <div className="flex flex-wrap gap-2">
                            {warehouses.map((wh) => (
                                <Button
                                    key={wh.name}
                                    variant={selectedWarehouse === wh.name ? "default" : "outline"}
                                    size="sm"
                                    onClick={() => setSelectedWarehouse(wh.name)}
                                    className={`rounded-full ${selectedWarehouse === wh.name ? "bg-red-600 hover:bg-red-700" : "hover:bg-gray-100"}`}
                                >
                                    {wh.name}
                                </Button>
                            ))}
                        </div>
                    </div>

                    <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
                        <TabsList className="grid w-full max-w-2xl grid-cols-2 mb-8">
                            <TabsTrigger value="wheelsets" active={activeTab === 'wheelsets'}>
                                Колесные пары
                            </TabsTrigger>
                            <TabsTrigger value="casting" active={activeTab === 'casting'}>
                                Литье и прочие
                            </TabsTrigger>
                        </TabsList>

                        {(activeTab === 'wheelsets' || activeTab === 'casting') && (
                            <div className="space-y-6">
                                {/* Filters */}
                                <div className="flex flex-wrap items-center gap-4 bg-gray-50 p-4 rounded-lg border">
                                    <div className="flex items-center text-sm font-medium text-gray-600 mr-2">
                                        <Filter className="w-4 h-4 mr-2" />
                                        Фильтры:
                                    </div>

                                    {activeTab === 'wheelsets' && (
                                        <div className="flex flex-wrap gap-2">
                                            <Button
                                                variant={thicknessFilter === null ? "secondary" : "ghost"}
                                                size="sm"
                                                onClick={() => setThicknessFilter(null)}
                                                className={thicknessFilter === null ? "bg-red-100 text-red-700 hover:bg-red-200" : ""}
                                            >
                                                Все толщины
                                            </Button>
                                            {thicknessRanges.map(range => (
                                                <Button
                                                    key={range}
                                                    variant={thicknessFilter === range ? "secondary" : "ghost"}
                                                    size="sm"
                                                    onClick={() => setThicknessFilter(range)}
                                                    className={thicknessFilter === range ? "bg-red-100 text-red-700 hover:bg-red-200" : ""}
                                                >
                                                    {range}
                                                </Button>
                                            ))}
                                        </div>
                                    )}

                                    {activeTab === 'casting' && (
                                        <div className="flex flex-wrap gap-2">
                                            <Button
                                                variant={ageFilter === null ? "secondary" : "ghost"}
                                                size="sm"
                                                onClick={() => setAgeFilter(null)}
                                                className={ageFilter === null ? "bg-red-100 text-red-700 hover:bg-red-200" : ""}
                                            >
                                                Все года
                                            </Button>
                                            {ageRanges.map(range => (
                                                <Button
                                                    key={range}
                                                    variant={ageFilter === range ? "secondary" : "ghost"}
                                                    size="sm"
                                                    onClick={() => setAgeFilter(range)}
                                                    className={ageFilter === range ? "bg-red-100 text-red-700 hover:bg-red-200" : ""}
                                                >
                                                    {range}
                                                </Button>
                                            ))}
                                        </div>
                                    )}
                                </div>

                                {/* Product Table */}
                                <div className="bg-white rounded-lg border shadow-sm overflow-hidden">
                                    <Table>
                                        <TableHeader>
                                            <TableRow className="bg-gray-50/50">
                                                <TableHead className="w-[40%]">Наименование</TableHead>
                                                <TableHead>Характеристики</TableHead>
                                                <TableHead>Цена</TableHead>
                                                <TableHead>Наличие</TableHead>
                                                <TableHead className="text-right">Действие</TableHead>
                                            </TableRow>
                                        </TableHeader>
                                        <TableBody>
                                            {filteredProducts.length > 0 ? (
                                                filteredProducts.map((product: any) => {
                                                    const quantity = getItemQuantity(product.id);
                                                    const attrs = product.attributes;
                                                    return (
                                                        <TableRow key={product.id}>
                                                            <TableCell className="font-medium">
                                                                {attrs.name}
                                                                <div className="text-xs text-gray-400 font-normal mt-1">SKU: {attrs.sku}</div>
                                                            </TableCell>
                                                            <TableCell>
                                                                {attrs.characteristics?.thickness && (
                                                                    <Badge variant="outline" className="bg-red-50 text-red-700 border-red-200">
                                                                        Толщина: {attrs.characteristics.thickness} мм
                                                                    </Badge>
                                                                )}
                                                                {attrs.characteristics?.age && (
                                                                    <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                                                                        Возраст: {attrs.characteristics.age}
                                                                    </Badge>
                                                                )}
                                                                {attrs.characteristics?.year && (
                                                                    <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">
                                                                        Год: {attrs.characteristics.year}
                                                                    </Badge>
                                                                )}
                                                                {!attrs.characteristics?.thickness && !attrs.characteristics?.age && !attrs.characteristics?.year && (
                                                                    <span className="text-gray-400">—</span>
                                                                )}
                                                            </TableCell>
                                                            <TableCell className="font-semibold text-red-600">
                                                                {new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(attrs.price)}
                                                            </TableCell>
                                                            <TableCell>
                                                                <span className={attrs.stock > 10 ? "text-green-600" : "text-orange-600"}>
                                                                    {attrs.stock} шт.
                                                                </span>
                                                            </TableCell>
                                                            <TableCell className="text-right">
                                                                {quantity > 0 ? (
                                                                    <div className="flex items-center justify-end space-x-2">
                                                                        <Button
                                                                            variant="outline"
                                                                            size="icon"
                                                                            className="h-8 w-8"
                                                                            onClick={() => updateQuantity(product.id, quantity - 1)}
                                                                        >
                                                                            <Minus className="h-3 w-3" />
                                                                        </Button>
                                                                        <span className="w-8 text-center font-medium">{quantity}</span>
                                                                        <Button
                                                                            variant="outline"
                                                                            size="icon"
                                                                            className="h-8 w-8"
                                                                            onClick={() => updateQuantity(product.id, quantity + 1)}
                                                                        >
                                                                            <Plus className="h-3 w-3" />
                                                                        </Button>
                                                                    </div>
                                                                ) : (
                                                                    <Button
                                                                        size="sm"
                                                                        onClick={() => addToCart(product)}
                                                                        className="bg-red-600 hover:bg-red-700"
                                                                    >
                                                                        <ShoppingCart className="mr-2 h-4 w-4" />
                                                                        В корзину
                                                                    </Button>
                                                                )}
                                                            </TableCell>
                                                        </TableRow>
                                                    );
                                                })
                                            ) : (
                                                <TableRow>
                                                    <TableCell colSpan={5} className="h-32 text-center text-gray-500">
                                                        Нет товаров, соответствующих выбранным фильтрам.
                                                    </TableCell>
                                                </TableRow>
                                            )}
                                        </TableBody>
                                    </Table>
                                </div>
                            </div>
                        )}
                    </Tabs>
                </>
            )}
        </div>
    );
};

export default CatalogPage;
