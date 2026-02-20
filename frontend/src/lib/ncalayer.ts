
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
                reject(new Error('NCALayer not connected'));
                return;
            }

            const request = {
                module: 'kz.gov.pki.knca.commonUtils',
                method: 'createCms',
                args: ['', data, true] // type, data, isAttached
            };

            // iDocs usually requires attached or detached?
            // "signatureBinaryContent" implies we send the signature. If it's CAdES, it might be attached or detached.
            // Usually for PDF signing in systems like this, we sign the HASH (detached).
            // But the method name is `createCms`. 
            // I will assume attached (true) or detached (false). 
            // Let's try `false` (detached) first as we upload the original file separately.
            // Wait, if we sign a hash, we sign the hash. 
            // If `content-to-sign` returns the file digest, we sign it.

            // We need to handle the response message
            const handleMessage = (event: MessageEvent) => {
                const response = JSON.parse(event.data);
                if (response.code === '200') {
                    resolve(response.responseObject);
                } else {
                    reject(new Error(response.message || 'Signing failed'));
                }
                NCALayer.socket?.removeEventListener('message', handleMessage);
            };

            NCALayer.socket.addEventListener('message', handleMessage);
            NCALayer.socket.send(JSON.stringify(request));
        });
    }
};
