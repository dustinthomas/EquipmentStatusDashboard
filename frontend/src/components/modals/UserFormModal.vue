<script setup>
import { useAdminStore } from '@/stores/admin'

const adminStore = useAdminStore()
</script>

<template>
    <Teleport to="body">
        <div class="modal-overlay" @click.self="adminStore.closeUserModal()">
            <div class="modal">
                <div class="modal-header">
                    <h3 class="modal-title">
                        {{ adminStore.userModal.mode === 'create' ? 'Add New User' : 'Edit User' }}
                    </h3>
                    <button
                        class="modal-close"
                        @click="adminStore.closeUserModal()"
                        :disabled="adminStore.userModal.submitting"
                    >
                        &times;
                    </button>
                </div>

                <div class="modal-body">
                    <form @submit.prevent="adminStore.submitUserModal()">
                        <!-- Success message -->
                        <div v-if="adminStore.userModal.successMessage" class="alert alert-success">
                            {{ adminStore.userModal.successMessage }}
                        </div>

                        <!-- Error message -->
                        <div v-if="adminStore.userModal.error" class="alert alert-error">
                            {{ adminStore.userModal.error }}
                        </div>

                        <!-- Username field -->
                        <div class="form-group">
                            <label class="form-label">
                                Username <span class="required">*</span>
                            </label>
                            <input
                                type="text"
                                v-model="adminStore.userModal.username"
                                class="form-input"
                                placeholder="Enter username"
                                :disabled="adminStore.userModal.submitting"
                                autocomplete="off"
                            />
                        </div>

                        <!-- Name field -->
                        <div class="form-group">
                            <label class="form-label">
                                Display Name <span class="required">*</span>
                            </label>
                            <input
                                type="text"
                                v-model="adminStore.userModal.name"
                                class="form-input"
                                placeholder="Enter display name"
                                :disabled="adminStore.userModal.submitting"
                            />
                        </div>

                        <!-- Password field (only for create mode) -->
                        <div class="form-group" v-if="adminStore.userModal.mode === 'create'">
                            <label class="form-label">
                                Password <span class="required">*</span>
                            </label>
                            <input
                                type="password"
                                v-model="adminStore.userModal.password"
                                class="form-input"
                                placeholder="Enter password"
                                :disabled="adminStore.userModal.submitting"
                                autocomplete="new-password"
                            />
                            <span class="form-help">
                                Password can be changed later via "Reset Password"
                            </span>
                        </div>

                        <!-- Role field -->
                        <div class="form-group">
                            <label class="form-label">Role</label>
                            <select
                                v-model="adminStore.userModal.role"
                                class="form-select"
                                :disabled="adminStore.userModal.submitting"
                            >
                                <option
                                    v-for="role in adminStore.validRoles"
                                    :key="role.value"
                                    :value="role.value"
                                >
                                    {{ role.label }}
                                </option>
                            </select>
                            <div v-if="adminStore.userModal.role" class="role-preview">
                                <span
                                    class="role-badge"
                                    :class="`role-${adminStore.userModal.role}`"
                                >
                                    {{ adminStore.userModal.role }}
                                </span>
                            </div>
                        </div>

                        <!-- Modal actions -->
                        <div class="modal-actions">
                            <button
                                type="button"
                                class="btn btn-secondary"
                                @click="adminStore.closeUserModal()"
                                :disabled="adminStore.userModal.submitting"
                            >
                                Cancel
                            </button>
                            <button
                                type="submit"
                                class="btn btn-primary"
                                :disabled="adminStore.userModal.submitting"
                            >
                                <span v-if="adminStore.userModal.submitting" class="loading-spinner loading-spinner-sm"></span>
                                {{ adminStore.userModal.submitting
                                    ? 'Saving...'
                                    : (adminStore.userModal.mode === 'create' ? 'Create User' : 'Save Changes') }}
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

.role-preview {
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
