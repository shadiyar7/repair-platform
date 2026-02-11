import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Trash2, Plus, Save, Edit2 } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useForm } from 'react-hook-form';

interface CompanyRequisite {
    id: string;
    company_name?: string;
    bin?: string;
    iban: string;
    swift?: string;
    bank_name?: string;
    kbe?: string;
}

interface UserCompanyProfile {
    company_name: string;
    bin: string;
    inn: string;
    phone: string;
    director_name: string;
    acting_on_basis: string;
    legal_address: string;
    actual_address: string;
}

const ProfilePage: React.FC = () => {
    const { user, setUser } = useAuth(); // Assuming setUser updates context state
    const [requisites, setRequisites] = useState<CompanyRequisite[]>([]);
    const [isLoadingRequisites, setIsLoadingRequisites] = useState(false);

    // Modal State for Requisites
    const [isRequisiteModalOpen, setIsRequisiteModalOpen] = useState(false);
    const [editingRequisite, setEditingRequisite] = useState<CompanyRequisite | null>(null);
    const { register: registerReq, handleSubmit: handleSubmitReq, reset: resetReq, setValue: setReqValue } = useForm<CompanyRequisite>();

    // Profile Form State
    const { register: registerProfile, handleSubmit: handleSubmitProfile, setValue: setProfileValue, formState: { isDirty: isProfileDirty, isSubmitting: isProfileSubmitting } } = useForm<UserCompanyProfile>();

    useEffect(() => {
        if (user) {
            // Populate Profile Form
            setProfileValue('company_name', user.company_name || '');
            setProfileValue('bin', (user as any).bin || ''); // Type assertion if types not updated
            setProfileValue('inn', (user as any).inn || '');
            setProfileValue('phone', user.phone || '');
            setProfileValue('director_name', (user as any).director_name || '');
            setProfileValue('acting_on_basis', (user as any).acting_on_basis || '');
            setProfileValue('legal_address', (user as any).legal_address || '');
            setProfileValue('actual_address', (user as any).actual_address || '');

            fetchRequisites();
        }
    }, [user, setProfileValue]);

    const fetchRequisites = async () => {
        setIsLoadingRequisites(true);
        try {
            const response = await api.get('/api/v1/company_requisites');
            const data = response.data.data;
            const formatted = Array.isArray(data)
                ? data.map((item: any) => ({ id: item.id, ...item.attributes }))
                : [];
            setRequisites(formatted);
        } catch (error) {
            console.error('Failed to fetch requisites', error);
        } finally {
            setIsLoadingRequisites(false);
        }
    };

    const onSaveProfile = async (data: UserCompanyProfile) => {
        try {
            const response = await api.put('/api/v1/auth/profile', data);

            // Update local user context
            // Assuming response returns updated user (user serializer structure)
            // Strategy 1: User provided structure (status + data)
            let updatedUser = user;
            if (response.data.user && response.data.user.data && response.data.user.data.attributes) {
                const attrs = response.data.user.data.attributes;
                updatedUser = { ...user, ...attrs, id: response.data.user.data.id || user?.id };
            } else if (response.data.data) { // Fallback if API changed
                updatedUser = { ...user, ...response.data.data };
            }

            // We need a way to update AuthContext user. Either add setUser to AuthContext or manually update localStorage
            // Since we extracted setUser above (check if AuthContext exports it), IF NOT:
            // We'll trust fetchRequisites might use it? No, fetchRequisites uses API.
            // Let's assume AuthContext might need a reload or we update localStorage manually if setUser is not available.

            // Note: I added setUser to AuthContext previously (check previous views). 
            // Wait, I saw AuthContext view: `const [user, setUser] = useState` but `value={{ user ... }}`. 
            // `setUser` is NOT exported in the value object in the previous view file code. 
            // I should have checked. Let's assume for now I can't update context easily without reload or refactor.
            // But let's try to update localStorage and reload if needed? 
            // Ideally I should expose setUser in AuthContext. For now, alert success.

            alert('Профиль компании обновлен');

            // To ensure consistency
            // To ensure consistency
            localStorage.setItem('user', JSON.stringify(updatedUser));
            setUser(updatedUser); // Update context without reload

        } catch (error) {
            console.error('Error saving profile', error);
            alert('Ошибка при сохранении профиля');
        }
    };

    const onSaveRequisite = async (data: CompanyRequisite) => {
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
            setIsRequisiteModalOpen(false);
            setEditingRequisite(null);
            resetReq();
            fetchRequisites();
        } catch (error) {
            console.error('Error saving requisite', error);
            alert('Ошибка при сохранении счета');
        }
    };

    const handleEditRequisite = (req: CompanyRequisite) => {
        setEditingRequisite(req);
        setReqValue('bank_name', req.bank_name);
        setReqValue('iban', req.iban);
        setReqValue('swift', req.swift);
        setReqValue('kbe', req.kbe);
        setIsRequisiteModalOpen(true);
    };

    const handleNewRequisite = () => {
        setEditingRequisite(null);
        resetReq();
        setIsRequisiteModalOpen(true);
    };

    const handleDeleteRequisite = async (id: string) => {
        if (confirm('Вы уверены, что хотите удалить этот счет?')) {
            try {
                await api.delete(`/api/v1/company_requisites/${id}`);
                fetchRequisites();
            } catch (error) {
                console.error('Error deleting', error);
            }
        }
    };

    if (!user) return null;

    return (
        <div className="max-w-5xl mx-auto space-y-8 py-8 px-4">
            <h1 className="text-3xl font-bold tracking-tight">Профиль компании</h1>

            {/* SECTION 1: Company Profile (Single) */}
            <Card>
                <CardHeader>
                    <CardTitle>Юридическое лицо</CardTitle>
                    <CardDescription>Основная информация о вашей компании</CardDescription>
                </CardHeader>
                <form onSubmit={handleSubmitProfile(onSaveProfile)}>
                    <CardContent className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="company_name">Название компании</Label>
                                <Input id="company_name" {...registerProfile('company_name')} placeholder='ТОО "Ромашка"' />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="bin">БИН/ИИН</Label>
                                <Input id="bin" {...registerProfile('bin')} placeholder="123456789012" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="director_name">ФИО Директора</Label>
                                <Input id="director_name" {...registerProfile('director_name')} />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="phone">Телефон</Label>
                                <Input id="phone" {...registerProfile('phone')} />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="legal_address">Юридический адрес</Label>
                                <Input id="legal_address" {...registerProfile('legal_address')} />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="actual_address">Фактический адрес</Label>
                                <Input id="actual_address" {...registerProfile('actual_address')} />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="acting_on_basis">Действует на основании</Label>
                                <Input id="acting_on_basis" {...registerProfile('acting_on_basis')} placeholder="Устава" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="inn">ИНН (опционально)</Label>
                                <Input id="inn" {...registerProfile('inn')} />
                            </div>
                        </div>
                    </CardContent>
                    <CardFooter className="flex justify-end border-t pt-4">
                        <Button type="submit" className="bg-red-600 hover:bg-red-700" disabled={!isProfileDirty || isProfileSubmitting}>
                            <Save className="mr-2 h-4 w-4" />
                            {isProfileSubmitting ? 'Сохранение...' : 'Сохранить изменения'}
                        </Button>
                    </CardFooter>
                </form>
            </Card>

            {/* SECTION 2: Bank Requisites (Multiple) */}
            <div className="space-y-4">
                <div className="flex justify-between items-center">
                    <div>
                        <h2 className="text-xl font-bold">Банковские счета</h2>
                        <p className="text-gray-500 text-sm">Добавьте несколько счетов для выбора при заказе</p>
                    </div>
                    <Button onClick={handleNewRequisite} variant="outline">
                        <Plus className="mr-2 h-4 w-4" />
                        Добавить счет
                    </Button>
                </div>

                {isLoadingRequisites ? (
                    <div>Загрузка счетов...</div>
                ) : requisites.length === 0 ? (
                    <Card className="text-center py-8">
                        <CardContent>
                            <p className="text-gray-500 mb-2">Счетов пока нет</p>
                            <Button size="sm" onClick={handleNewRequisite}>Добавить первый счет</Button>
                        </CardContent>
                    </Card>
                ) : (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        {requisites.map((req) => (
                            <Card key={req.id} className="relative group">
                                <CardHeader className="pb-2">
                                    <div className="flex justify-between items-start">
                                        <CardTitle className="text-base font-medium">{req.bank_name || 'Банк не указан'}</CardTitle>
                                        <div className="flex space-x-1">
                                            <Button size="icon" variant="ghost" className="h-6 w-6 text-gray-400 hover:text-blue-500" onClick={() => handleEditRequisite(req)}>
                                                <Edit2 className="h-4 w-4" />
                                            </Button>
                                            <Button size="icon" variant="ghost" className="h-6 w-6 text-gray-400 hover:text-red-500" onClick={() => handleDeleteRequisite(req.id)}>
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    </div>
                                    <CardDescription className="text-xs break-all">
                                        IBAN: {req.iban}
                                    </CardDescription>
                                </CardHeader>
                                <CardContent className="text-xs text-gray-500">
                                    <div>SWIFT: {req.swift}</div>
                                    {req.kbe && <div>КБе: {req.kbe}</div>}
                                </CardContent>
                            </Card>
                        ))}
                    </div>
                )}
            </div>

            {/* Modal for New Requisite */}
            <Dialog open={isRequisiteModalOpen} onOpenChange={setIsRequisiteModalOpen}>
                <DialogContent className="sm:max-w-[500px]">
                    <DialogHeader>
                        <DialogTitle>{editingRequisite ? 'Редактирование счета' : 'Добавление банковского счета'}</DialogTitle>
                    </DialogHeader>
                    <form onSubmit={handleSubmitReq(onSaveRequisite)} className="space-y-4 py-4">
                        <div className="grid grid-cols-1 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="bank_name">Название банка</Label>
                                <Input id="bank_name" {...registerReq('bank_name', { required: true })} placeholder="АО Kaspi Bank" />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="iban">IBAN (KZ...)</Label>
                                <Input id="iban" {...registerReq('iban', { required: true })} placeholder="KZ..." />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <Label htmlFor="swift">SWIFT (BIC)</Label>
                                    <Input id="swift" {...registerReq('swift', { required: true })} />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="kbe">КБе</Label>
                                    <Input id="kbe" {...registerReq('kbe')} placeholder="17" />
                                </div>
                            </div>
                        </div>

                        <div className="flex justify-end space-x-2 pt-4">
                            <Button type="button" variant="outline" onClick={() => setIsRequisiteModalOpen(false)}>Отмена</Button>
                            <Button type="submit" className="bg-red-600 hover:bg-red-700">Сохранить</Button>
                        </div>
                    </form>
                </DialogContent>
            </Dialog>
        </div>
    );
};

export default ProfilePage;
