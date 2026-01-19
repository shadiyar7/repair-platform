import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Building, MapPin, CreditCard, Plus, Edit2, Trash2, Landmark, User as UserIcon } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useForm } from 'react-hook-form';

interface CompanyRequisite {
    id: string;
    company_name: string;
    bin: string;
    legal_address: string;
    actual_address: string;
    director_name: string;
    acting_on_basis: string;
    iban: string;
    swift: string;
    bank_name?: string;
    kbe?: string;
    phone?: string;
    email?: string;
}

const ProfilePage: React.FC = () => {
    const { user } = useAuth();
    const [requisites, setRequisites] = useState<CompanyRequisite[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingRequisite, setEditingRequisite] = useState<CompanyRequisite | null>(null);

    const { register, handleSubmit, reset, setValue, formState: { errors } } = useForm<CompanyRequisite>();

    const fetchRequisites = async () => {
        try {
            const response = await api.get('/api/v1/company_requisites');
            // Check if JSONAPI format or flat
            const data = response.data.data;
            const formatted = Array.isArray(data)
                ? data.map((item: any) => ({ id: item.id, ...item.attributes }))
                : [];
            setRequisites(formatted);
        } catch (error) {
            console.error('Failed to fetch requisites', error);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        if (user) {
            fetchRequisites();
        }
    }, [user]);

    const onSubmit = async (data: CompanyRequisite) => {
        try {
            if (editingRequisite) {
                await api.put(`/api/v1/company_requisites/${editingRequisite.id}`, {
                    company_requisite: data
                });
            } else {
                await api.post('/api/v1/company_requisites', {
                    company_requisite: data
                });
            }
            setIsModalOpen(false);
            setEditingRequisite(null);
            reset();
            fetchRequisites();
        } catch (error) {
            console.error('Error saving requisite', error);
            alert('Ошибка при сохранении реквизитов. Проверьте данные и попробуйте снова.');
        }
    };

    const handleEdit = (req: CompanyRequisite) => {
        setEditingRequisite(req);
        // Set form values
        Object.keys(req).forEach((key) => {
            setValue(key as keyof CompanyRequisite, req[key as keyof CompanyRequisite]);
        });
        setIsModalOpen(true);
    };

    const handleDelete = async (id: string) => {
        if (confirm('Вы уверены, что хотите удалить эти реквизиты?')) {
            try {
                await api.delete(`/api/v1/company_requisites/${id}`);
                fetchRequisites();
            } catch (error) {
                console.error('Error deleting', error);
            }
        }
    };

    const handleNew = () => {
        setEditingRequisite(null);
        reset();
        setIsModalOpen(true);
    };

    if (!user) return null;

    return (
        <div className="max-w-5xl mx-auto space-y-8 py-8">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-bold tracking-tight">Профиль компании</h1>
                    <p className="text-muted-foreground mt-1">Управление юридическими лицами и реквизитами</p>
                </div>
                <Button onClick={handleNew} className="bg-red-600 hover:bg-red-700">
                    <Plus className="mr-2 h-4 w-4" />
                    Добавить компанию
                </Button>
            </div>

            {isLoading ? (
                <div>Загрузка...</div>
            ) : requisites.length === 0 ? (
                <Card className="text-center py-12">
                    <CardContent>
                        <Building className="mx-auto h-12 w-12 text-gray-300 mb-4" />
                        <h3 className="text-lg font-medium">Нет добавленных компаний</h3>
                        <p className="text-gray-500 mb-4">Добавьте реквизиты вашей компании для оформления заказов и выставления счетов.</p>
                        <Button onClick={handleNew} variant="outline">Добавить реквизиты</Button>
                    </CardContent>
                </Card>
            ) : (
                <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-2">
                    {requisites.map((req) => (
                        <Card key={req.id} className="relative group">
                            <CardHeader className="pb-3">
                                <CardTitle className="flex items-center justify-between">
                                    <span className="truncate" title={req.company_name}>{req.company_name}</span>
                                    <div className="flex space-x-2">
                                        <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => handleEdit(req)}>
                                            <Edit2 className="h-4 w-4" />
                                        </Button>
                                        <Button size="icon" variant="ghost" className="h-8 w-8 text-red-500 hover:text-red-700" onClick={() => handleDelete(req.id)}>
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </CardTitle>
                                <CardDescription>БИН: {req.bin}</CardDescription>
                            </CardHeader>
                            <CardContent className="text-sm space-y-3">
                                <div className="flex items-start">
                                    <MapPin className="mr-2 h-4 w-4 text-gray-400 mt-0.5 shrink-0" />
                                    <span>
                                        <div className="font-medium text-xs text-gray-500">Юридический адрес</div>
                                        {req.legal_address}
                                    </span>
                                </div>
                                <div className="flex items-start">
                                    <UserIcon className="mr-2 h-4 w-4 text-gray-400 mt-0.5 shrink-0" />
                                    <span>
                                        <div className="font-medium text-xs text-gray-500">Директор</div>
                                        {req.director_name} ({req.acting_on_basis})
                                    </span>
                                </div>
                                <div className="pt-2 border-t mt-2">
                                    <div className="flex items-start">
                                        <Landmark className="mr-2 h-4 w-4 text-gray-400 mt-0.5 shrink-0" />
                                        <span>
                                            <div className="font-medium text-xs text-gray-500">Банк</div>
                                            {req.bank_name || 'Не указан'}
                                        </span>
                                    </div>
                                    <div className="flex items-start mt-2">
                                        <CreditCard className="mr-2 h-4 w-4 text-gray-400 mt-0.5 shrink-0" />
                                        <span className="break-all">
                                            <div className="font-medium text-xs text-gray-500">IBAN</div>
                                            {req.iban}
                                        </span>
                                    </div>
                                </div>
                            </CardContent>
                        </Card>
                    ))}
                </div>
            )}

            <Dialog open={isModalOpen} onOpenChange={setIsModalOpen}>
                <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle>{editingRequisite ? 'Редактировать компанию' : 'Новая компания'}</DialogTitle>
                    </DialogHeader>
                    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 py-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="col-span-2">
                                <Label htmlFor="company_name">Название компании (ТОО/ИП)</Label>
                                <Input id="company_name" {...register('company_name', { required: "Введите название компании" })} placeholder='ТОО "Ромашка"' />
                                {errors.company_name && <span className="text-xs text-red-500">{errors.company_name.message}</span>}
                            </div>
                            <div>
                                <Label htmlFor="bin">БИН/ИИН</Label>
                                <Input id="bin" {...register('bin', {
                                    required: "Введите БИН/ИИН",
                                    minLength: { value: 12, message: "12 цифр" },
                                    maxLength: { value: 12, message: "12 цифр" }
                                })} placeholder="123456789012" />
                                {errors.bin && <span className="text-xs text-red-500">{errors.bin.message}</span>}
                            </div>

                            <div className="col-span-2">
                                <Label htmlFor="legal_address">Юридический адрес</Label>
                                <Input id="legal_address" {...register('legal_address', { required: "Введите юридический адрес" })} />
                                {errors.legal_address && <span className="text-xs text-red-500">{errors.legal_address.message}</span>}
                            </div>
                            <div className="col-span-2">
                                <Label htmlFor="actual_address">Фактический адрес</Label>
                                <Input id="actual_address" {...register('actual_address', { required: "Введите фактический адрес" })} />
                                {errors.actual_address && <span className="text-xs text-red-500">{errors.actual_address.message}</span>}
                            </div>
                            <div>
                                <Label htmlFor="director_name">ФИО Директора</Label>
                                <Input id="director_name" {...register('director_name', { required: "Введите ФИО директора" })} />
                                {errors.director_name && <span className="text-xs text-red-500">{errors.director_name.message}</span>}
                            </div>
                            <div>
                                <Label htmlFor="acting_on_basis">Действует на основании</Label>
                                <Input id="acting_on_basis" {...register('acting_on_basis')} placeholder="Устава" />
                            </div>
                        </div>

                        <div className="border-t pt-4">
                            <h4 className="text-sm font-medium mb-3">Банковские реквизиты</h4>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="col-span-2">
                                    <Label htmlFor="bank_name">Название банка</Label>
                                    <Input id="bank_name" {...register('bank_name')} placeholder="АО Kaspi Bank" />
                                </div>
                                <div className="col-span-2">
                                    <Label htmlFor="iban">IBAN (KZ...)</Label>
                                    <Input id="iban" {...register('iban', { required: "Введите IBAN" })} placeholder="KZ..." />
                                    {errors.iban && <span className="text-xs text-red-500">{errors.iban.message}</span>}
                                </div>
                                <div>
                                    <Label htmlFor="swift">SWIFT (BIC)</Label>
                                    <Input id="swift" {...register('swift')} />
                                </div>
                                <div>
                                    <Label htmlFor="kbe">КБе</Label>
                                    <Input id="kbe" {...register('kbe')} placeholder="17" />
                                </div>
                            </div>
                        </div>

                        <div className="flex justify-end space-x-2 pt-4">
                            <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)}>Отмена</Button>
                            <Button type="submit" className="bg-red-600 hover:bg-red-700">Сохранить</Button>
                        </div>
                    </form>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default ProfilePage;
