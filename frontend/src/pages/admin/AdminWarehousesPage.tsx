import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog';
import { Plus, Warehouse, ArrowRight } from 'lucide-react';
import { Label } from '@/components/ui/label';

interface WarehouseData {
    id: number;
    name: string;
    external_id_1c: number;
    address: string;
}

const AdminWarehousesPage: React.FC = () => {
    const navigate = useNavigate();
    const [warehouses, setWarehouses] = useState<WarehouseData[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isCreateOpen, setIsCreateOpen] = useState(false);

    // Form State
    const [newName, setNewName] = useState('');
    const [newId1c, setNewId1c] = useState('');
    const [newAddress, setNewAddress] = useState('');

    useEffect(() => {
        fetchWarehouses();
    }, []);

    const fetchWarehouses = async () => {
        try {
            const response = await api.get('/api/v1/admin/warehouses');
            setWarehouses(response.data);
        } catch (error) {
            console.error("Failed to fetch warehouses:", error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleCreate = async () => {
        try {
            await api.post('/api/v1/admin/warehouses', {
                warehouse: {
                    name: newName,
                    external_id_1c: parseInt(newId1c),
                    address: newAddress
                }
            });
            setIsCreateOpen(false);
            setNewName('');
            setNewId1c('');
            setNewAddress('');
            fetchWarehouses();
        } catch (error) {
            console.error("Failed to create warehouse:", error);
            alert("Ошибка при создании склада");
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
                        <div key={wh.id} className="bg-white p-6 rounded-lg border shadow-sm hover:shadow-md transition-shadow relative group">
                            <div className="flex items-center space-x-4 mb-4">
                                <div className="p-3 bg-red-50 text-red-600 rounded-full">
                                    <Warehouse className="h-6 w-6" />
                                </div>
                                <div>
                                    <h3 className="font-semibold text-lg">{wh.name}</h3>
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
        </div>
    );
};

export default AdminWarehousesPage;
