import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from "@/components/ui/dialog";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Badge } from '@/components/ui/badge';
import { Plus, Pencil, Trash2, Shield, Truck, Warehouse } from 'lucide-react';

interface User {
    id: number;
    email: string;
    phone: string;
    role: string;
    job_title: string;
    created_at: string;
}

const AdminUserManagementPage: React.FC = () => {
    const queryClient = useQueryClient();
    const [isCreateOpen, setIsCreateOpen] = useState(false);
    const [isEditOpen, setIsEditOpen] = useState(false);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);

    const [formData, setFormData] = useState({
        email: '',
        password: '',
        phone: '',
        role: 'warehouse',
        job_title: ''
    });

    const { data: usersData, isLoading } = useQuery({
        queryKey: ['admin', 'users'],
        queryFn: async () => {
            const res = await api.get('/api/v1/admin/users');
            return res.data;
        }
    });

    const createMutation = useMutation({
        mutationFn: (data: any) => api.post('/api/v1/admin/users', { user: data }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
            setIsCreateOpen(false);
            setFormData({ email: '', password: '', phone: '', role: 'warehouse', job_title: '' });
            alert('Пользователь создан');
        },
        onError: (err: any) => {
            alert('Ошибка создания: ' + (err.response?.data?.errors?.join(', ') || 'Проверьте данные'));
        }
    });

    const updateMutation = useMutation({
        mutationFn: (data: any) => api.put(`/api/v1/admin/users/${selectedUser?.id}`, { user: data }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
            setIsEditOpen(false);
            alert('Пользователь обновлен');
        },
        onError: (err: any) => {
            alert('Ошибка обновления: ' + err.response?.data?.errors?.join(', '));
        }
    });

    const deleteMutation = useMutation({
        mutationFn: (id: number) => api.delete(`/api/v1/admin/users/${id}`),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
            alert('Пользователь удален');
        }
    });

    const roles = [
        { value: 'admin', label: 'Администратор' },
        { value: 'director', label: 'Директор' },
        { value: 'supervisor', label: 'Супервайзер' },
        { value: 'warehouse', label: 'Менеджер склада' },
        { value: 'driver', label: 'Водитель' },
    ];

    const getRoleBadge = (role: string) => {
        switch (role) {
            case 'admin': return <Badge className="bg-red-100 text-red-800 hover:bg-red-100"><Shield className="w-3 h-3 mr-1" /> Админ</Badge>;
            case 'director': return <Badge className="bg-purple-100 text-purple-800 hover:bg-purple-100">Директор</Badge>;
            case 'warehouse': return <Badge className="bg-blue-100 text-blue-800 hover:bg-blue-100"><Warehouse className="w-3 h-3 mr-1" /> Склад</Badge>;
            case 'driver': return <Badge className="bg-green-100 text-green-800 hover:bg-green-100"><Truck className="w-3 h-3 mr-1" /> Водитель</Badge>;
            default: return <Badge variant="outline">{role}</Badge>;
        }
    };

    const handleCreate = () => {
        if (!formData.email || !formData.password || !formData.role) {
            alert('Заполните обязательные поля');
            return;
        }
        createMutation.mutate(formData);
    };

    const handleUpdate = () => {
        updateMutation.mutate({
            email: formData.email,
            phone: formData.phone,
            role: formData.role,
            job_title: formData.job_title,
            // Only send password if changed (not implementing password change here for simplicity yet, or handled by API if present)
            ...(formData.password ? { password: formData.password } : {})
        });
    };

    const openEdit = (user: User) => {
        setSelectedUser(user);
        setFormData({
            email: user.email,
            password: '', // Don't show password
            phone: user.phone || '',
            role: user.role,
            job_title: user.job_title || ''
        });
        setIsEditOpen(true);
    };

    const users = usersData?.data || [];

    return (
        <div className="container mx-auto py-10">
            <div className="flex justify-between items-center mb-6">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Сотрудники</h1>
                    <p className="text-muted-foreground">Управление доступом персонала (Админы, Склад, Водители)</p>
                </div>
                <Dialog open={isCreateOpen} onOpenChange={setIsCreateOpen}>
                    <DialogTrigger asChild>
                        <Button className="bg-red-600 hover:bg-red-700">
                            <Plus className="mr-2 h-4 w-4" /> Добавить сотрудника
                        </Button>
                    </DialogTrigger>
                    <DialogContent>
                        <DialogHeader>
                            <DialogTitle>Новый сотрудник</DialogTitle>
                            <DialogDescription>
                                Создайте учетную запись для персонала. Пользователь сможет войти через /admin/login.
                            </DialogDescription>
                        </DialogHeader>
                        <div className="grid gap-4 py-4">
                            <div className="grid gap-2">
                                <Label htmlFor="email">Email (Логин) *</Label>
                                <Input id="email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} placeholder="employee@dynamix.kz" />
                            </div>
                            <div className="grid gap-2">
                                <Label htmlFor="password">Пароль *</Label>
                                <Input id="password" type="password" value={formData.password} onChange={(e) => setFormData({ ...formData, password: e.target.value })} placeholder="Временный пароль" />
                            </div>
                            <div className="grid gap-2">
                                <Label htmlFor="role">Роль *</Label>
                                <Select value={formData.role} onValueChange={(val) => setFormData({ ...formData, role: val })}>
                                    <SelectTrigger>
                                        <SelectValue placeholder="Выберите роль" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        {roles.map(role => (
                                            <SelectItem key={role.value} value={role.value}>{role.label}</SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
                            <div className="grid gap-2">
                                <Label htmlFor="job_title">Должность</Label>
                                <Input id="job_title" value={formData.job_title} onChange={(e) => setFormData({ ...formData, job_title: e.target.value })} placeholder="Например: Старший кладовщик" />
                            </div>
                            <div className="grid gap-2">
                                <Label htmlFor="phone">Телефон</Label>
                                <Input id="phone" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} placeholder="+7..." />
                            </div>
                        </div>
                        <Button onClick={handleCreate} disabled={createMutation.isPending} className="w-full bg-red-600">
                            {createMutation.isPending ? 'Создание...' : 'Создать сотрудника'}
                        </Button>
                    </DialogContent>
                </Dialog>
            </div>

            <div className="border rounded-md">
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Email</TableHead>
                            <TableHead>Роль</TableHead>
                            <TableHead>Должность</TableHead>
                            <TableHead>Телефон</TableHead>
                            <TableHead className="text-right">Действия</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {isLoading ? (
                            <TableRow>
                                <TableCell colSpan={5} className="h-24 text-center">Загрузка...</TableCell>
                            </TableRow>
                        ) : users.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} className="h-24 text-center">Сотрудники не найдены</TableCell>
                            </TableRow>
                        ) : (
                            users.map((user: any) => (
                                <TableRow key={user.id}>
                                    <TableCell className="font-medium">{user.attributes.email}</TableCell>
                                    <TableCell>{getRoleBadge(user.attributes.role)}</TableCell>
                                    <TableCell>{user.attributes.job_title || '-'}</TableCell>
                                    <TableCell>{user.attributes.phone || '-'}</TableCell>
                                    <TableCell className="text-right flex justify-end gap-2">
                                        <Button variant="ghost" size="icon" onClick={() => openEdit(user.attributes)}>
                                            <Pencil className="h-4 w-4" />
                                        </Button>
                                        <Button variant="ghost" size="icon" className="text-red-500 hover:text-red-700 hover:bg-red-50" onClick={() => {
                                            if (confirm('Вы уверены? Это действие нельзя отменить.')) {
                                                deleteMutation.mutate(user.id);
                                            }
                                        }}>
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </div>

            {/* Edit Modal */}
            <Dialog open={isEditOpen} onOpenChange={setIsEditOpen}>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Редактирование сотрудника</DialogTitle>
                    </DialogHeader>
                    <div className="grid gap-4 py-4">
                        <div className="grid gap-2">
                            <Label htmlFor="edit-email">Email (Логин)</Label>
                            <Input id="edit-email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} />
                        </div>
                        <div className="grid gap-2">
                            {/* Optional Password Update */}
                            <Label htmlFor="edit-password">Новый пароль (Оставьте пустым, если не меняете)</Label>
                            <Input id="edit-password" type="password" value={formData.password} onChange={(e) => setFormData({ ...formData, password: e.target.value })} placeholder="******" />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="edit-role">Роль</Label>
                            <Select value={formData.role} onValueChange={(val) => setFormData({ ...formData, role: val })}>
                                <SelectTrigger>
                                    <SelectValue placeholder="Выберите роль" />
                                </SelectTrigger>
                                <SelectContent>
                                    {roles.map(role => (
                                        <SelectItem key={role.value} value={role.value}>{role.label}</SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="edit-job">Должность</Label>
                            <Input id="edit-job" value={formData.job_title} onChange={(e) => setFormData({ ...formData, job_title: e.target.value })} />
                        </div>
                        <div className="grid gap-2">
                            <Label htmlFor="edit-phone">Телефон</Label>
                            <Input id="edit-phone" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} />
                        </div>
                    </div>
                    <Button onClick={handleUpdate} disabled={updateMutation.isPending} className="w-full">
                        {updateMutation.isPending ? 'Сохранение...' : 'Сохранить изменения'}
                    </Button>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default AdminUserManagementPage;
