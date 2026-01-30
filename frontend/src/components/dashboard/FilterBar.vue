<script setup>
import { useDashboardStore } from '@/stores/dashboard'

const dashboardStore = useDashboardStore()

function handleSubmit() {
    dashboardStore.applyFilters()
}
</script>

<template>
    <div class="card filter-card">
        <form @submit.prevent="handleSubmit" class="filter-form">
            <div class="filter-row">
                <!-- State filter -->
                <div class="filter-group">
                    <label class="filter-label">Status</label>
                    <select
                        v-model="dashboardStore.filters.state"
                        class="form-select filter-select"
                        @change="dashboardStore.applyFilters()"
                    >
                        <option value="">All Statuses</option>
                        <option value="UP">Up</option>
                        <option value="UP_WITH_ISSUES">Up with Issues</option>
                        <option value="MAINTENANCE">Maintenance</option>
                        <option value="DOWN">Down</option>
                    </select>
                </div>

                <!-- Area filter -->
                <div class="filter-group">
                    <label class="filter-label">Area</label>
                    <select
                        v-model="dashboardStore.filters.area"
                        class="form-select filter-select"
                        @change="dashboardStore.applyFilters()"
                    >
                        <option value="">All Areas</option>
                        <option
                            v-for="area in dashboardStore.meta.areas"
                            :key="area"
                            :value="area"
                        >
                            {{ area }}
                        </option>
                    </select>
                </div>

                <!-- Search input -->
                <div class="filter-group filter-group-search">
                    <label class="filter-label">Search</label>
                    <input
                        type="text"
                        v-model="dashboardStore.filters.search"
                        class="form-input filter-input"
                        placeholder="Search by tool name..."
                        @keyup.enter="dashboardStore.applyFilters()"
                    />
                </div>

                <!-- Action buttons -->
                <div class="filter-group filter-group-buttons">
                    <button type="submit" class="btn btn-primary btn-sm">
                        Apply
                    </button>
                    <button
                        type="button"
                        class="btn btn-secondary btn-sm"
                        @click="dashboardStore.clearFilters()"
                        :disabled="!dashboardStore.hasActiveFilters"
                    >
                        Clear
                    </button>
                </div>
            </div>
        </form>
    </div>
</template>

<style scoped>
.filter-card {
    margin-bottom: 20px;
    padding: 16px 20px;
}

.filter-form {
    width: 100%;
}

.filter-row {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    align-items: flex-end;
}

.filter-group {
    display: flex;
    flex-direction: column;
    min-width: 140px;
}

.filter-group-search {
    flex: 1;
    min-width: 200px;
}

.filter-group-buttons {
    flex-direction: row;
    gap: 8px;
}

.filter-label {
    font-size: 0.8rem;
    font-weight: 500;
    color: var(--qci-dark-navy);
    margin-bottom: 4px;
}

.filter-select,
.filter-input {
    padding: 8px 10px;
    font-size: 0.9rem;
}
</style>
