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
        // Dashboard State
        // ========================================
        const dashboard = reactive({
            tools: [],
            meta: {
                total: 0,
                filtered: 0,
                areas: [],
                states: []
            },
            loading: false,
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

                // Clear dashboard data on logout
                dashboard.tools = [];
                dashboard.meta = { total: 0, filtered: 0, areas: [], states: [] };
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
        // Dashboard Methods
        // ========================================

        /**
         * Fetch tools from the API.
         * Calls /api/tools with optional query parameters.
         */
        async function fetchTools() {
            dashboard.loading = true;
            dashboard.error = null;

            try {
                const response = await fetch('/api/tools', {
                    method: 'GET',
                    credentials: 'same-origin',
                    headers: {
                        'Accept': 'application/json'
                    }
                });

                if (response.ok) {
                    const data = await response.json();
                    dashboard.tools = data.tools || [];
                    dashboard.meta = data.meta || { total: 0, filtered: 0, areas: [], states: [] };
                } else if (response.status === 401) {
                    // Session expired - redirect to login
                    auth.isAuthenticated = false;
                    auth.user = null;
                    dashboard.error = 'Session expired. Please log in again.';
                } else {
                    const errorData = await response.json().catch(() => ({}));
                    dashboard.error = errorData.error || 'Failed to load tools';
                }
            } catch (error) {
                console.error('Failed to fetch tools:', error);
                dashboard.error = 'Unable to connect to server. Please try again.';
            } finally {
                dashboard.loading = false;
            }
        }

        /**
         * Handle clicking on a tool row.
         * Prepares for tool detail view (to be implemented in Unit 4.1).
         * @param {Object} tool - The tool object that was clicked
         */
        function handleToolClick(tool) {
            // Tool detail view will be implemented in Unit 4.1
            console.log('Tool clicked:', tool.id, tool.name);
        }

        /**
         * Get CSS class for table row based on tool status.
         * @param {string} state - The tool's current state
         * @returns {string} CSS class name
         */
        function getRowStatusClass(state) {
            const classes = {
                'UP': 'tool-row-status-up',
                'UP_WITH_ISSUES': 'tool-row-status-up-with-issues',
                'MAINTENANCE': 'tool-row-status-maintenance',
                'DOWN': 'tool-row-status-down'
            };
            return classes[state] || '';
        }

        // ========================================
        // Lifecycle
        // ========================================

        // Check authentication status when app mounts
        onMounted(() => {
            checkAuth();
        });

        // Watch for authentication changes to fetch tools
        watch(() => auth.isAuthenticated, (isAuthenticated) => {
            if (isAuthenticated) {
                fetchTools();
            }
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
            dashboard,

            // Computed
            isAdmin,
            userName,

            // Methods
            handleLogin,
            handleLogout,
            fetchTools,
            handleToolClick,
            getRowStatusClass
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
                            <p v-if="dashboard.meta.total > 0">
                                Showing {{ dashboard.meta.filtered }} of {{ dashboard.meta.total }} tools
                            </p>
                        </div>

                        <!-- Error Message -->
                        <div v-if="dashboard.error" class="alert alert-error">
                            {{ dashboard.error }}
                            <button class="btn btn-sm btn-secondary" style="margin-left: 10px;" @click="fetchTools">
                                Retry
                            </button>
                        </div>

                        <!-- Loading State -->
                        <div v-if="dashboard.loading" class="card" style="text-align: center; padding: 60px 20px;">
                            <div class="loading-spinner-inline"></div>
                            <p style="margin-top: 20px; color: #666;">Loading tools...</p>
                        </div>

                        <!-- Tools Table -->
                        <div v-else class="card dashboard-card">
                            <!-- Empty State -->
                            <div v-if="dashboard.tools.length === 0" style="text-align: center; padding: 60px 20px;">
                                <p style="color: #666; font-size: 1.1rem;">No tools found</p>
                                <p style="color: #999; font-size: 0.9rem; margin-top: 10px;">
                                    There are no equipment tools to display.
                                </p>
                            </div>

                            <!-- Table -->
                            <div v-else class="table-container">
                                <table class="table dashboard-table">
                                    <thead>
                                        <tr>
                                            <th>Name</th>
                                            <th>Area</th>
                                            <th>Status</th>
                                            <th>Issue</th>
                                            <th>ETA</th>
                                            <th>Updated</th>
                                            <th>Updated By</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr
                                            v-for="tool in dashboard.tools"
                                            :key="tool.id"
                                            class="tool-row"
                                            :class="getRowStatusClass(tool.state)"
                                            @click="handleToolClick(tool)"
                                        >
                                            <td class="tool-name">{{ tool.name }}</td>
                                            <td>{{ tool.area }}</td>
                                            <td>
                                                <span class="status-badge" :class="tool.state_class">
                                                    {{ tool.state_display }}
                                                </span>
                                            </td>
                                            <td class="issue-cell" :title="tool.issue_description">
                                                {{ tool.issue_description || '-' }}
                                            </td>
                                            <td>{{ tool.eta_to_up_formatted || '-' }}</td>
                                            <td>{{ tool.status_updated_at_formatted || '-' }}</td>
                                            <td>{{ tool.status_updated_by || '-' }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
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
