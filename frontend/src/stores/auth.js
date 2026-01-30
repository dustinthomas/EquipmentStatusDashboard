import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useAuthStore = defineStore('auth', () => {
    // State
    const user = ref(null)
    const isAuthenticated = ref(false)
    const loading = ref(false)
    const error = ref(null)

    // Getters
    const isAdmin = computed(() => user.value?.role === 'admin')
    const userName = computed(() => user.value?.name || user.value?.username || '')

    // Actions

    /**
     * Check current authentication status on app load
     * Calls /api/auth/me to restore session if logged in
     */
    async function checkAuth() {
        loading.value = true
        error.value = null

        try {
            const response = await fetch('/api/auth/me', {
                method: 'GET',
                credentials: 'same-origin',
                headers: {
                    'Accept': 'application/json'
                }
            })

            if (response.ok) {
                const data = await response.json()
                isAuthenticated.value = true
                user.value = data.user
            } else {
                // Not authenticated - this is expected
                isAuthenticated.value = false
                user.value = null
            }
        } catch (err) {
            console.error('Auth check failed:', err)
            isAuthenticated.value = false
            user.value = null
        } finally {
            loading.value = false
        }
    }

    /**
     * Handle login
     * @param {string} username
     * @param {string} password
     * @returns {Promise<{success: boolean, error: string|null}>}
     */
    async function login(username, password) {
        loading.value = true
        error.value = null

        try {
            const response = await fetch('/api/auth/login', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ username, password })
            })

            const data = await response.json()

            if (response.ok) {
                isAuthenticated.value = true
                user.value = data.user
                return { success: true, error: null }
            } else {
                error.value = data.error || 'Login failed. Please try again.'
                return { success: false, error: error.value }
            }
        } catch (err) {
            console.error('Login request failed:', err)
            error.value = 'Unable to connect to server. Please try again.'
            return { success: false, error: error.value }
        } finally {
            loading.value = false
        }
    }

    /**
     * Handle logout
     */
    async function logout() {
        loading.value = true

        try {
            await fetch('/api/auth/logout', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Accept': 'application/json'
                }
            })
        } catch (err) {
            console.error('Logout request failed:', err)
        } finally {
            // Clear auth state regardless of response
            clearAuth()
            loading.value = false
        }
    }

    /**
     * Clear authentication state (called on 401)
     */
    function clearAuth() {
        isAuthenticated.value = false
        user.value = null
    }

    return {
        // State
        user,
        isAuthenticated,
        loading,
        error,
        // Getters
        isAdmin,
        userName,
        // Actions
        checkAuth,
        login,
        logout,
        clearAuth
    }
})
