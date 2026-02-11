import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';

import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';

const LoginPage: React.FC = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { loginWithPassword } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setIsLoading(true);

        try {
            await loginWithPassword(email, password);
            // Navigation is now handled by redirect or state change in App/Context, but we can explicit navigate
            // However, loginWithPassword in AuthContext does NOT return role currently.
            // We can read user from context or local storage after await.
            // But for safety, let's just default to catalog for now or reload page.
            // Better: Let's assume AuthContext updates state and we can navigate.
            // Actually, the previous implementation did role-based redirect.
            // Let's grab the user from localStorage since AuthContext writes it there.
            const storedUser = localStorage.getItem('user');
            if (storedUser) {
                const userData = JSON.parse(storedUser);
                if (userData.role === 'warehouse') {
                    navigate('/warehouse');
                } else if (userData.role === 'driver') {
                    navigate('/driver');
                } else {
                    navigate('/'); // Catalog is at root
                }
            } else {
                navigate('/');
            }

        } catch (err: any) {
            console.error(err);
            // Error is already formatted by AuthContext or we catch it here
            setError(err.message || 'Ошибка входа');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex items-center justify-center min-h-[80vh]">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle>Вход в систему</CardTitle>
                    <CardDescription>Введите ваши данные для доступа к аккаунту</CardDescription>
                </CardHeader>
                <form onSubmit={handleSubmit}>
                    <CardContent className="space-y-4">
                        {error && <div className="p-3 text-sm text-red-500 bg-red-50 rounded-md">{error}</div>}
                        <div className="space-y-2">
                            <Label htmlFor="email">Электронная почта</Label>
                            <Input
                                id="email"
                                type="email"
                                placeholder="name@company.com"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password">Пароль</Label>
                            <Input
                                id="password"
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </div>
                    </CardContent>
                    <CardFooter className="flex flex-col space-y-4">
                        <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isLoading}>
                            {isLoading ? 'Вход...' : 'Войти'}
                        </Button>
                        <div className="text-sm text-center text-gray-500">
                            Нет аккаунта?{' '}
                            <Link to="/register" className="text-red-600 hover:underline">
                                Зарегистрируйтесь здесь
                            </Link>
                        </div>
                    </CardFooter>
                </form>
            </Card>
        </div>
    );
};
export default LoginPage;
