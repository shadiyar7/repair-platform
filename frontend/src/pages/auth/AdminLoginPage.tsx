import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { ShieldCheck } from 'lucide-react';

const AdminLoginPage: React.FC = () => {
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

            // Check role after login
            const storedUser = localStorage.getItem('user');
            if (storedUser) {
                const userData = JSON.parse(storedUser);
                if (['admin', 'director', 'warehouse', 'supervisor'].includes(userData.role)) {
                    if (userData.role === 'admin') navigate('/admin/users');
                    else if (userData.role === 'warehouse') navigate('/warehouse');
                    else navigate('/orders'); // Fallback for director/supervisor
                } else {
                    setError('Доступ разрешен только сотрудникам. Клиенты должны использовать вход через главную страницу.');
                    // Logout immediately if client tries to login here? For now just show error.
                }
            } else {
                navigate('/');
            }

        } catch (err: any) {
            console.error(err);
            setError(err.message || 'Ошибка входа');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="flex items-center justify-center min-h-screen bg-slate-900">
            <Card className="w-full max-w-md border-slate-700 bg-slate-800 text-slate-100">
                <CardHeader className="text-center">
                    <div className="mx-auto bg-slate-700 p-3 rounded-full w-fit mb-4">
                        <ShieldCheck className="w-8 h-8 text-red-500" />
                    </div>
                    <CardTitle className="text-2xl text-white">Служебный вход</CardTitle>
                    <CardDescription className="text-slate-400">
                        Только для сотрудников компании DYNAMIX
                    </CardDescription>
                </CardHeader>
                <form onSubmit={handleSubmit}>
                    <CardContent className="space-y-4">
                        {error && <div className="p-3 text-sm text-red-200 bg-red-900/50 border border-red-800 rounded-md">{error}</div>}
                        <div className="space-y-2">
                            <Label htmlFor="email" className="text-slate-300">Корпоративная почта</Label>
                            <Input
                                id="email"
                                type="email"
                                placeholder="name@dynamix.kz"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                className="bg-slate-900 border-slate-700 text-white placeholder:text-slate-500 focus:border-red-500"
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password" className="text-slate-300">Пароль</Label>
                            <Input
                                id="password"
                                type="password"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                className="bg-slate-900 border-slate-700 text-white focus:border-red-500"
                            />
                        </div>
                    </CardContent>
                    <CardFooter className="flex flex-col space-y-4">
                        <Button type="submit" className="w-full bg-red-600 hover:bg-red-700 text-white" disabled={isLoading}>
                            {isLoading ? 'Вход...' : 'Войти в систему'}
                        </Button>
                        <Button variant="link" className="text-slate-400 hover:text-white" onClick={() => navigate('/')}>
                            Вернуться на сайт
                        </Button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    );
};

export default AdminLoginPage;
