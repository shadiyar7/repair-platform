import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { toast } from 'sonner';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Loader2, Percent, Calendar } from 'lucide-react';

interface GlobalDiscount {
    percent: number;
    active: boolean;
    valid_until: string | null;
}

const AdminDiscountsPage: React.FC = () => {
    const queryClient = useQueryClient();

    // Local state for the form so we can edit without instantly saving
    const [percent, setPercent] = useState<string>('0');
    const [active, setActive] = useState<boolean>(false);
    const [validUntil, setValidUntil] = useState<string>('');

    const { isLoading, isError } = useQuery({
        queryKey: ['admin_global_discount'],
        queryFn: () => api.get('/api/v1/admin/global_discount').then(res => {
            const data = res.data as GlobalDiscount;
            setPercent(data.percent?.toString() || '0');
            setActive(!!data.active);
            setValidUntil(data.valid_until ? new Date(data.valid_until).toISOString().split('T')[0] : '');
            return data;
        })
    });

    const updateMutation = useMutation({
        mutationFn: (data: { percent: number; active: boolean; valid_until: string | null }) =>
            api.post('/api/v1/admin/global_discount', { global_discount: data }),
        onSuccess: () => {
            toast.success('Настройки скидок успешно обновлены');
            queryClient.invalidateQueries({ queryKey: ['admin_global_discount'] });
            // Invalidate the public discount cache
            queryClient.invalidateQueries({ queryKey: ['globalDiscount'] });
        },
        onError: (err: any) => {
            toast.error('Ошибка сохранения', {
                description: err.response?.data?.error || err.response?.data?.errors?.join(', ') || 'Попробуйте позже'
            });
        }
    });

    const handleSave = () => {
        const val = parseFloat(percent);
        if (isNaN(val) || val < 0 || val > 100) {
            toast.error('Процент скидки должен быть от 0 до 100');
            return;
        }

        updateMutation.mutate({
            percent: val,
            active,
            valid_until: validUntil || null
        });
    };

    if (isLoading) {
        return <div className="flex justify-center items-center h-64"><Loader2 className="h-8 w-8 animate-spin" /></div>;
    }

    if (isError) {
        return <div className="text-center text-red-600 mt-10">Ошибка загрузки данных скидок</div>;
    }

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <h1 className="text-3xl font-bold tracking-tight">Управление скидками</h1>

            <Card>
                <CardHeader>
                    <CardTitle>Глобальная скидка (Акция)</CardTitle>
                    <CardDescription>
                        При активации эта скидка будет применяться ко <b>всем товарам</b> в корзине при оформлении заказа.
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                    <div className="flex items-center space-x-3 p-4 bg-gray-50 rounded-lg border">
                        <input
                            type="checkbox"
                            id="discount-active"
                            checked={active}
                            onChange={(e) => setActive(e.target.checked)}
                            className="h-4 w-4 rounded border-gray-300 text-red-600 focus:ring-red-500 cursor-pointer"
                        />
                        <div className="grid gap-1.5 leading-none">
                            <label
                                htmlFor="discount-active"
                                className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70 cursor-pointer"
                            >
                                Включить глобальную скидку
                            </label>
                            <p className="text-sm text-muted-foreground">
                                Скидка будет видна всем клиентам на сайте.
                            </p>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="space-y-2">
                            <Label htmlFor="percent" className="flex items-center gap-2">
                                <Percent className="h-4 w-4" /> Размер скидки (%)
                            </Label>
                            <Input
                                id="percent"
                                type="number"
                                min="0"
                                max="100"
                                value={percent}
                                onChange={(e) => setPercent(e.target.value)}
                                disabled={!active}
                            />
                        </div>

                        <div className="space-y-2">
                            <Label htmlFor="valid_until" className="flex items-center gap-2">
                                <Calendar className="h-4 w-4" /> Действует до (необязательно)
                            </Label>
                            <Input
                                id="valid_until"
                                type="date"
                                value={validUntil}
                                onChange={(e) => setValidUntil(e.target.value)}
                                disabled={!active}
                            />
                            <p className="text-xs text-gray-500">Если оставить пустым, скидка действует бессрочно.</p>
                        </div>
                    </div>
                </CardContent>
                <CardFooter className="bg-gray-50 border-t px-6 py-4 flex justify-end">
                    <Button
                        onClick={handleSave}
                        disabled={updateMutation.isPending}
                        className="bg-red-600 hover:bg-red-700"
                    >
                        {updateMutation.isPending ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
                        Сохранить акцию
                    </Button>
                </CardFooter>
            </Card>
        </div>
    );
};

export default AdminDiscountsPage;
