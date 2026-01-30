import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Lazy load all views
const DashboardView = () => import('@/views/DashboardView.vue')
const ToolDetailView = () => import('@/views/ToolDetailView.vue')
const ToolHistoryView = () => import('@/views/ToolHistoryView.vue')
const AdminToolsView = () => import('@/views/AdminToolsView.vue')
const AdminUsersView = () => import('@/views/AdminUsersView.vue')

const routes = [
    {
        path: '/',
        redirect: '/vue'
    },
    {
        path: '/vue',
        name: 'dashboard',
        component: DashboardView,
        meta: { requiresAuth: true }
    },
    {
        path: '/vue/tools/:id',
        name: 'tool-detail',
        component: ToolDetailView,
        meta: { requiresAuth: true },
        props: true
    },
    {
        path: '/vue/tools/:id/history',
        name: 'tool-history',
        component: ToolHistoryView,
        meta: { requiresAuth: true },
        props: true
    },
    {
        path: '/admin/tools',
        name: 'admin-tools',
        component: AdminToolsView,
        meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
        path: '/admin/users',
        name: 'admin-users',
        component: AdminUsersView,
        meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
        path: '/admin',
        redirect: '/admin/tools'
    },
    // Catch-all redirect to dashboard
    {
        path: '/:pathMatch(.*)*',
        redirect: '/vue'
    }
]

const router = createRouter({
    history: createWebHistory(),
    routes
})

// Navigation guards
router.beforeEach(async (to, from, next) => {
    const authStore = useAuthStore()

    // Wait for auth check to complete if not ready
    if (!authStore.isAuthenticated && authStore.loading) {
        // Wait a bit for auth check
        await new Promise(resolve => setTimeout(resolve, 100))
    }

    // Check if route requires authentication
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        // Let the app handle showing login - don't redirect
        // The App.vue will show login form when not authenticated
        next()
        return
    }

    // Check if route requires admin
    if (to.meta.requiresAdmin && !authStore.isAdmin) {
        // Redirect to dashboard with error
        next({
            path: '/vue',
            query: { error: 'forbidden' }
        })
        return
    }

    next()
})

export default router
