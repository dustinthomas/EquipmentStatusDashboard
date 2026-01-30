<script setup>
import { onMounted, ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useDashboardStore } from '@/stores/dashboard'
import NavBar from '@/components/layout/NavBar.vue'
import LoginForm from '@/components/layout/LoginForm.vue'
import ToastContainer from '@/components/common/ToastContainer.vue'

const authStore = useAuthStore()
const dashboardStore = useDashboardStore()

const appReady = ref(false)

onMounted(async () => {
    await authStore.checkAuth()
    appReady.value = true

    // If authenticated, fetch initial data
    if (authStore.isAuthenticated) {
        dashboardStore.readFiltersFromUrl()
    }
})
</script>

<template>
    <div id="app">
        <!-- Loading state while checking auth -->
        <div v-if="!appReady" class="loading-screen">
            <div class="loading-content">
                <div class="loading-spinner"></div>
                <p>Loading...</p>
            </div>
        </div>

        <!-- Main app content -->
        <template v-else>
            <NavBar />

            <main class="main-content">
                <div class="container">
                    <!-- Show login form if not authenticated -->
                    <LoginForm v-if="!authStore.isAuthenticated" />

                    <!-- Show router view if authenticated -->
                    <router-view v-else v-slot="{ Component }">
                        <transition name="page" mode="out-in">
                            <component :is="Component" />
                        </transition>
                    </router-view>
                </div>
            </main>

            <footer class="footer">
                <div class="container">
                    <p class="footer-copyright">
                        QCI Equipment Status Dashboard
                    </p>
                </div>
            </footer>

            <ToastContainer />
        </template>
    </div>
</template>

<style scoped>
.loading-screen {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    background-color: var(--qci-light-grey);
}

.loading-content {
    text-align: center;
}

.loading-content p {
    margin-top: 16px;
    color: var(--qci-body-text);
}

.footer {
    background-color: var(--qci-dark-navy);
    color: var(--qci-white);
    padding: 20px 0;
    text-align: center;
    font-size: 0.875rem;
    margin-top: 40px;
}

.footer-copyright {
    opacity: 0.9;
    margin: 0;
}
</style>
