<script setup>
import { useRouter } from 'vue-router'
import { useDashboardStore } from '@/stores/dashboard'
import StatusBadge from '@/components/common/StatusBadge.vue'
import LoadingSkeleton from '@/components/common/LoadingSkeleton.vue'
import EmptyState from '@/components/common/EmptyState.vue'

const router = useRouter()
const dashboardStore = useDashboardStore()

function handleToolClick(tool) {
    router.push(`/vue/tools/${tool.id}`)
}

function formatDate(dateStr) {
    if (!dateStr) return '-'
    try {
        const date = new Date(dateStr)
        return date.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        })
    } catch {
        return dateStr
    }
}

function getRowStatusClass(state) {
    const classMap = {
        'UP': 'tool-row-status-up',
        'UP_WITH_ISSUES': 'tool-row-status-up-with-issues',
        'MAINTENANCE': 'tool-row-status-maintenance',
        'DOWN': 'tool-row-status-down'
    }
    return classMap[state] || ''
}

function isStale(tool) {
    return tool.is_stale === true
}
</script>

<template>
    <div class="card dashboard-card">
        <div class="table-container">
            <table class="table dashboard-table">
                <thead>
                    <tr>
                        <th
                            class="sortable-header"
                            :class="dashboardStore.getSortClass('name')"
                            @click="dashboardStore.handleSortClick('name')"
                        >
                            Tool Name
                            <span class="sort-indicator"></span>
                        </th>
                        <th
                            class="sortable-header"
                            :class="dashboardStore.getSortClass('area')"
                            @click="dashboardStore.handleSortClick('area')"
                        >
                            Area
                            <span class="sort-indicator"></span>
                        </th>
                        <th
                            class="sortable-header"
                            :class="dashboardStore.getSortClass('state')"
                            @click="dashboardStore.handleSortClick('state')"
                        >
                            Status
                            <span class="sort-indicator"></span>
                        </th>
                        <th>Issue</th>
                        <th
                            class="sortable-header"
                            :class="dashboardStore.getSortClass('eta')"
                            @click="dashboardStore.handleSortClick('eta')"
                        >
                            ETA to Up
                            <span class="sort-indicator"></span>
                        </th>
                        <th
                            class="sortable-header"
                            :class="dashboardStore.getSortClass('updated')"
                            @click="dashboardStore.handleSortClick('updated')"
                        >
                            Last Updated
                            <span class="sort-indicator"></span>
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <!-- Loading state -->
                    <template v-if="dashboardStore.loading">
                        <tr v-for="i in 5" :key="i">
                            <td colspan="6">
                                <LoadingSkeleton type="row" />
                            </td>
                        </tr>
                    </template>

                    <!-- Empty state -->
                    <tr v-else-if="dashboardStore.tools.length === 0">
                        <td colspan="6">
                            <EmptyState
                                title="No tools found"
                                :message="dashboardStore.hasActiveFilters
                                    ? 'Try adjusting your filters'
                                    : 'No equipment has been added yet'"
                            >
                                <button
                                    v-if="dashboardStore.hasActiveFilters"
                                    class="btn btn-secondary btn-sm mt-16"
                                    @click="dashboardStore.clearFilters()"
                                >
                                    Clear Filters
                                </button>
                            </EmptyState>
                        </td>
                    </tr>

                    <!-- Tool rows -->
                    <tr
                        v-else
                        v-for="tool in dashboardStore.tools"
                        :key="tool.id"
                        class="tool-row"
                        :class="[getRowStatusClass(tool.state), { stale: isStale(tool) }]"
                        @click="handleToolClick(tool)"
                    >
                        <td class="tool-name">{{ tool.name }}</td>
                        <td>{{ tool.area }}</td>
                        <td>
                            <StatusBadge :status="tool.state" />
                        </td>
                        <td class="issue-cell" :title="tool.issue_description">
                            {{ tool.issue_description || '-' }}
                        </td>
                        <td>
                            <span v-if="tool.eta_to_up">
                                {{ formatDate(tool.eta_to_up) }}
                            </span>
                            <span v-else>-</span>
                        </td>
                        <td>
                            <span :class="{ 'stale-indicator': isStale(tool) }">
                                {{ formatDate(tool.updated_at) }}
                            </span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Footer with count -->
        <div class="table-footer" v-if="!dashboardStore.loading && dashboardStore.tools.length > 0">
            Showing <strong>{{ dashboardStore.meta.filtered }}</strong>
            of <strong>{{ dashboardStore.meta.total }}</strong> tools
        </div>
    </div>
</template>

<style scoped>
.dashboard-card {
    padding: 0;
    overflow: hidden;
}

.table-container {
    overflow-x: auto;
}

.dashboard-table {
    margin-bottom: 0;
}

.dashboard-table th {
    white-space: nowrap;
}

.tool-row {
    cursor: pointer;
    transition: background-color var(--transition-fast);
    border-left: 3px solid transparent;
}

.tool-row:hover {
    background-color: var(--hover-bg);
}

.tool-name {
    font-weight: 500;
}

.issue-cell {
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

/* Status row colors with left border */
.tool-row-status-up {
    border-left-color: var(--status-up);
    background-color: rgba(46, 204, 113, 0.03);
}

.tool-row-status-up:hover {
    background-color: rgba(46, 204, 113, 0.08);
}

.tool-row-status-up-with-issues {
    border-left-color: var(--status-up-with-issues);
    background-color: rgba(243, 156, 18, 0.05);
}

.tool-row-status-up-with-issues:hover {
    background-color: rgba(243, 156, 18, 0.1);
}

.tool-row-status-maintenance {
    border-left-color: var(--status-maintenance);
    background-color: rgba(230, 126, 34, 0.05);
}

.tool-row-status-maintenance:hover {
    background-color: rgba(230, 126, 34, 0.1);
}

.tool-row-status-down {
    border-left-color: var(--status-down);
    background-color: rgba(231, 76, 60, 0.05);
}

.tool-row-status-down:hover {
    background-color: rgba(231, 76, 60, 0.1);
}

/* Stale row styling */
.tool-row.stale {
    opacity: 0.7;
}

.stale-indicator {
    display: inline-flex;
    align-items: center;
    gap: 4px;
}

.stale-indicator::before {
    content: '\231A';
    font-size: 0.9em;
    opacity: 0.6;
}

/* Sortable headers */
.sortable-header {
    cursor: pointer;
    user-select: none;
    transition: background-color var(--transition-fast);
    position: relative;
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

.table-footer {
    padding: 12px 16px;
    background-color: var(--qci-light-grey);
    border-top: 1px solid var(--border-color);
    font-size: 0.875rem;
    color: #666;
}
</style>
