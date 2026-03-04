import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

const api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
    withCredentials: true,
});

// Add a request interceptor to include the JWT token in headers
api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Add a response interceptor to handle 401 Unauthorized globally
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            // Check if we are not already hitting an auth endpoint (to avoid blocking incorrect password attempts)
            const isAuthEndpoint = error.config?.url?.includes('/auth/login') || error.config?.url?.includes('/auth/verify');

            if (!isAuthEndpoint) {
                // Token has expired or is invalid
                localStorage.removeItem('token');
                localStorage.removeItem('user');

                // Only redirect if we're not already on the login page
                if (!window.location.pathname.includes('/login')) {
                    sessionStorage.setItem('session_expired', 'true');
                    window.location.href = '/login';
                }
            }
        }
        return Promise.reject(error);
    }
);

export default api;
