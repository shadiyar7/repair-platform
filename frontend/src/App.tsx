import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { MessageCircle } from 'lucide-react';
import { Toaster } from 'sonner';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from '@/context/AuthContext';
import { CartProvider } from '@/context/CartContext';
import ProtectedRoute from '@/components/ProtectedRoute';
import Layout from '@/components/Layout';
import HomePage from '@/pages/HomePage';
import LoginPage from '@/pages/auth/LoginPage';
import RegisterPage from '@/pages/auth/RegisterPage';
import CatalogPage from '@/pages/catalog/CatalogPage';
import CatalogNewPage from '@/pages/catalog/CatalogNewPage';

import OrdersPage from '@/pages/orders/OrdersPage';
import OrderDetailPage from '@/pages/orders/OrderDetailPage';
import CheckoutPage from '@/pages/orders/CheckoutPage';
import WarehouseDashboard from '@/pages/warehouse/WarehouseDashboard';
import DriverDashboard from '@/pages/driver/DriverDashboard';
import ProfilePage from '@/pages/ProfilePage';
import AdminWarehousesPage from '@/pages/admin/AdminWarehousesPage';
import AdminProductsPage from '@/pages/admin/AdminProductsPage';
import AdminUserManagementPage from '@/pages/admin/AdminUserManagementPage';
import AdminLoginPage from '@/pages/auth/AdminLoginPage';
import AdminDiscountsPage from '@/pages/admin/AdminDiscountsPage';

import SmartLinkPage from '@/pages/driver/SmartLinkPage';
import TrackingPage from '@/pages/public/TrackingPage';

import SupervisorDashboard from '@/pages/supervisor/SupervisorDashboard';
import DirectorDashboard from '@/pages/director/DirectorDashboard';
import DirectorOrdersPage from '@/pages/director/DirectorOrdersPage';
import ForgotPasswordPage from '@/pages/auth/ForgotPasswordPage';

import { Navigate } from 'react-router-dom';


const RoleBasedRedirect = () => {
  const { user, isLoading } = useAuth();

  if (isLoading) return <div>Loading...</div>;

  if (user?.role === 'supervisor') return <Navigate to="/supervisor" replace />;
  if (user?.role === 'director') return <Navigate to="/director" replace />;
  if (user?.role === 'warehouse') return <Navigate to="/warehouse" replace />;
  if (user?.role === 'driver') return <Navigate to="/driver" replace />;

  // Default for Client/Admin (or unknown) -> Catalog
  return <CatalogPage />;
};

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <CartProvider>
          <Router>
            <Routes>
              {/* Public Tracking Route */}
              <Route path="/track/:token" element={<TrackingPage />} />

              {/* Driver specific smart link (Legacy or specific view) */}
              <Route path="/smart-link/:token" element={<SmartLinkPage />} />

              <Route path="/" element={<Layout />}>
                <Route index element={<CatalogNewPage />} />
                <Route path="catalogNew" element={
                  <ProtectedRoute allowedRoles={['client', 'admin', 'supervisor', 'director']}>
                    <RoleBasedRedirect />
                  </ProtectedRoute>
                } />
                <Route path="landing" element={<HomePage />} />
                <Route path="login" element={<LoginPage />} />
                <Route path="register" element={<RegisterPage />} />
                <Route path="forgot-password" element={<ForgotPasswordPage />} />
                <Route
                  path="orders"
                  element={
                    <ProtectedRoute allowedRoles={['client', 'admin', 'director']}>
                      <OrdersPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="orders/:id"
                  element={
                    <ProtectedRoute allowedRoles={['client', 'admin', 'warehouse', 'driver', 'director', 'supervisor']}>
                      <OrderDetailPage />
                    </ProtectedRoute>
                  }
                />

                <Route
                  path="checkout"
                  element={
                    <ProtectedRoute allowedRoles={['client', 'admin']}>
                      <CheckoutPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="warehouse"
                  element={
                    <ProtectedRoute allowedRoles={['warehouse', 'admin', 'supervisor']}>
                      <WarehouseDashboard />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="driver"
                  element={
                    <ProtectedRoute allowedRoles={['driver', 'admin']}>
                      <DriverDashboard />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="profile"
                  element={
                    <ProtectedRoute>
                      <ProfilePage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="admin/warehouses"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <AdminWarehousesPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="admin/warehouses/:id"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <AdminProductsPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="admin/discounts"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <AdminDiscountsPage />
                    </ProtectedRoute>
                  }
                />

                <Route
                  path="supervisor"
                  element={
                    <ProtectedRoute allowedRoles={['supervisor', 'admin']}>
                      <SupervisorDashboard />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="director"
                  element={
                    <ProtectedRoute allowedRoles={['director', 'admin']}>
                      <DirectorDashboard />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="director/orders"
                  element={
                    <ProtectedRoute allowedRoles={['director', 'admin']}>
                      <DirectorOrdersPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="admin/users"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <AdminUserManagementPage />
                    </ProtectedRoute>
                  }
                />
              </Route>

              {/* Standalone Admin Login Route - Outside Layout if we want different look, or inside if we want header */}
              {/* Requirement: /admin/login */}
              <Route path="/admin/login" element={<AdminLoginPage />} />
            </Routes>
          </Router>
        </CartProvider>
      </AuthProvider>
      <SupportWidget />
      <Toaster position="top-center" richColors expand={true} />
    </QueryClientProvider>
  );
}

const SupportWidget = () => {
  return (
    <a
      href="https://wa.me/77014264519"
      target="_blank"
      rel="noopener noreferrer"
      className="fixed bottom-6 right-6 bg-[#25D366] text-white px-5 py-3 rounded-xl shadow-[0_10px_25px_-5px_rgba(37,211,102,0.4)] hover:shadow-[0_15px_30px_-5px_rgba(37,211,102,0.6)] hover:-translate-y-1 transition-all duration-300 z-50 flex items-center space-x-3 group"
    >
      <div className="relative">
        <MessageCircle className="w-7 h-7" />
        <span className="absolute -top-1 -right-1 flex h-3 w-3">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
          <span className="relative inline-flex rounded-full h-3 w-3 bg-white"></span>
        </span>
      </div>
      <div className="flex flex-col items-start leading-tight">
        <span className="text-[9px] uppercase tracking-[0.15em] opacity-90 font-black">Поддержка</span>
        <span className="text-sm font-bold whitespace-nowrap">Нужна помощь?</span>
      </div>
    </a>
  );
};

export default App;
