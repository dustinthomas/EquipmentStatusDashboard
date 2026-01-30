<script setup>
import { computed } from 'vue'

const props = defineProps({
    status: {
        type: String,
        required: true
    },
    size: {
        type: String,
        default: 'normal', // 'normal' or 'large'
        validator: (value) => ['normal', 'large'].includes(value)
    }
})

const statusClass = computed(() => {
    const statusMap = {
        'UP': 'status-up',
        'UP_WITH_ISSUES': 'status-up-with-issues',
        'MAINTENANCE': 'status-maintenance',
        'DOWN': 'status-down'
    }
    return statusMap[props.status] || 'status-up'
})

const statusLabel = computed(() => {
    const labelMap = {
        'UP': 'Up',
        'UP_WITH_ISSUES': 'Up with Issues',
        'MAINTENANCE': 'Maintenance',
        'DOWN': 'Down'
    }
    return labelMap[props.status] || props.status
})
</script>

<template>
    <span
        class="status-badge"
        :class="[statusClass, { 'status-badge-lg': size === 'large' }]"
    >
        <span class="status-badge-icon"></span>
        {{ statusLabel }}
    </span>
</template>
