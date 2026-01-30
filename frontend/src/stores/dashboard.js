import { defineStore } from 'pinia'
import { ref, reactive, computed } from 'vue'
import { useApi } from '@/composables/useApi'
import { useAuthStore } from './auth'

export const useDashboardStore = defineStore('dashboard', () => {
    const { get } = useApi()
    const authStore = useAuthStore()

    // State
    const tools = ref([])
    const meta = reactive({
        total: 0,
        filtered: 0,
        areas: [],
        states: []
    })
    const loading = ref(false)
    const error = ref(null)

    // Filter state
    const filters = reactive({
        state: '',
        area: '',
        search: ''
    })

    // Sort state
    const sort = reactive({
        column: 'state',
        direction: 'asc'
    })

    // Sortable columns and their API field names
    const sortableColumns = {
        name: 'name',
        area: 'area',
        state: 'state',
        eta: 'eta',
        updated: 'updated'
    }

    // Getters
    const hasActiveFilters = computed(() => {
        return filters.state !== '' || filters.area !== '' || filters.search.trim() !== ''
    })

    // Actions

    /**
     * Build URL query string from filter and sort state
     */
    function buildFilterQueryString() {
        const params = new URLSearchParams()

        if (filters.state) {
            params.set('state', filters.state)
        }
        if (filters.area) {
            params.set('area', filters.area)
        }
        if (filters.search.trim()) {
            params.set('search', filters.search.trim())
        }

        // Add sort params (include even if defaults to maintain URL state)
        if (sort.column && sort.column !== 'state') {
            params.set('sort', sort.column)
        }
        if (sort.direction && sort.direction !== 'asc') {
            params.set('dir', sort.direction)
        }

        const queryString = params.toString()
        return queryString ? `?${queryString}` : ''
    }

    /**
     * Update browser URL with current filter state
     */
    function updateUrlWithFilters() {
        const queryString = buildFilterQueryString()
        const newUrl = window.location.pathname + queryString
        window.history.replaceState({}, '', newUrl)
    }

    /**
     * Read filter and sort state from URL query parameters
     */
    function readFiltersFromUrl() {
        const params = new URLSearchParams(window.location.search)

        filters.state = params.get('state') || ''
        filters.area = params.get('area') || ''
        filters.search = params.get('search') || ''

        // Read sort params (with defaults)
        sort.column = params.get('sort') || 'state'
        sort.direction = params.get('dir') || 'asc'

        // Check for error parameter (e.g., from admin route redirect)
        const errorParam = params.get('error')
        if (errorParam === 'forbidden') {
            error.value = 'You do not have permission to access that page. Admin access required.'
            // Clear the error param from URL without triggering a reload
            params.delete('error')
            const newUrl = window.location.pathname + (params.toString() ? '?' + params.toString() : '')
            window.history.replaceState({}, '', newUrl)
        }
    }

    /**
     * Fetch tools from the API
     */
    async function fetchTools() {
        loading.value = true
        // Preserve forbidden error message (from admin redirect), clear other errors
        if (error.value && !error.value.includes('Admin access required')) {
            error.value = null
        }

        const queryString = buildFilterQueryString()
        const { data, error: apiError, status } = await get(`/api/tools${queryString}`)

        if (status === 401) {
            authStore.clearAuth()
            error.value = 'Session expired. Please log in again.'
        } else if (apiError) {
            error.value = apiError
        } else {
            tools.value = data.tools || []
            Object.assign(meta, data.meta || { total: 0, filtered: 0, areas: [], states: [] })
            // Clear any previous errors on success
            if (error.value && !error.value.includes('Admin access required')) {
                error.value = null
            }
        }

        loading.value = false
    }

    /**
     * Apply current filters and fetch tools
     */
    function applyFilters() {
        updateUrlWithFilters()
        fetchTools()
    }

    /**
     * Clear all filters and fetch tools
     */
    function clearFilters() {
        filters.state = ''
        filters.area = ''
        filters.search = ''
        updateUrlWithFilters()
        fetchTools()
    }

    /**
     * Handle click on a sortable column header
     */
    function handleSortClick(column) {
        if (!sortableColumns[column]) {
            return
        }

        if (sort.column === column) {
            sort.direction = sort.direction === 'asc' ? 'desc' : 'asc'
        } else {
            sort.column = column
            sort.direction = 'asc'
        }

        updateUrlWithFilters()
        fetchTools()
    }

    /**
     * Check if a column is sortable
     */
    function isSortable(column) {
        return !!sortableColumns[column]
    }

    /**
     * Check if a column is the currently sorted column
     */
    function isSortedBy(column) {
        return sort.column === column
    }

    /**
     * Get the CSS class for sort indicator on a column header
     */
    function getSortClass(column) {
        if (!isSortedBy(column)) {
            return 'sortable'
        }
        return sort.direction === 'asc' ? 'sorted-asc' : 'sorted-desc'
    }

    /**
     * Clear dashboard data (on logout)
     */
    function clearData() {
        tools.value = []
        Object.assign(meta, { total: 0, filtered: 0, areas: [], states: [] })
        error.value = null
    }

    return {
        // State
        tools,
        meta,
        loading,
        error,
        filters,
        sort,
        sortableColumns,
        // Getters
        hasActiveFilters,
        // Actions
        buildFilterQueryString,
        updateUrlWithFilters,
        readFiltersFromUrl,
        fetchTools,
        applyFilters,
        clearFilters,
        handleSortClick,
        isSortable,
        isSortedBy,
        getSortClass,
        clearData
    }
})
