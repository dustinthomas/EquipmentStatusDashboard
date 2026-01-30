<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const toasts = ref([])
let toastId = 0

function addToast(message, type = 'info', duration = 4000) {
    const id = ++toastId
    toasts.value.push({ id, message, type })

    if (duration > 0) {
        setTimeout(() => {
            removeToast(id)
        }, duration)
    }

    return id
}

function removeToast(id) {
    const index = toasts.value.findIndex(t => t.id === id)
    if (index > -1) {
        toasts.value.splice(index, 1)
    }
}

// Expose methods globally via custom event
function handleToastEvent(event) {
    const { message, type, duration } = event.detail
    addToast(message, type, duration)
}

onMounted(() => {
    window.addEventListener('show-toast', handleToastEvent)
})

onUnmounted(() => {
    window.removeEventListener('show-toast', handleToastEvent)
})

// Expose as global function for convenience
window.showToast = (message, type = 'info', duration = 4000) => {
    window.dispatchEvent(new CustomEvent('show-toast', {
        detail: { message, type, duration }
    }))
}
</script>

<template>
    <div class="toast-container">
        <TransitionGroup name="toast">
            <div
                v-for="toast in toasts"
                :key="toast.id"
                class="toast"
                :class="`toast-${toast.type}`"
                @click="removeToast(toast.id)"
            >
                <span class="toast-icon">
                    <template v-if="toast.type === 'success'">&#10003;</template>
                    <template v-else-if="toast.type === 'error'">&#10007;</template>
                    <template v-else-if="toast.type === 'warning'">&#9888;</template>
                    <template v-else>&#8505;</template>
                </span>
                <span class="toast-message">{{ toast.message }}</span>
                <button class="toast-close">&times;</button>
            </div>
        </TransitionGroup>
    </div>
</template>

<style scoped>
.toast-container {
    position: fixed;
    top: 20px;
    right: 20px;
    z-index: var(--z-toast);
    display: flex;
    flex-direction: column;
    gap: 10px;
    max-width: 400px;
}

.toast {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 14px 16px;
    background: var(--qci-white);
    border-radius: var(--radius-md);
    box-shadow: var(--shadow-lg);
    cursor: pointer;
    border-left: 4px solid;
}

.toast-success {
    border-color: var(--status-up);
}

.toast-error {
    border-color: var(--status-down);
}

.toast-warning {
    border-color: var(--status-up-with-issues);
}

.toast-info {
    border-color: var(--qci-dark-navy);
}

.toast-icon {
    font-size: 1.2rem;
    flex-shrink: 0;
}

.toast-success .toast-icon {
    color: var(--status-up);
}

.toast-error .toast-icon {
    color: var(--status-down);
}

.toast-warning .toast-icon {
    color: var(--status-up-with-issues);
}

.toast-info .toast-icon {
    color: var(--qci-dark-navy);
}

.toast-message {
    flex: 1;
    font-size: 0.9rem;
    color: var(--qci-body-text);
}

.toast-close {
    background: none;
    border: none;
    font-size: 1.2rem;
    color: #999;
    cursor: pointer;
    padding: 0;
    line-height: 1;
}

.toast-close:hover {
    color: var(--qci-body-text);
}

/* Animations */
.toast-enter-active {
    animation: toast-in 0.3s ease;
}

.toast-leave-active {
    animation: toast-out 0.3s ease;
}

@keyframes toast-in {
    from {
        opacity: 0;
        transform: translateX(100%);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

@keyframes toast-out {
    from {
        opacity: 1;
        transform: translateX(0);
    }
    to {
        opacity: 0;
        transform: translateX(100%);
    }
}
</style>
