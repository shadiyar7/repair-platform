import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';

const ForgotPasswordPage: React.FC = () => {
    const [email, setEmail] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [isSubmitted, setIsSubmitted] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);

        try {
            await api.post('/api/v1/auth/password', { email });
            setIsSubmitted(true);
            toast.success('Инструкции отправлены на почту');
        } catch (err: any) {
            console.error(err);
            toast.error(err.response?.data?.errors?.[0] || 'Произошла ошибка');
        } finally {
            setIsLoading(false);
        }
    };

    if (isSubmitted) {
        return (
            <div className="flex items-center justify-center min-h-[80vh]">
                <Card className="w-full max-w-md">
                    <CardHeader className="text-center">
                        <CardTitle>Проверьте почту</CardTitle>
                        <CardDescription>
                            Мы отправили инструкции по восстановлению пароля на <b>{email}</b>
                        </CardDescription>
                    </CardHeader>
                    <CardFooter>
                        <Link to="/login" className="w-full">
                            <Button variant="outline" className="w-full">Вернуться к входу</Button>
                        </Link>
                    </CardFooter>
                </Card>
            </div>
        );
    }

    return (
        <div className="flex items-center justify-center min-h-[80vh]">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle>Восстановление пароля</CardTitle>
                    <CardDescription>Введите ваш email, и мы отправим ссылку для сброса пароля</CardDescription>
                </CardHeader>
                <form onSubmit={handleSubmit}>
                    <CardContent className="space-y-4">
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
                    </CardContent>
                    <CardFooter className="flex flex-col space-y-4">
                        <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isLoading}>
                            {isLoading ? 'Отправка...' : 'Отправить инструкции'}
                        </Button>
                        <div className="text-sm text-center text-gray-500">
                            Вспомнили пароль?{' '}
                            <Link to="/login" className="text-red-600 hover:underline">
                                Войти
                            </Link>
                        </div>
                    </CardFooter>
                </form>
            </Card>
        </div>
    );
};

export default ForgotPasswordPage;
