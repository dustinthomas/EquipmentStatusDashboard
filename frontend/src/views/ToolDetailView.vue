<script setup>
import { onMounted, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToolDetailStore } from '@/stores/toolDetail'
import StatusBadge from '@/components/common/StatusBadge.vue'
import StatusUpdateModal from '@/components/modals/StatusUpdateModal.vue'

const route = useRoute()
const router = useRouter()
const toolDetailStore = useToolDetailStore()

const toolId = computed(() => route.params.id)

onMounted(() => {
    toolDetailStore.fetchTool(toolId.value)
})

// Watch for route changes
watch(() => route.params.id, (newId) => {
    if (newId) {
        toolDetailStore.fetchTool(newId)
    }
})

function navigateBack() {
    router.push('/vue')
}

function navigateToHistory() {
    router.push(`/vue/tools/${toolId.value}/history`)
}

function formatDate(dateStr) {
    if (!dateStr) return '-'
    try {
        const date = new Date(dateStr)
        return date.toLocaleString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: 'numeric',
            minute: '2-digit'
        })
    } catch {
        return dateStr
    }
}
</script>

<template>
    <div class="tool-detail-view">
        <!-- Back link -->
        <a href="/vue" class="back-link" @click.prevent="navigateBack">
            &#8592; Back to Dashboard
        </a>

        <!-- Loading state -->
        <div v-if="toolDetailStore.loading" class="loading-container">
            <div class="loading-spinner"></div>
            <p>Loading tool details...</p>
        </div>

        <!-- Error state -->
        <div v-else-if="toolDetailStore.error" class="alert alert-error">
            {{ toolDetailStore.error }}
            <button class="btn btn-secondary btn-sm mt-16" @click="navigateBack">
                Return to Dashboard
            </button>
        </div>

        <!-- Tool detail content -->
        <div v-else-if="toolDetailStore.tool" class="tool-detail">
            <!-- Header card -->
            <div class="card tool-detail-header">
                <div class="tool-detail-title-row">
                    <div>
                        <h1 class="tool-detail-name">{{ toolDetailStore.tool.name }}</h1>
                        <p class="tool-detail-subtitle">
                            <span class="tool-detail-area">{{ toolDetailStore.tool.area }}</span>
                            <span v-if="toolDetailStore.tool.bay" class="tool-detail-bay">
                                / {{ toolDetailStore.tool.bay }}
                            </span>
                            <span v-if="toolDetailStore.tool.criticality" class="tool-detail-criticality">
                                &bull; {{ toolDetailStore.tool.criticality }} criticality
                            </span>
                        </p>
                    </div>
                    <StatusBadge :status="toolDetailStore.tool.state" size="large" />
                </div>
            </div>

            <!-- Status details card -->
            <div class="card tool-detail-status">
                <h2 class="card-section-title">Current Status Details</h2>

                <div class="tool-detail-grid">
                    <div class="detail-item">
                        <span class="detail-label">Issue Description</span>
                        <span class="detail-value">
                            {{ toolDetailStore.tool.issue_description || 'None' }}
                        </span>
                    </div>

                    <div class="detail-item">
                        <span class="detail-label">Comment</span>
                        <span class="detail-value">
                            {{ toolDetailStore.tool.comment || 'None' }}
                        </span>
                    </div>

                    <div class="detail-item" v-if="toolDetailStore.tool.state !== 'UP'">
                        <span class="detail-label">ETA to Up</span>
                        <span class="detail-value">
                            {{ toolDetailStore.tool.eta_to_up
                                ? formatDate(toolDetailStore.tool.eta_to_up)
                                : 'Not specified' }}
                        </span>
                    </div>

                    <div class="detail-item">
                        <span class="detail-label">Last Updated</span>
                        <span class="detail-value">
                            {{ formatDate(toolDetailStore.tool.updated_at) }}
                        </span>
                    </div>

                    <div class="detail-item">
                        <span class="detail-label">Last Updated By</span>
                        <span class="detail-value">
                            {{ toolDetailStore.tool.updated_by || 'Unknown' }}
                        </span>
                    </div>
                </div>

                <!-- Action buttons -->
                <div class="tool-detail-actions">
                    <button
                        class="btn btn-primary"
                        @click="toolDetailStore.openStatusForm()"
                    >
                        Update Status
                    </button>
                    <button
                        class="btn btn-secondary"
                        @click="navigateToHistory"
                    >
                        View History
                    </button>
                </div>
            </div>
        </div>

        <!-- Status Update Modal -->
        <StatusUpdateModal
            v-if="toolDetailStore.statusForm.visible"
            :tool-id="toolId"
        />
    </div>
</template>

<style scoped>
.tool-detail-view {
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

.loading-container {
    text-align: center;
    padding: 48px;
}

.loading-container p {
    margin-top: 16px;
    color: #666;
}

.tool-detail {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.tool-detail-header {
    padding: 24px;
}

.tool-detail-title-row {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    flex-wrap: wrap;
}

.tool-detail-name {
    font-size: 1.75rem;
    font-weight: 600;
    color: var(--qci-dark-navy);
    margin: 0;
}

.tool-detail-subtitle {
    margin-top: 8px;
    color: #666;
    font-size: 0.95rem;
    margin-bottom: 0;
}

.tool-detail-area {
    font-weight: 500;
}

.tool-detail-bay,
.tool-detail-criticality {
    margin-left: 4px;
}

.tool-detail-status {
    padding: 24px;
}

.card-section-title {
    font-size: 1.1rem;
    font-weight: 600;
    color: var(--qci-dark-navy);
    margin: 0 0 20px 0;
    padding-bottom: 12px;
    border-bottom: 1px solid var(--border-color);
}

.tool-detail-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
}

.detail-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.detail-label {
    font-size: 0.8rem;
    font-weight: 500;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 0.02em;
}

.detail-value {
    font-size: 1rem;
    color: var(--qci-body-text);
}

.tool-detail-actions {
    display: flex;
    gap: 12px;
    flex-wrap: wrap;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid var(--border-color);
}
</style>
