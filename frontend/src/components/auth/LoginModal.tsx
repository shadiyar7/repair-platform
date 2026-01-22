import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useAuth } from '@/context/AuthContext';
import { X, Loader2, Mail, Lock } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

const emailSchema = z.object({
    email: z.string().email("Введите корректный Email"),
});

const passwordSchema = z.object({
    email: z.string().email("Введите корректный Email"),
    password: z.string().min(1, "Введите пароль"),
});

const otpSchema = z.object({
    otp: z.string().length(6, "Код должен состоять из 6 цифр"),
});

type EmailFormValues = z.infer<typeof emailSchema>;
type PasswordFormValues = z.infer<typeof passwordSchema>;
type OtpFormValues = z.infer<typeof otpSchema>;

interface LoginModalProps {
    isOpen: boolean;
    onClose: () => void;
}

const LoginModal: React.FC<LoginModalProps> = ({ isOpen, onClose }) => {
    const [loginMethod, setLoginMethod] = useState<'password' | 'otp'>('password');
    const [step, setStep] = useState<'email' | 'otp'>('email'); // For OTP flow
    const [emailForOtp, setEmailForOtp] = useState('');
    const [error, setError] = useState<string | null>(null);
    const { sendOtp, verifyOtp, loginWithPassword } = useAuth();

    // Forms
    const {
        register: registerPass,
        handleSubmit: handleSubmitPass,
        setValue: setPassEmail,
        formState: { errors: passErrors, isSubmitting: isPassSubmitting },
    } = useForm<PasswordFormValues>({ resolver: zodResolver(passwordSchema) });

    const {
        register: registerEmail,
        handleSubmit: handleSubmitEmail,
        formState: { errors: emailErrors, isSubmitting: isEmailSubmitting },
    } = useForm<EmailFormValues>({ resolver: zodResolver(emailSchema) });

    const {
        register: registerOtp,
        handleSubmit: handleSubmitOtp,
        formState: { errors: otpErrors, isSubmitting: isOtpSubmitting },
    } = useForm<OtpFormValues>({ resolver: zodResolver(otpSchema) });

    // Handlers
    const onPasswordSubmit = async (data: PasswordFormValues) => {
        try {
            setError(null);
            await loginWithPassword(data.email, data.password);
            onClose();
        } catch (err) {
            console.error("Login failed:", err);
            setError(err instanceof Error ? err.message : 'Неизвестная ошибка входа');
        }
    };

    const onEmailSubmit = async (data: EmailFormValues) => {
        try {
            setError(null);
            await sendOtp(data.email);
            setEmailForOtp(data.email);
            setStep('otp');
        } catch (err) {
            setError('Ошибка отправки кода. Проверьте Email.');
        }
    };

    const onOtpSubmit = async (data: OtpFormValues) => {
        try {
            setError(null);
            await verifyOtp(emailForOtp, data.otp);
            onClose();
            setStep('email');
        } catch (err) {
            setError('Неверный код подтверждения.');
        }
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
                    <p className="text-sm text-gray-500 mt-1">Выберите способ входа</p>
                </div>

                {error && (
                    <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 rounded-md border border-red-100 flex items-center">
                        <span className="mr-2">⚠️</span> {error}
                    </div>
                )}

                <Tabs value={loginMethod} onValueChange={(v) => setLoginMethod(v as 'password' | 'otp')} className="w-full">
                    <TabsList className="grid w-full grid-cols-2 mb-6">
                        <TabsTrigger value="password">Пароль</TabsTrigger>
                        <TabsTrigger value="otp">Email код (OTP)</TabsTrigger>
                    </TabsList>

                    <TabsContent value="password">
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
                                <Label htmlFor="password">Пароль</Label>
                                <div className="relative">
                                    <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                                    <Input id="password" type="password" className="pl-9" placeholder="••••••••" {...registerPass('password')} />
                                </div>
                                {passErrors.password && <p className="text-xs text-red-500">{passErrors.password.message}</p>}
                            </div>
                            <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isPassSubmitting}>
                                {isPassSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                Войти
                            </Button>
                        </form>
                    </TabsContent>

                    <TabsContent value="otp">
                        {step === 'email' ? (
                            <form onSubmit={handleSubmitEmail(onEmailSubmit)} className="space-y-4">
                                <div className="space-y-2">
                                    <Label htmlFor="otp-email">Email</Label>
                                    <div className="relative">
                                        <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                                        <Input id="otp-email" className="pl-9" placeholder="name@company.com" {...registerEmail('email')} />
                                    </div>
                                    {emailErrors.email && <p className="text-xs text-red-500">{emailErrors.email.message}</p>}
                                </div>
                                <Button type="submit" className="w-full" disabled={isEmailSubmitting}>
                                    {isEmailSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                    Получить код
                                </Button>
                            </form>
                        ) : (
                            <form onSubmit={handleSubmitOtp(onOtpSubmit)} className="space-y-4">
                                <div className="text-center text-sm text-gray-500 mb-4 bg-gray-50 p-2 rounded">
                                    Код отправлен на <span className="font-semibold text-gray-900">{emailForOtp}</span>
                                </div>
                                <div className="space-y-2">
                                    <Label htmlFor="otp-code">Код из SMS/Email (111111 для теста)</Label>
                                    <Input id="otp-code" className="text-center tracking-[0.5em] text-lg font-mono" maxLength={6} placeholder="000000" {...registerOtp('otp')} />
                                    {otpErrors.otp && <p className="text-xs text-red-500">{otpErrors.otp.message}</p>}
                                </div>
                                <Button type="submit" className="w-full bg-red-600 hover:bg-red-700" disabled={isOtpSubmitting}>
                                    {isOtpSubmitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                                    Подтвердить
                                </Button>
                                <button type="button" onClick={() => setStep('email')} className="w-full text-xs text-gray-500 hover:underline mt-2">
                                    Изменить Email
                                </button>
                            </form>
                        )}
                    </TabsContent>
                </Tabs>

                {/* Footer removed as per request */}
            </div>
        </div>
    );
};

export default LoginModal;
