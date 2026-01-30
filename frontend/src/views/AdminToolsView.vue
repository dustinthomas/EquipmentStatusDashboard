<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminStore } from '@/stores/admin'
import EmptyState from '@/components/common/EmptyState.vue'
import ToolFormModal from '@/components/modals/ToolFormModal.vue'

const router = useRouter()
const adminStore = useAdminStore()

onMounted(() => {
    adminStore.switchTab('tools')
    if (adminStore.tools.items.length === 0) {
        adminStore.fetchTools()
    }
})

function navigateToUsers() {
    router.push('/admin/users')
}

function getCriticalityClass(criticality) {
    return `criticality-${criticality}`
}
</script>

<template>
    <div class="admin-view">
        <div class="page-header">
            <h1>Admin Panel</h1>
            <p>Manage tools and users</p>
        </div>

        <!-- Tab navigation -->
        <div class="admin-tabs">
            <button
                class="admin-tab admin-tab-active"
            >
                Tools
            </button>
            <button
                class="admin-tab"
                @click="navigateToUsers"
            >
                Users
            </button>
        </div>

        <!-- Error message -->
        <div v-if="adminStore.tools.error" class="alert alert-error">
            {{ adminStore.tools.error }}
        </div>

        <!-- Toolbar -->
        <div class="card admin-toolbar">
            <div class="admin-toolbar-row">
                <div class="admin-search-group">
                    <input
                        type="text"
                        v-model="adminStore.tools.search"
                        class="form-input admin-search-input"
                        placeholder="Search tools..."
                    />
                </div>
                <button class="btn btn-primary" @click="adminStore.openAddToolModal()">
                    + Add Tool
                </button>
            </div>
        </div>

        <!-- Tools table -->
        <div class="card admin-table-card">
            <div class="table-container">
                <table class="table admin-tools-table">
                    <thead>
                        <tr>
                            <th
                                class="sortable-header"
                                :class="adminStore.getToolSortClass('name')"
                                @click="adminStore.handleToolSortClick('name')"
                            >
                                Name
                                <span class="sort-indicator"></span>
                            </th>
                            <th
                                class="sortable-header"
                                :class="adminStore.getToolSortClass('area')"
                                @click="adminStore.handleToolSortClick('area')"
                            >
                                Area
                                <span class="sort-indicator"></span>
                            </th>
                            <th>Bay</th>
                            <th
                                class="sortable-header"
                                :class="adminStore.getToolSortClass('criticality')"
                                @click="adminStore.handleToolSortClick('criticality')"
                            >
                                Criticality
                                <span class="sort-indicator"></span>
                            </th>
                            <th
                                class="sortable-header"
                                :class="adminStore.getToolSortClass('is_active')"
                                @click="adminStore.handleToolSortClick('is_active')"
                            >
                                Active
                                <span class="sort-indicator"></span>
                            </th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Loading state -->
                        <tr v-if="adminStore.tools.loading">
                            <td colspan="6" class="loading-cell">
                                <div class="loading-spinner"></div>
                                <span>Loading tools...</span>
                            </td>
                        </tr>

                        <!-- Empty state -->
                        <tr v-else-if="adminStore.filteredTools.length === 0">
                            <td colspan="6">
                                <EmptyState
                                    title="No tools found"
                                    :message="adminStore.tools.search
                                        ? 'Try adjusting your search'
                                        : 'Click Add Tool to create your first tool'"
                                />
                            </td>
                        </tr>

                        <!-- Tool rows -->
                        <tr
                            v-else
                            v-for="tool in adminStore.filteredTools"
                            :key="tool.id"
                            :class="{ 'admin-row-inactive': !tool.is_active }"
                        >
                            <td class="tool-name">{{ tool.name }}</td>
                            <td>{{ tool.area }}</td>
                            <td>{{ tool.bay || '-' }}</td>
                            <td>
                                <span
                                    class="criticality-badge"
                                    :class="getCriticalityClass(tool.criticality)"
                                >
                                    {{ tool.criticality }}
                                </span>
                            </td>
                            <td>
                                <span
                                    class="active-badge"
                                    :class="tool.is_active ? 'active-badge-yes' : 'active-badge-no'"
                                >
                                    {{ tool.is_active ? 'Yes' : 'No' }}
                                </span>
                            </td>
                            <td class="admin-actions-cell">
                                <button
                                    class="btn btn-secondary btn-sm"
                                    @click="adminStore.openEditToolModal(tool)"
                                >
                                    Edit
                                </button>
                                <button
                                    class="btn btn-sm"
                                    :class="tool.is_active ? 'btn-outline-danger' : 'btn-outline-success'"
                                    @click="adminStore.toggleToolActive(tool)"
                                >
                                    {{ tool.is_active ? 'Deactivate' : 'Activate' }}
                                </button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Footer with count -->
            <div class="admin-table-footer" v-if="!adminStore.tools.loading && adminStore.filteredTools.length > 0">
                Showing <strong>{{ adminStore.filteredTools.length }}</strong>
                of <strong>{{ adminStore.tools.items.length }}</strong> tools
            </div>
        </div>

        <!-- Tool Form Modal -->
        <ToolFormModal v-if="adminStore.toolModal.visible" />
    </div>
</template>

<style scoped>
.admin-view {
    padding-bottom: 24px;
}

.page-header {
    margin-bottom: 24px;
}

.page-header h1 {
    margin-bottom: 8px;
}

.page-header p {
    color: #666;
    margin: 0;
}

.admin-tabs {
    display: flex;
    gap: 0;
    margin-bottom: 20px;
    background-color: var(--qci-white);
    border-radius: var(--radius-md);
    overflow: hidden;
    box-shadow: var(--shadow-sm);
}

.admin-tab {
    flex: 1;
    padding: 14px 24px;
    border: none;
    background-color: var(--qci-white);
    color: var(--qci-body-text);
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color var(--transition-fast), color var(--transition-fast);
    border-bottom: 3px solid transparent;
}

.admin-tab:hover {
    background-color: var(--qci-light-grey);
}

.admin-tab-active {
    background-color: var(--qci-light-grey);
    color: var(--qci-dark-navy);
    border-bottom-color: var(--qci-dark-navy);
}

.admin-toolbar {
    margin-bottom: 20px;
    padding: 16px 20px;
}

.admin-toolbar-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 16px;
    flex-wrap: wrap;
}

.admin-search-group {
    flex: 1;
    min-width: 200px;
    max-width: 400px;
}

.admin-search-input {
    width: 100%;
}

.admin-table-card {
    padding: 0;
    overflow: hidden;
}

.table-container {
    overflow-x: auto;
}

.admin-tools-table {
    margin-bottom: 0;
}

.admin-tools-table th {
    white-space: nowrap;
}

.tool-name {
    font-weight: 500;
}

.admin-row-inactive {
    opacity: 0.6;
    background-color: rgba(128, 128, 128, 0.05);
}

.admin-row-inactive:hover {
    opacity: 0.8;
    background-color: rgba(128, 128, 128, 0.1);
}

.admin-actions-cell {
    white-space: nowrap;
}

.admin-actions-cell .btn {
    margin-right: 4px;
}

.admin-actions-cell .btn:last-child {
    margin-right: 0;
}

.loading-cell {
    text-align: center;
    padding: 48px !important;
}

.loading-cell span {
    margin-left: 12px;
    color: #666;
}

.admin-table-footer {
    padding: 12px 16px;
    background-color: var(--qci-light-grey);
    border-top: 1px solid var(--border-color);
    font-size: 0.875rem;
    color: #666;
}

/* Sortable headers */
.sortable-header {
    cursor: pointer;
    user-select: none;
    transition: background-color var(--transition-fast);
}

.sortable-header:hover {
    background-color: var(--qci-light-navy);
}

.sort-indicator {
    display: inline-block;
    margin-left: 6px;
    opacity: 0.4;
    font-size: 0.75rem;
}

.sort-indicator::after {
    content: '\2195';
}

.sortable-header.sorted-asc,
.sortable-header.sorted-desc {
    background-color: var(--qci-light-navy);
}

.sortable-header.sorted-asc .sort-indicator,
.sortable-header.sorted-desc .sort-indicator {
    opacity: 1;
}

.sortable-header.sorted-asc .sort-indicator::after {
    content: '\2191';
}

.sortable-header.sorted-desc .sort-indicator::after {
    content: '\2193';
}
</style>
