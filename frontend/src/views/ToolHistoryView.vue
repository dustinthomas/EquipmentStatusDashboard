<script setup>
import { onMounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToolDetailStore } from '@/stores/toolDetail'
import StatusBadge from '@/components/common/StatusBadge.vue'
import EmptyState from '@/components/common/EmptyState.vue'

const route = useRoute()
const router = useRouter()
const toolDetailStore = useToolDetailStore()

const toolId = computed(() => route.params.id)

onMounted(() => {
    toolDetailStore.fetchHistory(toolId.value)
})

watch(() => route.params.id, (newId) => {
    if (newId) {
        toolDetailStore.fetchHistory(newId)
    }
})

function navigateBack() {
    router.push(`/vue/tools/${toolId.value}`)
}

function formatTimestamp(dateStr) {
    if (!dateStr) return '-'
    try {
        const date = new Date(dateStr)
        return date.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            second: '2-digit'
        })
    } catch {
        return dateStr
    }
}
</script>

<template>
    <div class="tool-history-view">
        <!-- Back link -->
        <a :href="`/vue/tools/${toolId}`" class="back-link" @click.prevent="navigateBack">
            &#8592; Back to Tool Details
        </a>

        <!-- Header -->
        <div class="card tool-history-header">
            <h1 class="tool-history-title">Status History</h1>
            <p class="tool-history-subtitle">
                {{ toolDetailStore.history.toolName || 'Loading...' }}
            </p>
        </div>

        <!-- Date filter card -->
        <div class="card filter-card">
            <form @submit.prevent="toolDetailStore.applyHistoryFilters(toolId)" class="filter-form">
                <div class="filter-row">
                    <div class="filter-group">
                        <label class="filter-label">From Date</label>
                        <input
                            type="date"
                            v-model="toolDetailStore.history.fromDate"
                            class="form-input"
                        />
                    </div>

                    <div class="filter-group">
                        <label class="filter-label">To Date</label>
                        <input
                            type="date"
                            v-model="toolDetailStore.history.toDate"
                            class="form-input"
                        />
                    </div>

                    <div class="filter-group filter-group-buttons">
                        <button type="submit" class="btn btn-primary btn-sm">
                            Apply
                        </button>
                        <button
                            type="button"
                            class="btn btn-secondary btn-sm"
                            @click="toolDetailStore.clearHistoryFilters(toolId)"
                            :disabled="!toolDetailStore.hasActiveHistoryFilters"
                        >
                            Clear
                        </button>
                        <button
                            type="button"
                            class="btn btn-outline btn-sm"
                            @click="toolDetailStore.exportHistoryCsv(toolId)"
                            :disabled="toolDetailStore.history.events.length === 0"
                        >
                            Export CSV
                        </button>
                    </div>
                </div>
            </form>
        </div>

        <!-- Error message -->
        <div v-if="toolDetailStore.history.error" class="alert alert-error">
            {{ toolDetailStore.history.error }}
        </div>

        <!-- History table -->
        <div class="card history-card">
            <div class="table-container">
                <table class="table history-table">
                    <thead>
                        <tr>
                            <th>Timestamp</th>
                            <th>Status</th>
                            <th>Issue</th>
                            <th>Comment</th>
                            <th>ETA to Up</th>
                            <th>Updated By</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Loading state -->
                        <tr v-if="toolDetailStore.history.loading">
                            <td colspan="6" class="loading-cell">
                                <div class="loading-spinner"></div>
                                <span>Loading history...</span>
                            </td>
                        </tr>

                        <!-- Empty state -->
                        <tr v-else-if="toolDetailStore.history.events.length === 0">
                            <td colspan="6">
                                <EmptyState
                                    title="No history found"
                                    :message="toolDetailStore.hasActiveHistoryFilters
                                        ? 'Try adjusting the date range'
                                        : 'No status changes have been recorded yet'"
                                />
                            </td>
                        </tr>

                        <!-- History rows -->
                        <tr v-else v-for="event in toolDetailStore.history.events" :key="event.id">
                            <td class="history-timestamp">
                                {{ formatTimestamp(event.created_at) }}
                            </td>
                            <td>
                                <StatusBadge :status="event.state" />
                            </td>
                            <td class="history-issue" :title="event.issue_description">
                                {{ event.issue_description || '-' }}
                            </td>
                            <td class="history-comment" :title="event.comment">
                                {{ event.comment || '-' }}
                            </td>
                            <td>
                                {{ event.eta_to_up ? formatTimestamp(event.eta_to_up) : '-' }}
                            </td>
                            <td>{{ event.created_by || 'Unknown' }}</td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Footer with count -->
            <div class="history-footer" v-if="!toolDetailStore.history.loading && toolDetailStore.history.events.length > 0">
                <span class="history-count">{{ toolDetailStore.history.events.length }}</span>
                status change{{ toolDetailStore.history.events.length !== 1 ? 's' : '' }} found
            </div>
        </div>
    </div>
</template>

<style scoped>
.tool-history-view {
    padding-bottom: 24px;
}

.back-link {
    display: inline-flex;
    align-items: center;
    color: var(--qci-dark-navy);
    text-decoration: none;
    font-size: 0.95rem;
    margin-bottom: 20px;
    transition: color var(--transition-fast);
}

.back-link:hover {
    color: var(--qci-light-navy);
    text-decoration: underline;
}

.tool-history-header {
    padding: 24px;
    margin-bottom: 20px;
}

.tool-history-title {
    font-size: 1.5rem;
    font-weight: 600;
    color: var(--qci-dark-navy);
    margin: 0 0 4px 0;
}

.tool-history-subtitle {
    color: #666;
    font-size: 1rem;
    margin: 0;
}

.filter-card {
    margin-bottom: 20px;
    padding: 16px 20px;
}

.filter-form {
    width: 100%;
}

.filter-row {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    align-items: flex-end;
}

.filter-group {
    display: flex;
    flex-direction: column;
    min-width: 140px;
}

.filter-group-buttons {
    flex-direction: row;
    gap: 8px;
}

.filter-label {
    font-size: 0.8rem;
    font-weight: 500;
    color: var(--qci-dark-navy);
    margin-bottom: 4px;
}

.history-card {
    padding: 0;
    overflow: hidden;
}

.table-container {
    overflow-x: auto;
}

.history-table {
    margin-bottom: 0;
}

.history-table th {
    white-space: nowrap;
}

.history-timestamp {
    white-space: nowrap;
    font-family: monospace;
    font-size: 0.85rem;
}

.history-issue,
.history-comment {
    max-width: 180px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.loading-cell {
    text-align: center;
    padding: 48px !important;
}

.loading-cell span {
    margin-left: 12px;
    color: #666;
}

.history-footer {
    padding: 12px 16px;
    background-color: var(--qci-light-grey);
    border-top: 1px solid var(--border-color);
    font-size: 0.875rem;
    color: #666;
}

.history-count {
    font-weight: 500;
}
</style>
