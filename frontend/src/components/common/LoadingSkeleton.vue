<script setup>
defineProps({
    type: {
        type: String,
        default: 'text', // 'text', 'badge', 'row'
        validator: (value) => ['text', 'badge', 'row'].includes(value)
    },
    lines: {
        type: Number,
        default: 3
    }
})
</script>

<template>
    <div class="skeleton-container">
        <template v-if="type === 'text'">
            <div
                v-for="i in lines"
                :key="i"
                class="skeleton skeleton-text"
                :style="{ width: i === lines ? '60%' : '100%' }"
            ></div>
        </template>

        <template v-else-if="type === 'badge'">
            <div class="skeleton skeleton-badge"></div>
        </template>

        <template v-else-if="type === 'row'">
            <div class="skeleton-row">
                <div class="skeleton" style="width: 30%; height: 20px;"></div>
                <div class="skeleton" style="width: 20%; height: 20px;"></div>
                <div class="skeleton skeleton-badge"></div>
                <div class="skeleton" style="width: 15%; height: 20px;"></div>
            </div>
        </template>
    </div>
</template>

<style scoped>
.skeleton-container {
    padding: 8px 0;
}

.skeleton-row {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 8px 12px;
}
</style>
