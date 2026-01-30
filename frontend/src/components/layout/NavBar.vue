<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useDashboardStore } from '@/stores/dashboard'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const dashboardStore = useDashboardStore()

const isAdminRoute = computed(() => {
    return route.path.startsWith('/admin')
})

async function handleLogout() {
    await authStore.logout()
    dashboardStore.clearData()
    router.push('/vue')
}

function navigateToDashboard() {
    router.push('/vue')
}

function navigateToAdminTools() {
    router.push('/admin/tools')
}

function navigateToAdminUsers() {
    router.push('/admin/users')
}
</script>

<template>
    <nav class="navbar">
        <div class="container navbar-content">
            <a href="/vue" class="logo" @click.prevent="navigateToDashboard">
                <img src="/img/qci-logo.svg" alt="QCI" class="logo-img" />
                <span>Equipment Status</span>
            </a>

            <div class="nav-links">
                <template v-if="authStore.isAuthenticated">
                    <!-- Dashboard link -->
                    <a
                        href="/vue"
                        class="nav-link"
                        :class="{ 'nav-link-active': route.path === '/vue' || route.path.startsWith('/vue/tools') }"
                        @click.prevent="navigateToDashboard"
                    >
                        Dashboard
                    </a>

                    <!-- Admin links (only for admins) -->
                    <template v-if="authStore.isAdmin">
                        <span class="nav-divider"></span>
                        <a
                            href="/admin/tools"
                            class="nav-link"
                            :class="{ 'nav-link-active': route.path === '/admin/tools' }"
                            @click.prevent="navigateToAdminTools"
                        >
                            Manage Tools
                        </a>
                        <a
                            href="/admin/users"
                            class="nav-link"
                            :class="{ 'nav-link-active': route.path === '/admin/users' }"
                            @click.prevent="navigateToAdminUsers"
                        >
                            Manage Users
                        </a>
                    </template>

                    <span class="nav-divider"></span>

                    <!-- User info -->
                    <span class="user-info">
                        {{ authStore.userName }}
                        <span v-if="authStore.isAdmin" class="role-indicator">(Admin)</span>
                    </span>

                    <!-- Logout button -->
                    <button
                        class="btn btn-outline btn-sm"
                        @click="handleLogout"
                        :disabled="authStore.loading"
                    >
                        <span v-if="authStore.loading" class="loading-spinner loading-spinner-sm"></span>
                        Logout
                    </button>
                </template>

                <template v-else>
                    <span class="nav-text">Please log in</span>
                </template>
            </div>
        </div>
    </nav>
</template>

<style scoped>
.navbar {
    background-color: var(--qci-dark-navy);
    color: var(--qci-white);
    padding: 12px 0;
    box-shadow: var(--shadow-sm);
}

.navbar-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
}

.logo {
    display: flex;
    align-items: center;
    gap: 10px;
    font-weight: 700;
    font-size: 1.1rem;
    color: var(--qci-white);
    text-decoration: none;
    transition: opacity var(--transition-fast);
}

.logo:hover {
    opacity: 0.9;
    text-decoration: none;
}

.logo-img {
    height: 28px;
    width: auto;
}

.nav-links {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
}

.nav-link {
    color: var(--qci-white);
    text-decoration: none;
    padding: 6px 12px;
    border-radius: var(--radius-sm);
    font-size: 0.9rem;
    transition: background-color var(--transition-fast);
}

.nav-link:hover {
    background-color: var(--qci-light-navy);
    text-decoration: none;
}

.nav-link-active {
    background-color: var(--qci-light-navy);
}

.nav-divider {
    width: 1px;
    height: 20px;
    background-color: rgba(255, 255, 255, 0.3);
    margin: 0 4px;
}

.user-info {
    color: var(--qci-white);
    opacity: 0.9;
    padding: 6px 12px;
    font-size: 0.9rem;
}

.role-indicator {
    opacity: 0.7;
    font-size: 0.8rem;
}

.nav-text {
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.9rem;
    padding: 6px 12px;
}

.btn-outline {
    background-color: transparent;
    border: 1px solid var(--qci-white);
    color: var(--qci-white);
}

.btn-outline:hover:not(:disabled) {
    background-color: rgba(255, 255, 255, 0.1);
}
</style>
