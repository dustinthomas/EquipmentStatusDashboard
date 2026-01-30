<script setup>
import { onMounted } from 'vue'
import { useDashboardStore } from '@/stores/dashboard'
import FilterBar from '@/components/dashboard/FilterBar.vue'
import ToolTable from '@/components/dashboard/ToolTable.vue'

const dashboardStore = useDashboardStore()

onMounted(() => {
    dashboardStore.readFiltersFromUrl()
    dashboardStore.fetchTools()
})
</script>

<template>
    <div class="dashboard-view">
        <div class="page-header">
            <h1>Equipment Status Dashboard</h1>
            <p>Monitor and update the status of fab equipment</p>
        </div>

        <!-- Error message -->
        <div v-if="dashboardStore.error" class="alert alert-error">
            {{ dashboardStore.error }}
        </div>

        <!-- Filter bar -->
        <FilterBar />

        <!-- Tool table -->
        <ToolTable />
    </div>
</template>

<style scoped>
.dashboard-view {
    padding-bottom: 24px;
}

.page-header {
    margin-bottom: 24px;
}

.page-header h1 {
    margin-bottom: 8px;
}

.page-header p {
    color: #666;
    margin: 0;
}
</style>
