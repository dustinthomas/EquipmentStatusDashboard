<script setup>
import { useAdminStore } from '@/stores/admin'

const adminStore = useAdminStore()

function getCriticalityClass(criticality) {
    return `criticality-${criticality}`
}
</script>

<template>
    <Teleport to="body">
        <div class="modal-overlay" @click.self="adminStore.closeToolModal()">
            <div class="modal">
                <div class="modal-header">
                    <h3 class="modal-title">
                        {{ adminStore.toolModal.mode === 'create' ? 'Add New Tool' : 'Edit Tool' }}
                    </h3>
                    <button
                        class="modal-close"
                        @click="adminStore.closeToolModal()"
                        :disabled="adminStore.toolModal.submitting"
                    >
                        &times;
                    </button>
                </div>

                <div class="modal-body">
                    <form @submit.prevent="adminStore.submitToolModal()">
                        <!-- Success message -->
                        <div v-if="adminStore.toolModal.successMessage" class="alert alert-success">
                            {{ adminStore.toolModal.successMessage }}
                        </div>

                        <!-- Error message -->
                        <div v-if="adminStore.toolModal.error" class="alert alert-error">
                            {{ adminStore.toolModal.error }}
                        </div>

                        <!-- Name field -->
                        <div class="form-group">
                            <label class="form-label">
                                Tool Name <span class="required">*</span>
                            </label>
                            <input
                                type="text"
                                v-model="adminStore.toolModal.name"
                                class="form-input"
                                placeholder="Enter tool name"
                                :disabled="adminStore.toolModal.submitting"
                            />
                        </div>

                        <!-- Area field -->
                        <div class="form-group">
                            <label class="form-label">
                                Area <span class="required">*</span>
                            </label>
                            <input
                                type="text"
                                v-model="adminStore.toolModal.area"
                                class="form-input"
                                placeholder="Enter area (e.g., Etch, Litho)"
                                :disabled="adminStore.toolModal.submitting"
                            />
                        </div>

                        <!-- Bay field -->
                        <div class="form-group">
                            <label class="form-label">Bay / Line</label>
                            <input
                                type="text"
                                v-model="adminStore.toolModal.bay"
                                class="form-input"
                                placeholder="Enter bay or line (optional)"
                                :disabled="adminStore.toolModal.submitting"
                            />
                        </div>

                        <!-- Criticality field -->
                        <div class="form-group">
                            <label class="form-label">Criticality</label>
                            <select
                                v-model="adminStore.toolModal.criticality"
                                class="form-select"
                                :disabled="adminStore.toolModal.submitting"
                            >
                                <option
                                    v-for="crit in adminStore.validCriticalities"
                                    :key="crit.value"
                                    :value="crit.value"
                                >
                                    {{ crit.label }}
                                </option>
                            </select>
                            <div v-if="adminStore.toolModal.criticality" class="criticality-preview">
                                <span
                                    class="criticality-badge"
                                    :class="getCriticalityClass(adminStore.toolModal.criticality)"
                                >
                                    {{ adminStore.toolModal.criticality }}
                                </span>
                            </div>
                        </div>

                        <!-- Modal actions -->
                        <div class="modal-actions">
                            <button
                                type="button"
                                class="btn btn-secondary"
                                @click="adminStore.closeToolModal()"
                                :disabled="adminStore.toolModal.submitting"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                class="btn btn-primary"
                                :disabled="adminStore.toolModal.submitting"
                            >
                                <span v-if="adminStore.toolModal.submitting" class="loading-spinner loading-spinner-sm"></span>
                                {{ adminStore.toolModal.submitting
                                    ? 'Saving...'
                                    : (adminStore.toolModal.mode === 'create' ? 'Create Tool' : 'Save Changes') }}
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

.criticality-preview {
    margin-top: 8px;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
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
