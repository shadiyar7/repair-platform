import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog';
import { Plus, ArrowLeft, Trash2, Edit } from 'lucide-react';
import { Label } from '@/components/ui/label';

interface ProductData {
    id: string; // JSON:API ID is string
    attributes: {
        name: string;
        sku: string;
        price: number;
        category: string;
        is_active: boolean;
        characteristics: any;
    }
}

const AdminProductsPage: React.FC = () => {
    const { id: warehouseId } = useParams();
    const navigate = useNavigate();
    const [products, setProducts] = useState<ProductData[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [warehouseName, setWarehouseName] = useState('');

    // Modal State
    const [isEditOpen, setIsEditOpen] = useState(false);
    const [editingProduct, setEditingProduct] = useState<any>(null); // null = Create Mode

    // Form State
    const [formData, setFormData] = useState({
        name: '',
        sku: '',
        price: '',
        category: '',
        is_active: true,
        characteristics_json: '{}'
    });

    useEffect(() => {
        fetchData();
    }, [warehouseId]);

    const fetchData = async () => {
        try {
            // Fetch Warehouse Name
            const whRes = await api.get(`/api/v1/admin/warehouses/${warehouseId}`);
            setWarehouseName(whRes.data.name);

            // Fetch Products
            // Note: Admin Products API supports filter by warehouse_id
            const prodRes = await api.get(`/api/v1/admin/products`, { params: { warehouse_id: warehouseId } });
            if (prodRes.data && prodRes.data.data) {
                setProducts(prodRes.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch admin data:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const openCreateModal = () => {
        setEditingProduct(null);
        setFormData({
            name: '',
            sku: '',
            price: '',
            category: 'Колесные пары', // Default
            is_active: true,
            characteristics_json: '{\n  "thickness": "30-34"\n}'
        });
        setIsEditOpen(true);
    };

    const openEditModal = (product: ProductData) => {
        setEditingProduct(product);
        setFormData({
            name: product.attributes.name,
            sku: product.attributes.sku,
            price: product.attributes.price.toString(),
            category: product.attributes.category || '',
            is_active: product.attributes.is_active,
            characteristics_json: JSON.stringify(product.attributes.characteristics || {}, null, 2)
        });
        setIsEditOpen(true);
    };

    const handleSave = async () => {
        try {
            let parsedChars = {};
            try {
                parsedChars = JSON.parse(formData.characteristics_json);
            } catch (e) {
                alert("Ошибка валидации JSON характеристик");
                return;
            }

            const payload = {
                product: {
                    name: formData.name,
                    sku: formData.sku,
                    price: parseFloat(formData.price),
                    category: formData.category,
                    is_active: formData.is_active,
                    characteristics: parsedChars
                }
            };

            if (editingProduct) {
                await api.patch(`/api/v1/admin/products/${editingProduct.id}`, payload);
            } else {
                await api.post('/api/v1/admin/products', payload);
            }

            setIsEditOpen(false);
            fetchData();
        } catch (error) {
            console.error("Save failed:", error);
            alert("Ошибка сохранения");
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm("Вы уверены, что хотите удалить товар?")) return;
        try {
            await api.delete(`/api/v1/admin/products/${id}`);
            fetchData();
        } catch (error) {
            console.error("Delete failed:", error);
            alert("Ошибка удаления");
        }
    };

    return (
        <div className="space-y-6 container mx-auto py-8">
            <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                    <Button variant="ghost" size="icon" onClick={() => navigate('/admin/warehouses')}>
                        <ArrowLeft className="h-6 w-6" />
                    </Button>
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight text-gray-900">Товары: {warehouseName}</h1>
                        <p className="text-gray-500">Управление номенклатурой склада.</p>
                    </div>
                </div>
                <Button onClick={openCreateModal} className="bg-red-600 hover:bg-red-700">
                    <Plus className="mr-2 h-4 w-4" /> Добавить товар
                </Button>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-12">
                    <span className="loading-spinner text-red-600">Загрузка...</span>
                </div>
            ) : (
                <div className="bg-white rounded-lg border shadow-sm overflow-hidden">
                    <Table>
                        <TableHeader>
                            <TableRow className="bg-gray-50/50">
                                <TableHead>1C ID (SKU)</TableHead>
                                <TableHead>Название</TableHead>
                                <TableHead>Цена</TableHead>
                                <TableHead>Статус</TableHead>
                                <TableHead className="text-right">Действия</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {products.map((product) => (
                                <TableRow key={product.id}>
                                    <TableCell className="font-mono font-medium">{product.attributes.sku}</TableCell>
                                    <TableCell>
                                        <div>{product.attributes.name}</div>
                                        <div className="text-xs text-gray-400">{product.attributes.category}</div>
                                    </TableCell>
                                    <TableCell>
                                        {new Intl.NumberFormat('kk-KZ', { style: 'currency', currency: 'KZT', maximumFractionDigits: 0 }).format(product.attributes.price)}
                                    </TableCell>
                                    <TableCell>
                                        {product.attributes.is_active ?
                                            <Badge className="bg-green-100 text-green-700 hover:bg-green-100">Активен</Badge> :
                                            <Badge variant="outline" className="text-gray-500">Скрыт</Badge>
                                        }
                                    </TableCell>
                                    <TableCell className="text-right space-x-2">
                                        <Button variant="ghost" size="icon" onClick={() => openEditModal(product)}>
                                            <Edit className="h-4 w-4 text-blue-600" />
                                        </Button>
                                        <Button variant="ghost" size="icon" onClick={() => handleDelete(product.id)}>
                                            <Trash2 className="h-4 w-4 text-red-600" />
                                        </Button>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {products.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center py-8 text-gray-500">
                                        Товары не найдены.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </div>
            )}

            {/* Create/Edit Modal */}
            <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
                <DialogContent className="max-w-xl">
                    <DialogHeader>
                        <DialogTitle>{editingProduct ? 'Редактировать товар' : 'Новый товар'}</DialogTitle>
                    </DialogHeader>
                    <div className="grid gap-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>ID из 1С (SKU)</Label>
                                <Input
                                    value={formData.sku}
                                    onChange={(e) => setFormData({ ...formData, sku: e.target.value })}
                                    placeholder="000123"
                                />
                            </div>
                            <div className="space-y-2">
                                <Label>Цена</Label>
                                <Input
                                    type="number"
                                    value={formData.price}
                                    onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                                    placeholder="50000"
                                />
                            </div>
                        </div>
                        <div className="space-y-2">
                            <Label>Название</Label>
                            <Input
                                value={formData.name}
                                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                placeholder="Колесная пара..."
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Категория</Label>
                            <Input
                                value={formData.category}
                                onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                                placeholder="Колесные пары"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label>Характеристики (JSON)</Label>
                            <textarea
                                className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                value={formData.characteristics_json}
                                onChange={(e) => setFormData({ ...formData, characteristics_json: e.target.value })}
                            />
                        </div>
                        <div className="flex items-center space-x-2">
                            <Switch
                                id="active-mode"
                                checked={formData.is_active}
                                onCheckedChange={(c) => setFormData({ ...formData, is_active: c })}
                            />
                            <Label htmlFor="active-mode">Активен (Отображать в каталоге)</Label>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsEditOpen(false)}>Отмена</Button>
                        <Button onClick={handleSave} className="bg-red-600 hover:bg-red-700">Сохранить</Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default AdminProductsPage;
