import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import api from '@/lib/api';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

const RegisterPage: React.FC = () => {
    const [formData, setFormData] = useState({
        email: '',
        password: '',
        password_confirmation: '',
        company_name: '',
        inn: '',
        phone: '',
        director_name: '',
        acting_on_basis: '',
        legal_address: '',
        actual_address: '',
        bin: '',
        iban: '',
        swift: '',
        role: 'client' as 'client' | 'admin' | 'warehouse' | 'driver'
    });
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        setFormData({ ...formData, [e.target.id]: e.target.value });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        if (formData.password !== formData.password_confirmation) {
            setError('Пароли не совпадают');
            setIsLoading(false);
            return;
        }

        try {
            const response = await api.post('/signup', {
                user: formData
            });

            const token = response.headers.authorization?.split(' ')[1];
            if (token) {
                login(token, response.data.data);
                navigate('/');
            } else {
                setError('Регистрация прошла успешно, но вход не удался. Пожалуйста, войдите вручную.');
                navigate('/login');
            }
        } catch (err: any) {
            setError(err.response?.data?.status?.message || 'Ошибка регистрации. Пожалуйста, проверьте введенные данные.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex items-center justify-center min-h-[80vh] py-12">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle>Создание аккаунта</CardTitle>
                    <CardDescription>Зарегистрируйте вашу компанию на платформе DYNAMIX</CardDescription>
                </CardHeader>
                <form onSubmit={handleSubmit}>
                    <CardContent className="space-y-4">
                        {error && <div className="p-3 text-sm text-red-500 bg-red-50 rounded-md">{error}</div>}

                        <div className="space-y-2">
                            <Label htmlFor="role">Я являюсь...</Label>
                            <select
                                id="role"
                                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                                value={formData.role}
                                onChange={(e) => setFormData({ ...formData, role: e.target.value as any })}
                            >
                                <option value="client">Клиент (Ремонтное депо / Логистика)</option>
                                <option value="warehouse">Менеджер склада</option>
                                <option value="driver">Водитель</option>
                            </select>
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="company_name">Название компании</Label>
                            <Input id="company_name" placeholder="ТОО Логистик Про" value={formData.company_name} onChange={handleChange} required />
                        </div>

                        {formData.role === 'client' && (
                            <>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="bin">БИН</Label>
                                        <Input id="bin" placeholder="123456789012" value={formData.bin} onChange={handleChange} required />
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="director_name">ФИО Директора</Label>
                                        <Input id="director_name" placeholder="Иван Иванов" value={formData.director_name} onChange={handleChange} required />
                                    </div>
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="acting_on_basis">Действует на основании</Label>
                                    <Input id="acting_on_basis" placeholder="Устава / Доверенности" value={formData.acting_on_basis} onChange={handleChange} required />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="legal_address">Юридический адрес</Label>
                                    <Input id="legal_address" placeholder="Алматы, Достык 100" value={formData.legal_address} onChange={handleChange} required />
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="actual_address">Фактический адрес</Label>
                                    <Input id="actual_address" placeholder="Алматы, Абая 50" value={formData.actual_address} onChange={handleChange} required />
                                </div>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label htmlFor="iban">IBAN (KZT)</Label>
                                        <Input id="iban" placeholder="KZ..." value={formData.iban} onChange={handleChange} required />
                                    </div>
                                    <div className="space-y-2">
                                        <Label htmlFor="swift">SWIFT код</Label>
                                        <Input id="swift" placeholder="KAZ..." value={formData.swift} onChange={handleChange} required />
                                    </div>
                                </div>
                            </>
                        )}

                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label htmlFor="inn">ИНН (Необязательно)</Label>
                                <Input id="inn" placeholder="123456789012" value={formData.inn} onChange={handleChange} />
                            </div>
                            <div className="space-y-2">
                                <Label htmlFor="phone">Телефон</Label>
                                <Input id="phone" placeholder="+7 700 000 0000" value={formData.phone} onChange={handleChange} required />
                            </div>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="email">Электронная почта</Label>
                            <Input id="email" type="email" placeholder="name@company.com" value={formData.email} onChange={handleChange} required />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password">Пароль</Label>
                            <Input id="password" type="password" value={formData.password} onChange={handleChange} required />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password_confirmation">Подтвердите пароль</Label>
                            <Input id="password_confirmation" type="password" value={formData.password_confirmation} onChange={handleChange} required />
                        </div>
                    </CardContent>
                    <CardFooter className="flex flex-col space-y-4">
                        <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isLoading}>
                            {isLoading ? 'Создание аккаунта...' : 'Зарегистрироваться'}
                        </Button>
                        <div className="text-sm text-center text-gray-500">
                            Уже есть аккаунт?{' '}
                            <Link to="/login" className="text-red-600 hover:underline">
                                Войдите здесь
                            </Link>
                        </div>
                    </CardFooter>
                </form>
            </Card>
        </div>
    );
};

export default RegisterPage;
