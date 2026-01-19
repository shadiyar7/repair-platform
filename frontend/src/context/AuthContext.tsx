import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

// Configure axios to include credentials (cookies)
axios.defaults.withCredentials = true;
axios.defaults.baseURL = 'http://localhost:3000';

interface User {
    id: string;
    email: string;
    role: 'client' | 'admin' | 'warehouse' | 'driver' | 'director';
    company_name?: string;
    phone?: string;
}

interface AuthContextType {
    user: User | null;
    isAuthenticated: boolean;
    sendOtp: (email: string) => Promise<void>;
    verifyOtp: (email: string, otp: string) => Promise<void>;
    loginWithPassword: (email: string, password: string) => Promise<void>;
    logout: () => void;
    isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Check if user is logged in by hitting a protected endpoint or profile
        // For now, simple check using localStorage persistence for USER SESSIONS ONLY (not tokens)
        const storedUser = localStorage.getItem('user');
        if (storedUser) {
            setUser(JSON.parse(storedUser));
        }
        setIsLoading(false);
    }, []);

    const sendOtp = async (email: string) => {
        await axios.post('/api/v1/auth/login', { email });
    };

    const verifyOtp = async (email: string, otp: string) => {
        const response = await axios.post('/api/v1/auth/verify', { email, otp });
        const userData = response.data.user.data.attributes;
        // Map backend attributes to frontend User interface
        const newUser: User = {
            id: response.data.user.data.id,
            email: userData.email,
            role: userData.role,
            company_name: userData.company_name,
            phone: userData.phone
        };

        setUser(newUser);
        localStorage.setItem('user', JSON.stringify(newUser));
    };

    const loginWithPassword = async (email: string, password: string) => {
        const response = await axios.post('/api/v1/auth/login_password', { email, password });
        console.log("LOGIN RESPONSE:", response.data);

        let userData;

        // Strategy 1: User provided structure (status + data)
        if (response.data.data && response.data.data.email) {
            userData = response.data.data;
        }
        // Strategy 2: JSON:API structure (user.data.attributes)
        else if (response.data.user && response.data.user.data && response.data.user.data.attributes) {
            userData = response.data.user.data.attributes;
            // If ID is outside attributes in JSON:API nested user
            if (!userData.id && response.data.user.data.id) {
                userData.id = response.data.user.data.id;
            }
        }
        else {
            console.error("Unknown response structure:", response.data);
            throw new Error("Некорректный ответ от сервера. Проверьте консоль.");
        }

        const newUser: User = {
            id: String(userData.id || '0'),
            email: userData.email,
            role: userData.role,
            company_name: userData.company_name,
            phone: userData.phone
        };
        setUser(newUser);
        localStorage.setItem('user', JSON.stringify(newUser));
    };

    const logout = async () => {
        try {
            await axios.delete('/logout'); // Devise logout to clear cookie
        } catch (error) {
            console.error('Logout error', error);
        } finally {
            setUser(null);
            localStorage.removeItem('user');
        }
    };

    return (
        <AuthContext.Provider value={{
            user,
            isAuthenticated: !!user,
            sendOtp,
            verifyOtp,
            loginWithPassword,
            logout,
            isLoading
        }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
