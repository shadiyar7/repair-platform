import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Eye, EyeOff } from 'lucide-react';

import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';

const LoginPage: React.FC = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
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
                } else if (userData.role === 'director') {
                    navigate('/director');
                } else if (userData.role === 'supervisor') {
                    navigate('/supervisor');
                } else {
                    navigate('/'); // Catalog is at root for Client
                }
            } else {
                navigate('/');
            }

            toast.success("Вход выполнен успешно!", {
                description: "Добро пожаловать в DYNAMIX"
            });
        } catch (err: any) {
            console.error(err);
            toast.error("Ошибка входа", {
                description: err.message || "Неверный email или пароль"
            });
            setError(err.message || 'Ошибка входа');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex items-center justify-center min-h-[80vh]">
            <Card className="w-full max-w-md border-none shadow-xl">
                <CardHeader className="space-y-1 pb-6">
                    <CardTitle className="text-2xl font-bold text-center">Вход в DYNAMIX</CardTitle>
                    <CardDescription className="text-center">
                        Войдите в свой аккаунт для продолжения
                    </CardDescription>
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
                            <div className="flex items-center justify-between">
                                <Label htmlFor="password">Пароль</Label>
                                <Link to="/forgot-password" title="Восстановить через OTP-код" className="text-xs font-medium text-red-600 hover:text-red-700 hover:underline">
                                    Забыли пароль?
                                </Link>
                            </div>
                            <div className="relative">
                                <Input
                                    id="password"
                                    type={showPassword ? 'text' : 'password'}
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    className="pr-10"
                                    required
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                                >
                                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                </button>
                            </div>
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
