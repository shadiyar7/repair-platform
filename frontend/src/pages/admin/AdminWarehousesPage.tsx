import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog';
import { Plus, Warehouse, ArrowRight, Edit2 } from 'lucide-react';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';

interface WarehouseData {
    id: number;
    name: string;
    external_id_1c: number;
    address: string;
    display_name?: string;
    is_active?: boolean;
}

const AdminWarehousesPage: React.FC = () => {
    const navigate = useNavigate();
    const [warehouses, setWarehouses] = useState<WarehouseData[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isCreateOpen, setIsCreateOpen] = useState(false);
    const [isEditOpen, setIsEditOpen] = useState(false);
    const [editingWarehouse, setEditingWarehouse] = useState<WarehouseData | null>(null);

    // Form State (Create)
    const [newName, setNewName] = useState('');
    const [newId1c, setNewId1c] = useState('');
    const [newAddress, setNewAddress] = useState('');

    // Form State (Edit)
    const [editDisplayName, setEditDisplayName] = useState('');
    const [editIsActive, setEditIsActive] = useState(true);

    useEffect(() => {
        fetchWarehouses();
    }, []);

    const fetchWarehouses = async () => {
        try {
            const response = await api.get('/api/v1/admin/warehouses');
            setWarehouses(Array.isArray(response.data) ? response.data : []);
        } catch (error) {
            console.error("Failed to fetch warehouses:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleCreate = async () => {
        try {
            const externalId = parseInt(newId1c);
            if (isNaN(externalId)) {
                alert("ID из 1С должен быть числом");
                return;
            }
            if (!newName || !newAddress) {
                alert("Заполните все поля");
                return;
            }

            await api.post('/api/v1/admin/warehouses', {
                warehouse: {
                    name: newName,
                    external_id_1c: externalId,
                    address: newAddress
                }
            });
            setIsCreateOpen(false);
            setNewName('');
            setNewId1c('');
            setNewAddress('');
            fetchWarehouses();
        } catch (error: any) {
            console.error("Failed to create warehouse:", error);
            // Show backend errors if available
            const errorMsg = error.response?.data?.errors
                ? JSON.stringify(error.response.data.errors)
                : "Ошибка при создании склада";
            alert(errorMsg);
        }
    };

    const openEditModal = (wh: WarehouseData) => {
        setEditingWarehouse(wh);
        setEditDisplayName(wh.display_name || '');
        setEditIsActive(wh.is_active ?? true);
        setIsEditOpen(true);
    };

    const handleEditSave = async () => {
        if (!editingWarehouse) return;
        try {
            await api.patch(`/api/v1/admin/warehouses/${editingWarehouse.id}`, {
                warehouse: {
                    display_name: editDisplayName,
                    is_active: editIsActive
                }
            });
            setIsEditOpen(false);
            setEditingWarehouse(null);
            fetchWarehouses();
        } catch (error: any) {
            console.error("Failed to update warehouse:", error);
            alert("Ошибка при сохранении склада");
        }
    };

    return (
        <div className="space-y-6 container mx-auto py-8">
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight text-gray-900">Склады</h1>
                    <p className="text-gray-500">Выберите склад для управления товарами или создайте новый.</p>
                </div>
                <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
                    <DialogTrigger asChild>
                        <Button className="bg-red-600 hover:bg-red-700">
                            <Plus className="mr-2 h-4 w-4" /> Добавить склад
                        </Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogHeader>
                            <DialogTitle>Новый склад</DialogTitle>
                        </DialogHeader>
                        <div className="space-y-4 py-4">
                            <div className="space-y-2">
                                <Label>Название склада</Label>
                                <Input value={newName} onChange={(e) => setNewName(e.target.value)} placeholder="Например: Атырау Главный" />
                            </div>
                            <div className="space-y-2">
                                <Label>ID из 1С</Label>
                                <Input type="number" value={newId1c} onChange={(e) => setNewId1c(e.target.value)} placeholder="1" />
                            </div>
                            <div className="space-y-2">
                                <Label>Адрес</Label>
                                <Input value={newAddress} onChange={(e) => setNewAddress(e.target.value)} placeholder="ул. Ленина 1" />
                            </div>
                        </div>
                        <DialogFooter>
                            <Button variant="outline" onClick={() => setIsCreateOpen(false)}>Отмена</Button>
                            <Button onClick={handleCreate} className="bg-red-600 hover:bg-red-700">Создать</Button>
                        </DialogFooter>
                    </DialogContent>
                </Dialog>
            </div>

            {isLoading ? (
                <div className="flex justify-center p-12">
                    <span className="loading-spinner text-red-600">Загрузка...</span>
                </div>
            ) : (
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                    {warehouses.map((wh) => (
                        <div key={wh.id} className={`bg-white p-6 rounded-lg border shadow-sm hover:shadow-md transition-shadow relative group ${wh.is_active === false ? 'opacity-70 bg-gray-50' : ''}`}>
                            <div className="absolute top-4 right-4 flex items-center space-x-2">
                                {wh.is_active === false && (
                                    <Badge variant="secondary" className="bg-gray-200 text-gray-700">Скрыт</Badge>
                                )}
                                <Button
                                    variant="ghost"
                                    size="icon"
                                    className="h-8 w-8 text-gray-400 hover:text-red-600"
                                    onClick={() => openEditModal(wh)}
                                >
                                    <Edit2 className="h-4 w-4" />
                                </Button>
                            </div>
                            <div className="flex items-center space-x-4 mb-4">
                                <div className={`p-3 rounded-full ${wh.is_active === false ? 'bg-gray-100 text-gray-500' : 'bg-red-50 text-red-600'}`}>
                                    <Warehouse className="h-6 w-6" />
                                </div>
                                <div>
                                    <h3 className="font-semibold text-lg">{wh.display_name || wh.name}</h3>
                                    {wh.display_name && (
                                        <p className="text-xs text-gray-400">В 1С: {wh.name}</p>
                                    )}
                                    <p className="text-sm text-gray-500">ID 1C: {wh.external_id_1c}</p>
                                </div>
                            </div>
                            <div className="text-sm text-gray-600 mb-6">
                                {wh.address || 'Адрес не указан'}
                            </div>
                            <Button
                                className="w-full"
                                variant="secondary"
                                onClick={() => navigate(`/admin/warehouses/${wh.id}`)}
                            >
                                Управление товарами <ArrowRight className="ml-2 h-4 w-4" />
                            </Button>
                        </div>
                    ))}

                    {warehouses.length === 0 && (
                        <div className="col-span-full text-center py-12 text-gray-500 border-2 border-dashed rounded-lg">
                            Складов пока нет. Создайте первый склад.
                        </div>
                    )}
                </div>
            )}

            {/* Edit Modal */}
            <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Настройки склада: {editingWarehouse?.name}</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-6 py-4">
                        <div className="space-y-4 bg-gray-50 p-4 rounded border">
                            <div className="flex items-center justify-between">
                                <div className="space-y-1">
                                    <Label className="text-base">Показывать в каталоге</Label>
                                    <p className="text-xs text-gray-500">Если выключено, склад скроется с витрины для клиентов.</p>
                                </div>
                                <Switch
                                    checked={editIsActive}
                                    onCheckedChange={setEditIsActive}
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label>Название на витрине (публичное)</Label>
                            <Input
                                value={editDisplayName}
                                onChange={(e) => setEditDisplayName(e.target.value)}
                                placeholder="Оставьте пустым для использования имени из 1С"
                            />
                            <p className="text-xs text-gray-500">
                                Название из 1С: <span className="font-mono bg-gray-100 px-1">{editingWarehouse?.name}</span>
                            </p>
                        </div>
                    </div>
                    <DialogFooter>
                        <Button variant="outline" onClick={() => setIsEditOpen(false)}>Отмена</Button>
                        <Button onClick={handleEditSave} className="bg-red-600 hover:bg-red-700">Сохранить</Button>
                    </DialogFooter>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default AdminWarehousesPage;
