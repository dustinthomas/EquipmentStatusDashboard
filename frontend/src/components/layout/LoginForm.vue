<script setup>
import { reactive } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const form = reactive({
    username: '',
    password: '',
    submitting: false,
    error: null
})

async function handleSubmit() {
    form.error = null

    if (!form.username.trim() || !form.password.trim()) {
        form.error = 'Please enter both username and password'
        return
    }

    form.submitting = true

    const result = await authStore.login(form.username.trim(), form.password)

    if (result.success) {
        // Clear form on success
        form.username = ''
        form.password = ''
    } else {
        form.error = result.error
    }

    form.submitting = false
}
</script>

<template>
    <div class="login-container">
        <div class="card login-card">
            <div class="card-header">
                <h2>Equipment Status Dashboard</h2>
                <p>Sign in to continue</p>
            </div>

            <form @submit.prevent="handleSubmit" class="login-form">
                <!-- Error message -->
                <div v-if="form.error" class="alert alert-error">
                    {{ form.error }}
                </div>

                <div class="form-group">
                    <label for="username" class="form-label">Username</label>
                    <input
                        type="text"
                        id="username"
                        v-model="form.username"
                        class="form-input"
                        placeholder="Enter your username"
                        :disabled="form.submitting"
                        autocomplete="username"
                    />
                </div>

                <div class="form-group">
                    <label for="password" class="form-label">Password</label>
                    <input
                        type="password"
                        id="password"
                        v-model="form.password"
                        class="form-input"
                        placeholder="Enter your password"
                        :disabled="form.submitting"
                        autocomplete="current-password"
                    />
                </div>

                <div class="form-group">
                    <button
                        type="submit"
                        class="btn btn-primary btn-block"
                        :disabled="form.submitting"
                    >
                        <span v-if="form.submitting" class="loading-spinner loading-spinner-sm"></span>
                        {{ form.submitting ? 'Signing in...' : 'Sign In' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>

<style scoped>
.login-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: calc(100vh - 300px);
    width: 100%;
}

.login-card {
    width: 100%;
    max-width: 400px;
    padding: 40px;
}

.login-form .form-group:last-child {
    margin-bottom: 0;
    margin-top: 24px;
}
</style>
