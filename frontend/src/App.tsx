import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/context/AuthContext';
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

import SmartLinkPage from '@/pages/driver/SmartLinkPage';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <CartProvider>
          <Router>
            <Routes>
              <Route path="/smart-link/:token" element={<SmartLinkPage />} />
              <Route path="/" element={<Layout />}>
                <Route index element={<CatalogPage />} />
                <Route path="catalogNew" element={<CatalogNewPage />} />
                <Route path="landing" element={<HomePage />} />
                <Route path="login" element={<LoginPage />} />
                <Route path="register" element={<RegisterPage />} />
                <Route
                  path="orders"
                  element={
                    <ProtectedRoute allowedRoles={['client', 'admin']}>
                      <OrdersPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="orders/:id"
                  element={
                    <ProtectedRoute allowedRoles={['client', 'admin', 'warehouse', 'driver']}>
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
                    <ProtectedRoute allowedRoles={['warehouse', 'admin']}>
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
              </Route>
            </Routes>
          </Router>
        </CartProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
