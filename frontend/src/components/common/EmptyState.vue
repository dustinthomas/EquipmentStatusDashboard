<script setup>
defineProps({
    title: {
        type: String,
        default: 'No data found'
    },
    message: {
        type: String,
        default: ''
    },
    icon: {
        type: String,
        default: '&#128269;' // Magnifying glass
    }
})
</script>

<template>
    <div class="empty-state">
        <div class="empty-state-icon" v-html="icon"></div>
        <h3 class="empty-state-title">{{ title }}</h3>
        <p v-if="message" class="empty-state-message">{{ message }}</p>
        <slot></slot>
    </div>
</template>

<style scoped>
.empty-state {
    text-align: center;
    padding: 48px 24px;
    color: #666;
}

.empty-state-icon {
    font-size: 3rem;
    opacity: 0.5;
    margin-bottom: 16px;
}

.empty-state-title {
    font-size: 1.1rem;
    font-weight: 600;
    color: var(--qci-dark-navy);
    margin: 0 0 8px 0;
}

.empty-state-message {
    font-size: 0.9rem;
    margin: 0;
    max-width: 400px;
    margin-left: auto;
    margin-right: auto;
}
</style>
