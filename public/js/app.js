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
        // Application ready state
        const appReady = ref(true);

        // Placeholder for future auth and dashboard state
        // These will be implemented in subsequent units

        return {
            appReady
        };
    },

    // Template rendered once Vue mounts
    template: `
        <div class="app-container">
            <!-- Navigation Bar -->
            <nav class="navbar">
                <div class="container">
                    <div class="navbar-content">
                        <span class="logo">QCI Equipment Status</span>
                        <div class="nav-links">
                            <!-- Auth and nav links will be added in Unit 2.2 -->
                        </div>
                    </div>
                </div>
            </nav>

            <!-- Main Content Area -->
            <main class="main-content">
                <div class="container">
                    <!-- Placeholder content until dashboard is implemented -->
                    <div class="page-header">
                        <h1>Equipment Status Dashboard</h1>
                        <p>Vue.js frontend initialized successfully</p>
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
