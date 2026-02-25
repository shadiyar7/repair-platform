import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '@/lib/api';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';

type Step = 'email' | 'reset';

const ForgotPasswordPage: React.FC = () => {
    const [step, setStep] = useState<Step>('email');
    const [email, setEmail] = useState('');
    const [otp, setOtp] = useState('');
    const [password, setPassword] = useState('');
    const [passwordConfirmation, setPasswordConfirmation] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const navigate = useNavigate();

    // Step 1: Request OTP
    const handleRequestOtp = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsLoading(true);
        try {
            await api.post('/api/v1/auth/password', { email: email.trim() });
            toast.success('Код отправлен на почту (если такой аккаунт существует)');
            setStep('reset');
        } catch (err: any) {
            toast.error('Ошибка при отправке кода');
        } finally {
            setIsLoading(false);
        }
    };

    // Step 2: Enter code + new password
    const handleResetPassword = async (e: React.FormEvent) => {
        e.preventDefault();
        if (password !== passwordConfirmation) {
            toast.error('Пароли не совпадают');
            return;
        }
        if (password.length < 6) {
            toast.error('Пароль должен быть не менее 6 символов');
            return;
        }
        setIsLoading(true);
        try {
            await api.put('/api/v1/auth/password', {
                email: email.trim(),
                otp,
                password,
                password_confirmation: passwordConfirmation
            });
            toast.success('Пароль успешно изменён! Войдите с новым паролем.');
            navigate('/login');
        } catch (err: any) {
            toast.error(err.response?.data?.error || 'Неверный код или срок действия истёк');
        } finally {
            setIsLoading(false);
        }
    };

    if (step === 'email') {
        return (
            <div className="flex items-center justify-center min-h-[80vh]">
                <Card className="w-full max-w-md">
                    <CardHeader>
                        <CardTitle>Восстановление пароля</CardTitle>
                        <CardDescription>
                            Введите ваш email — мы отправим код для сброса пароля
                        </CardDescription>
                    </CardHeader>
                    <form onSubmit={handleRequestOtp}>
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
                                {isLoading ? 'Отправка...' : 'Получить код'}
                            </Button>
                            <div className="text-sm text-center text-gray-500">
                                Вспомнили пароль?{' '}
                                <Link to="/login" className="text-red-600 hover:underline">Войти</Link>
                            </div>
                        </CardFooter>
                    </form>
                </Card>
            </div>
        );
    }

    return (
        <div className="flex items-center justify-center min-h-[80vh]">
            <Card className="w-full max-w-md">
                <CardHeader>
                    <CardTitle>Введите код и новый пароль</CardTitle>
                    <CardDescription>
                        Код отправлен на <b>{email}</b>. Проверьте почту и введите код ниже.
                    </CardDescription>
                </CardHeader>
                <form onSubmit={handleResetPassword}>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="otp">Код из письма</Label>
                            <Input
                                id="otp"
                                className="text-center tracking-[0.5em] text-lg font-mono"
                                maxLength={6}
                                placeholder="000000"
                                value={otp}
                                onChange={(e) => setOtp(e.target.value)}
                                required
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="password">Новый пароль</Label>
                            <Input
                                id="password"
                                type="password"
                                placeholder="Минимум 6 символов"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                            />
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="passwordConfirmation">Повторите пароль</Label>
                            <Input
                                id="passwordConfirmation"
                                type="password"
                                value={passwordConfirmation}
                                onChange={(e) => setPasswordConfirmation(e.target.value)}
                                required
                            />
                        </div>
                    </CardContent>
                    <CardFooter className="flex flex-col space-y-4">
                        <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isLoading}>
                            {isLoading ? 'Сохранение...' : 'Сохранить новый пароль'}
                        </Button>
                        <button
                            type="button"
                            onClick={() => setStep('email')}
                            className="text-sm text-gray-500 hover:underline"
                        >
                            ← Изменить email
                        </button>
                    </CardFooter>
                </form>
            </Card>
        </div>
    );
};

export default ForgotPasswordPage;
