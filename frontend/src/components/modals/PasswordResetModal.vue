<script setup>
import { useAdminStore } from '@/stores/admin'

const adminStore = useAdminStore()
</script>

<template>
    <Teleport to="body">
        <div class="modal-overlay" @click.self="adminStore.closePasswordModal()">
            <div class="modal">
                <div class="modal-header">
                    <h3 class="modal-title">Reset Password</h3>
                    <button
                        class="modal-close"
                        @click="adminStore.closePasswordModal()"
                        :disabled="adminStore.passwordModal.submitting"
                    >
                        &times;
                    </button>
                </div>

                <div class="modal-body">
                    <form @submit.prevent="adminStore.submitPasswordModal()">
                        <!-- Success message -->
                        <div v-if="adminStore.passwordModal.successMessage" class="alert alert-success">
                            {{ adminStore.passwordModal.successMessage }}
                        </div>

                        <!-- Error message -->
                        <div v-if="adminStore.passwordModal.error" class="alert alert-error">
                            {{ adminStore.passwordModal.error }}
                        </div>

                        <p class="modal-description">
                            Set a new password for <strong>{{ adminStore.passwordModal.userName }}</strong>
                        </p>

                        <!-- Password field -->
                        <div class="form-group">
                            <label class="form-label">
                                New Password <span class="required">*</span>
                            </label>
                            <input
                                type="password"
                                v-model="adminStore.passwordModal.password"
                                class="form-input"
                                placeholder="Enter new password"
                                :disabled="adminStore.passwordModal.submitting"
                                autocomplete="new-password"
                            />
                        </div>

                        <!-- Modal actions -->
                        <div class="modal-actions">
                            <button
                                type="button"
                                class="btn btn-secondary"
                                @click="adminStore.closePasswordModal()"
                                :disabled="adminStore.passwordModal.submitting"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                class="btn btn-primary"
                                :disabled="adminStore.passwordModal.submitting"
                            >
                                <span v-if="adminStore.passwordModal.submitting" class="loading-spinner loading-spinner-sm"></span>
                                {{ adminStore.passwordModal.submitting ? 'Resetting...' : 'Reset Password' }}
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
    max-width: 400px;
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

.modal-description {
    margin-bottom: 20px;
    color: var(--qci-body-text);
}

.modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid var(--border-color);
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
