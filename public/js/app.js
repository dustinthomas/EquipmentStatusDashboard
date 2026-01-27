/**
 * QCI Equipment Status Dashboard - Vue 3 Application
 *
 * Single-file Vue application using CDN-loaded Vue 3.
 * No build step required - runs directly in the browser.
 */

const { createApp, ref, reactive, computed, onMounted, watch, nextTick } = Vue;

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
        // Filter State
        // ========================================
        const filters = reactive({
            state: '',
            area: '',
            search: ''
        });

        // ========================================
        // Sort State
        // ========================================
        const sort = reactive({
            column: 'state',   // Default sort by state (DOWN first)
            direction: 'asc'   // Default ascending
        });

        // Columns that can be sorted and their API field names
        const sortableColumns = {
            name: 'name',
            area: 'area',
            state: 'state',
            eta: 'eta',
            updated: 'updated'
        };

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
         * Build URL query string from filter and sort state.
         * @returns {string} Query string (including ? prefix if non-empty)
         */
        function buildFilterQueryString() {
            const params = new URLSearchParams();

            if (filters.state) {
                params.set('state', filters.state);
            }
            if (filters.area) {
                params.set('area', filters.area);
            }
            if (filters.search.trim()) {
                params.set('search', filters.search.trim());
            }

            // Add sort params (include even if defaults to maintain URL state)
            if (sort.column && sort.column !== 'state') {
                params.set('sort', sort.column);
            }
            if (sort.direction && sort.direction !== 'asc') {
                params.set('dir', sort.direction);
            }

            const queryString = params.toString();
            return queryString ? `?${queryString}` : '';
        }

        /**
         * Update browser URL with current filter state.
         * Uses replaceState to avoid creating history entries for each filter change.
         */
        function updateUrlWithFilters() {
            const queryString = buildFilterQueryString();
            const newUrl = window.location.pathname + queryString;
            window.history.replaceState({}, '', newUrl);
        }

        /**
         * Read filter and sort state from URL query parameters.
         * Called on app load to restore filters and sort from URL.
         */
        function readFiltersFromUrl() {
            const params = new URLSearchParams(window.location.search);

            filters.state = params.get('state') || '';
            filters.area = params.get('area') || '';
            filters.search = params.get('search') || '';

            // Read sort params (with defaults)
            sort.column = params.get('sort') || 'state';
            sort.direction = params.get('dir') || 'asc';
        }

        /**
         * Fetch tools from the API.
         * Calls /api/tools with filter query parameters.
         */
        async function fetchTools() {
            dashboard.loading = true;
            dashboard.error = null;

            try {
                const queryString = buildFilterQueryString();
                const response = await fetch(`/api/tools${queryString}`, {
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
         * Apply current filters and fetch tools.
         * Updates URL to reflect filter state.
         */
        function applyFilters() {
            updateUrlWithFilters();
            fetchTools();
        }

        /**
         * Clear all filters and fetch tools.
         * Resets URL to base path but preserves sort state.
         */
        function clearFilters() {
            filters.state = '';
            filters.area = '';
            filters.search = '';
            updateUrlWithFilters();
            fetchTools();
        }

        /**
         * Handle click on a sortable column header.
         * Toggles direction if same column, otherwise sorts ascending.
         * @param {string} column - The column to sort by
         */
        function handleSortClick(column) {
            if (!sortableColumns[column]) {
                return; // Not a sortable column
            }

            if (sort.column === column) {
                // Same column - toggle direction
                sort.direction = sort.direction === 'asc' ? 'desc' : 'asc';
            } else {
                // New column - set to ascending
                sort.column = column;
                sort.direction = 'asc';
            }

            updateUrlWithFilters();
            fetchTools();
        }

        /**
         * Check if a column is sortable.
         * @param {string} column - Column name to check
         * @returns {boolean} True if column can be sorted
         */
        function isSortable(column) {
            return !!sortableColumns[column];
        }

        /**
         * Check if a column is the currently sorted column.
         * @param {string} column - Column name to check
         * @returns {boolean} True if this is the active sort column
         */
        function isSortedBy(column) {
            return sort.column === column;
        }

        /**
         * Get the CSS class for sort indicator on a column header.
         * @param {string} column - Column name
         * @returns {string} CSS class for the sort indicator
         */
        function getSortClass(column) {
            if (!isSortedBy(column)) {
                return 'sortable';
            }
            return sort.direction === 'asc' ? 'sorted-asc' : 'sorted-desc';
        }

        /**
         * Check if any filters are currently active.
         * @returns {boolean} True if any filter is set
         */
        const hasActiveFilters = computed(() => {
            return filters.state !== '' || filters.area !== '' || filters.search.trim() !== '';
        });

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
            // Read filters from URL before checking auth
            readFiltersFromUrl();
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
            filters,
            sort,

            // Computed
            isAdmin,
            userName,
            hasActiveFilters,

            // Methods
            handleLogin,
            handleLogout,
            fetchTools,
            applyFilters,
            clearFilters,
            handleToolClick,
            getRowStatusClass,
            handleSortClick,
            isSortable,
            isSortedBy,
            getSortClass
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

                        <!-- Filter Card -->
                        <div class="card filter-card">
                            <form class="filter-form" @submit.prevent="applyFilters">
                                <div class="filter-row">
                                    <!-- State Filter -->
                                    <div class="filter-group">
                                        <label class="filter-label" for="filter-state">Status</label>
                                        <select
                                            id="filter-state"
                                            v-model="filters.state"
                                            class="form-control filter-select"
                                        >
                                            <option value="">All States</option>
                                            <option v-for="state in dashboard.meta.states" :key="state" :value="state">
                                                {{ state === 'UP' ? 'Up' : state === 'UP_WITH_ISSUES' ? 'Up with Issues' : state === 'MAINTENANCE' ? 'Maintenance' : state === 'DOWN' ? 'Down' : state }}
                                            </option>
                                        </select>
                                    </div>

                                    <!-- Area Filter -->
                                    <div class="filter-group">
                                        <label class="filter-label" for="filter-area">Area</label>
                                        <select
                                            id="filter-area"
                                            v-model="filters.area"
                                            class="form-control filter-select"
                                        >
                                            <option value="">All Areas</option>
                                            <option v-for="area in dashboard.meta.areas" :key="area" :value="area">
                                                {{ area }}
                                            </option>
                                        </select>
                                    </div>

                                    <!-- Search Input -->
                                    <div class="filter-group filter-group-search">
                                        <label class="filter-label" for="filter-search">Search</label>
                                        <input
                                            type="text"
                                            id="filter-search"
                                            v-model="filters.search"
                                            class="form-control filter-input"
                                            placeholder="Search by name..."
                                        />
                                    </div>

                                    <!-- Filter Buttons -->
                                    <div class="filter-group filter-group-buttons">
                                        <button type="submit" class="btn btn-primary" :disabled="dashboard.loading">
                                            Apply
                                        </button>
                                        <button
                                            type="button"
                                            class="btn btn-secondary"
                                            @click="clearFilters"
                                            :disabled="dashboard.loading || !hasActiveFilters"
                                        >
                                            Clear
                                        </button>
                                    </div>
                                </div>
                            </form>
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
                                <p v-if="hasActiveFilters" style="color: #999; font-size: 0.9rem; margin-top: 10px;">
                                    No tools match the current filters.
                                    <button class="btn btn-sm btn-secondary" style="margin-left: 8px;" @click="clearFilters">
                                        Clear Filters
                                    </button>
                                </p>
                                <p v-else style="color: #999; font-size: 0.9rem; margin-top: 10px;">
                                    There are no equipment tools to display.
                                </p>
                            </div>

                            <!-- Table -->
                            <div v-else class="table-container">
                                <table class="table dashboard-table">
                                    <thead>
                                        <tr>
                                            <th
                                                class="sortable-header"
                                                :class="getSortClass('name')"
                                                @click="handleSortClick('name')"
                                                title="Sort by name"
                                            >
                                                Name
                                                <span class="sort-indicator"></span>
                                            </th>
                                            <th
                                                class="sortable-header"
                                                :class="getSortClass('area')"
                                                @click="handleSortClick('area')"
                                                title="Sort by area"
                                            >
                                                Area
                                                <span class="sort-indicator"></span>
                                            </th>
                                            <th
                                                class="sortable-header"
                                                :class="getSortClass('state')"
                                                @click="handleSortClick('state')"
                                                title="Sort by status (Down first)"
                                            >
                                                Status
                                                <span class="sort-indicator"></span>
                                            </th>
                                            <th>Issue</th>
                                            <th
                                                class="sortable-header"
                                                :class="getSortClass('eta')"
                                                @click="handleSortClick('eta')"
                                                title="Sort by ETA"
                                            >
                                                ETA
                                                <span class="sort-indicator"></span>
                                            </th>
                                            <th
                                                class="sortable-header"
                                                :class="getSortClass('updated')"
                                                @click="handleSortClick('updated')"
                                                title="Sort by last updated"
                                            >
                                                Updated
                                                <span class="sort-indicator"></span>
                                            </th>
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
