/**
 * QCI Equipment Status Dashboard - Vue 3 Application
 *
 * Single-file Vue application using CDN-loaded Vue 3.
 * No build step required - runs directly in the browser.
 */

const { createApp, ref, reactive, computed, onMounted, watch } = Vue;

// ========================================
// Application State
// ========================================

const app = createApp({
    setup() {
        // Application ready state (false until auth check completes)
        const appReady = ref(false);

        // ========================================
        // Authentication State
        // ========================================
        const auth = reactive({
            isAuthenticated: false,
            user: null,
            loading: false,
            error: null
        });

        // Login form state
        const loginForm = reactive({
            username: '',
            password: '',
            submitting: false,
            error: null
        });

        // ========================================
        // Authentication Methods
        // ========================================

        /**
         * Check current authentication status on app load.
         * Calls /api/auth/me to restore session if logged in.
         */
        async function checkAuth() {
            try {
                const response = await fetch('/api/auth/me', {
                    method: 'GET',
                    credentials: 'same-origin',
                    headers: {
                        'Accept': 'application/json'
                    }
                });

                if (response.ok) {
                    const data = await response.json();
                    auth.isAuthenticated = true;
                    auth.user = data.user;
                } else {
                    // Not authenticated - this is expected
                    auth.isAuthenticated = false;
                    auth.user = null;
                }
            } catch (error) {
                console.error('Auth check failed:', error);
                auth.isAuthenticated = false;
                auth.user = null;
            } finally {
                appReady.value = true;
            }
        }

        /**
         * Handle login form submission.
         * Calls /api/auth/login with credentials.
         */
        async function handleLogin() {
            // Clear previous errors
            loginForm.error = null;

            // Validate form
            if (!loginForm.username.trim() || !loginForm.password.trim()) {
                loginForm.error = 'Please enter both username and password';
                return;
            }

            loginForm.submitting = true;

            try {
                const response = await fetch('/api/auth/login', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({
                        username: loginForm.username.trim(),
                        password: loginForm.password
                    })
                });

                const data = await response.json();

                if (response.ok) {
                    // Login successful
                    auth.isAuthenticated = true;
                    auth.user = data.user;

                    // Clear form
                    loginForm.username = '';
                    loginForm.password = '';
                    loginForm.error = null;
                } else {
                    // Login failed - display error from API
                    loginForm.error = data.error || 'Login failed. Please try again.';
                }
            } catch (error) {
                console.error('Login request failed:', error);
                loginForm.error = 'Unable to connect to server. Please try again.';
            } finally {
                loginForm.submitting = false;
            }
        }

        /**
         * Handle logout.
         * Calls /api/auth/logout to clear session.
         */
        async function handleLogout() {
            auth.loading = true;

            try {
                const response = await fetch('/api/auth/logout', {
                    method: 'POST',
                    credentials: 'same-origin',
                    headers: {
                        'Accept': 'application/json'
                    }
                });

                // Clear auth state regardless of response
                auth.isAuthenticated = false;
                auth.user = null;
            } catch (error) {
                console.error('Logout request failed:', error);
                // Clear auth state anyway - session may be invalid
                auth.isAuthenticated = false;
                auth.user = null;
            } finally {
                auth.loading = false;
            }
        }

        // ========================================
        // Lifecycle
        // ========================================

        // Check authentication status when app mounts
        onMounted(() => {
            checkAuth();
        });

        // ========================================
        // Computed Properties
        // ========================================

        const isAdmin = computed(() => {
            return auth.user && auth.user.role === 'admin';
        });

        const userName = computed(() => {
            return auth.user ? auth.user.name : '';
        });

        // ========================================
        // Return Public API
        // ========================================

        return {
            // State
            appReady,
            auth,
            loginForm,

            // Computed
            isAdmin,
            userName,

            // Methods
            handleLogin,
            handleLogout
        };
    },

    // ========================================
    // Template
    // ========================================
    template: `
        <div class="app-container">
            <!-- Navigation Bar -->
            <nav class="navbar">
                <div class="container">
                    <div class="navbar-content">
                        <span class="logo">QCI Equipment Status</span>
                        <div class="nav-links">
                            <template v-if="auth.isAuthenticated">
                                <span class="user-info">{{ userName }}</span>
                                <button
                                    class="btn btn-outline btn-sm"
                                    @click="handleLogout"
                                    :disabled="auth.loading"
                                >
                                    Logout
                                </button>
                            </template>
                        </div>
                    </div>
                </div>
            </nav>

            <!-- Main Content Area -->
            <main class="main-content">
                <div class="container">
                    <!-- Loading State (checking auth) -->
                    <template v-if="!appReady">
                        <div class="card" style="text-align: center; padding: 60px 20px;">
                            <div class="loading-spinner-inline"></div>
                            <p style="margin-top: 20px; color: #666;">Loading...</p>
                        </div>
                    </template>

                    <!-- Login Form (not authenticated) -->
                    <template v-else-if="!auth.isAuthenticated">
                        <div class="login-container">
                            <div class="card login-card">
                                <div class="card-header">
                                    <h2>Login</h2>
                                    <p>Sign in to access the equipment dashboard</p>
                                </div>

                                <form @submit.prevent="handleLogin" class="login-form">
                                    <!-- Error Message -->
                                    <div v-if="loginForm.error" class="alert alert-error">
                                        {{ loginForm.error }}
                                    </div>

                                    <!-- Username Field -->
                                    <div class="form-group">
                                        <label for="username">Username</label>
                                        <input
                                            type="text"
                                            id="username"
                                            v-model="loginForm.username"
                                            class="form-control"
                                            placeholder="Enter your username"
                                            autocomplete="username"
                                            :disabled="loginForm.submitting"
                                            autofocus
                                        />
                                    </div>

                                    <!-- Password Field -->
                                    <div class="form-group">
                                        <label for="password">Password</label>
                                        <input
                                            type="password"
                                            id="password"
                                            v-model="loginForm.password"
                                            class="form-control"
                                            placeholder="Enter your password"
                                            autocomplete="current-password"
                                            :disabled="loginForm.submitting"
                                        />
                                    </div>

                                    <!-- Submit Button -->
                                    <button
                                        type="submit"
                                        class="btn btn-primary btn-block"
                                        :disabled="loginForm.submitting"
                                    >
                                        <template v-if="loginForm.submitting">
                                            <span class="loading-spinner-inline loading-spinner-sm"></span>
                                            Signing in...
                                        </template>
                                        <template v-else>
                                            Sign In
                                        </template>
                                    </button>
                                </form>
                            </div>
                        </div>
                    </template>

                    <!-- Dashboard Content (authenticated) -->
                    <template v-else>
                        <div class="page-header">
                            <h1>Equipment Status Dashboard</h1>
                            <p>Welcome, {{ userName }}</p>
                        </div>

                        <div class="card">
                            <p style="text-align: center; color: #666; padding: 40px 20px;">
                                Dashboard components will be implemented in Milestone 3.
                                <br><br>
                                <strong>API endpoints available:</strong>
                                <br>
                                GET /api/tools - List tools<br>
                                GET /api/tools/:id - Tool details<br>
                                POST /api/tools/:id/status - Update status<br>
                                GET /api/tools/:id/history - Status history
                            </p>
                        </div>
                    </template>
                </div>
            </main>

            <!-- Footer -->
            <footer class="footer">
                <div class="container">
                    QCI Equipment Status Dashboard
                </div>
            </footer>
        </div>
    `
});

// Mount the application
app.mount('#app');
