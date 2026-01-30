<script setup>
import { useToolDetailStore } from '@/stores/toolDetail'
import StatusBadge from '@/components/common/StatusBadge.vue'

const props = defineProps({
    toolId: {
        type: [Number, String],
        required: true
    }
})

const emit = defineEmits(['updated'])

const toolDetailStore = useToolDetailStore()

async function handleSubmit() {
    const success = await toolDetailStore.submitStatusForm(props.toolId)
    if (success) {
        emit('updated')
        if (window.showToast) {
            window.showToast('Status updated successfully', 'success')
        }
    }
}
</script>

<template>
    <Teleport to="body">
        <div class="modal-overlay" @click.self="toolDetailStore.closeStatusForm()">
            <div class="modal">
                <div class="modal-header">
                    <h3 class="modal-title">Update Status</h3>
                    <button
                        class="modal-close"
                        @click="toolDetailStore.closeStatusForm()"
                        :disabled="toolDetailStore.statusForm.submitting"
                    >
                        &times;
                    </button>
                </div>

                <div class="modal-body">
                    <form @submit.prevent="handleSubmit">
                        <!-- Error message -->
                        <div v-if="toolDetailStore.statusForm.error" class="alert alert-error">
                            {{ toolDetailStore.statusForm.error }}
                        </div>

                        <!-- Status field -->
                        <div class="form-group">
                            <label class="form-label">
                                Status <span class="required">*</span>
                            </label>
                            <select
                                v-model="toolDetailStore.statusForm.state"
                                class="form-select"
                                :disabled="toolDetailStore.statusForm.submitting"
                            >
                                <option value="">Select status...</option>
                                <option
                                    v-for="state in toolDetailStore.validStates"
                                    :key="state.value"
                                    :value="state.value"
                                >
                                    {{ state.label }}
                                </option>
                            </select>
                            <div v-if="toolDetailStore.statusForm.state" class="status-preview">
                                <StatusBadge :status="toolDetailStore.statusForm.state" />
                            </div>
                        </div>

                        <!-- Issue description -->
                        <div class="form-group">
                            <label class="form-label">Issue Description</label>
                            <textarea
                                v-model="toolDetailStore.statusForm.issue_description"
                                class="form-textarea"
                                rows="2"
                                placeholder="Describe the issue..."
                                :disabled="toolDetailStore.statusForm.submitting"
                            ></textarea>
                        </div>

                        <!-- Comment -->
                        <div class="form-group">
                            <label class="form-label">Comment</label>
                            <textarea
                                v-model="toolDetailStore.statusForm.comment"
                                class="form-textarea"
                                rows="2"
                                placeholder="Additional notes..."
                                :disabled="toolDetailStore.statusForm.submitting"
                            ></textarea>
                        </div>

                        <!-- ETA to Up (hidden when status is UP) -->
                        <div class="form-group" v-if="toolDetailStore.shouldShowEtaField">
                            <label class="form-label">ETA to Up</label>
                            <input
                                type="datetime-local"
                                v-model="toolDetailStore.statusForm.eta_to_up"
                                class="form-input"
                                :disabled="toolDetailStore.statusForm.submitting"
                            />
                            <span class="form-help">
                                When do you expect the tool to be back up?
                            </span>
                        </div>

                        <!-- Modal actions -->
                        <div class="modal-actions">
                            <button
                                type="button"
                                class="btn btn-secondary"
                                @click="toolDetailStore.closeStatusForm()"
                                :disabled="toolDetailStore.statusForm.submitting"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                class="btn btn-primary"
                                :disabled="toolDetailStore.statusForm.submitting"
                            >
                                <span v-if="toolDetailStore.statusForm.submitting" class="loading-spinner loading-spinner-sm"></span>
                                {{ toolDetailStore.statusForm.submitting ? 'Saving...' : 'Save Changes' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </Teleport>
</template>

<style scoped>
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(2px);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: var(--z-modal);
    padding: 20px;
    animation: fadeIn 0.2s ease;
}

.modal {
    background: var(--qci-white);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-lg);
    width: 100%;
    max-width: 500px;
    max-height: 90vh;
    overflow: auto;
    animation: slideUp 0.3s ease;
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 24px;
    border-bottom: 1px solid var(--border-color);
}

.modal-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--qci-dark-navy);
    margin: 0;
}

.modal-close {
    background: none;
    border: none;
    font-size: 1.5rem;
    color: #666;
    cursor: pointer;
    padding: 0;
    line-height: 1;
    transition: color var(--transition-fast);
}

.modal-close:hover:not(:disabled) {
    color: var(--qci-dark-navy);
}

.modal-close:disabled {
    cursor: not-allowed;
    opacity: 0.5;
}

.modal-body {
    padding: 24px;
}

.modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid var(--border-color);
}

.status-preview {
    margin-top: 8px;
}

@keyframes fadeIn {
    from {
        opacity: 0;
    }
    to {
        opacity: 1;
    }
}

@keyframes slideUp {
    from {
        opacity: 0;
        transform: translateY(20px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}
</style>
