
export const NCALayer = {
    socket: null as WebSocket | null,

    connect: (): Promise<void> => {
        return new Promise((resolve, reject) => {
            const socket = new WebSocket('wss://127.0.0.1:13579/');

            socket.onopen = () => {
                console.log('NCALayer connected');
                NCALayer.socket = socket;
                resolve();
            };

            socket.onclose = () => {
                console.log('NCALayer disconnected');
                NCALayer.socket = null;
            };

            socket.onerror = (error) => {
                console.error('NCALayer error', error);
                reject(error);
            };
        });
    },

    createCms: (data: string): Promise<string> => {
        return new Promise((resolve, reject) => {
            if (!NCALayer.socket || NCALayer.socket.readyState !== WebSocket.OPEN) {
                reject(new Error('NCALayer не подключен (проверьте, запущено ли приложение NCALayer)'));
                return;
            }

            // 'storageName' cannot be empty in createCMSSignatureFromBase64.
            // 'PKCS12' is the standard for file-based keys (.p12) and triggers a file picker.
            const request = {
                module: 'kz.gov.pki.knca.commonUtils',
                method: 'createCMSSignatureFromBase64',
                args: ['PKCS12', 'SIGNATURE', data, true] // storage, keyType, base64Data, isAttached (true for attached)
            };

            // Note: If you have a physical token (Kaztoken, etc.), use 'AKKaztoken Store' or similar.
            // But 'PKCS12' is the safest default to trigger the browser's file selection if needed.

            console.log('NCALayer signing request:', { ...request, args: [request.args[0], request.args[1], `Base64(${data.length})`, request.args[3]] });

            const handleMessage = (event: MessageEvent) => {
                try {
                    const response = JSON.parse(event.data);
                    console.log('NCALayer raw response:', response);

                    if (response.code === '200') {
                        resolve(response.responseObject);
                    } else if (response.status === '200') {
                        // Some versions use status instead of code
                        resolve(response.responseObject || response.result);
                    } else {
                        // Handle potential error from NCALayer
                        const errorMsg = response.message || response.responseObject || 'Ошибка при подписании';
                        reject(new Error(errorMsg));
                    }
                } catch (e) {
                    console.error('Error parsing NCALayer response', e);
                    reject(new Error('Некорректный ответ от NCALayer'));
                } finally {
                    NCALayer.socket?.removeEventListener('message', handleMessage);
                }
            };

            NCALayer.socket.addEventListener('message', handleMessage);
            NCALayer.socket.send(JSON.stringify(request));
        });
    }
};
