import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useAuth } from '@/context/AuthContext';
import { X, Loader2, Mail, Lock, Eye, EyeOff } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useNavigate } from 'react-router-dom';

const passwordSchema = z.object({
    email: z.string().email("Введите корректный Email"),
    password: z.string().min(1, "Введите пароль"),
});

type PasswordFormValues = z.infer<typeof passwordSchema>;

interface LoginModalProps {
    isOpen: boolean;
    onClose: () => void;
}

const LoginModal: React.FC<LoginModalProps> = ({ isOpen, onClose }) => {
    const [error, setError] = useState<string | null>(null);
    const [showPassword, setShowPassword] = useState(false);
    const { loginWithPassword } = useAuth();
    const navigate = useNavigate();

    // Forms
    const {
        register: registerPass,
        handleSubmit: handleSubmitPass,
        formState: { errors: passErrors, isSubmitting: isPassSubmitting },
    } = useForm<PasswordFormValues>({ resolver: zodResolver(passwordSchema) });

    // Handlers
    const onPasswordSubmit = async (data: PasswordFormValues) => {
        try {
            setError(null);
            await loginWithPassword(data.email, data.password);
            onClose();
        } catch (err: any) {
            console.error("Login failed:", err);
            let errorMessage = "Неверный email или пароль. Пожалуйста, проверьте данные и попробуйте снова.";

            if (err.response?.status === 401) {
                errorMessage = "Неверный email или пароль. Пожалуйста, проверьте данные и попробуйте снова.";
            } else if (err.message) {
                if (err.message.includes('network') || err.code === 'ERR_NETWORK') {
                    errorMessage = "Ошибка сети. Пожалуйста, проверьте интернет-соединение.";
                }
            }
            setError(errorMessage);
        }
    };

    const handleRegisterClick = () => {
        onClose();
        navigate('/register');
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in">
            <div className="relative w-full max-w-md bg-white rounded-xl shadow-2xl p-6 overflow-hidden">
                <button
                    onClick={onClose}
                    className="absolute right-4 top-4 text-gray-400 hover:text-gray-500 z-10"
                >
                    <X className="h-5 w-5" />
                </button>

                <div className="text-center mb-6">
                    <h2 className="text-2xl font-bold text-gray-900">Вход в DYNAMIX</h2>
                    <p className="text-sm text-gray-500 mt-1">Войдите в свой аккаунт для продолжения</p>
                </div>

                {error && (
                    <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 rounded-md border border-red-100 flex items-center">
                        <span className="mr-2">⚠️</span> {error}
                    </div>
                )}

                <form onSubmit={handleSubmitPass(onPasswordSubmit)} className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="pass-email">Email</Label>
                        <div className="relative">
                            <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                            <Input id="pass-email" className="pl-9" placeholder="name@company.com" {...registerPass('email')} />
                        </div>
                        {passErrors.email && <p className="text-xs text-red-500">{passErrors.email.message}</p>}
                    </div>
                    <div className="space-y-2">
                        <div className="flex items-center justify-between">
                            <Label htmlFor="password">Пароль</Label>
                            <button
                                type="button"
                                onClick={() => {
                                    onClose();
                                    navigate('/forgot-password');
                                }}
                                title="Восстановить через OTP-код"
                                className="text-xs font-medium text-red-600 hover:text-red-700 hover:underline"
                            >
                                Забыли пароль?
                            </button>
                        </div>
                        <div className="relative">
                            <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                            <Input
                                id="password"
                                type={showPassword ? 'text' : 'password'}
                                className="pl-9 pr-10"
                                placeholder="••••••••"
                                {...registerPass('password')}
                            />
                            <button
                                type="button"
                                onClick={() => setShowPassword(!showPassword)}
                                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                            >
                                {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </button>
                        </div>
                        {passErrors.password && <p className="text-xs text-red-500">{passErrors.password.message}</p>}
                    </div>
                    <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isPassSubmitting}>
                        {isPassSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Войти
                    </Button>
                </form>

                <div className="text-center text-sm text-gray-500 mt-4 pt-4 border-t">
                    Нет аккаунта?{" "}
                    <button
                        onClick={handleRegisterClick}
                        className="text-red-600 hover:text-red-700 font-semibold hover:underline"
                    >
                        Зарегистрируйтесь
                    </button>
                    {/* OTP hidden as per request */}
                </div>
            </div>
        </div>
    );
};

export default LoginModal;
