import { defineStore } from 'pinia'
import { ref, reactive, computed } from 'vue'
import { useApi } from '@/composables/useApi'
import { useAuthStore } from './auth'

export const useToolDetailStore = defineStore('toolDetail', () => {
    const { get, post } = useApi()
    const authStore = useAuthStore()

    // Tool detail state
    const tool = ref(null)
    const loading = ref(false)
    const error = ref(null)

    // Status form state
    const statusForm = reactive({
        visible: false,
        submitting: false,
        error: null,
        state: '',
        issue_description: '',
        comment: '',
        eta_to_up: ''
    })

    // History state
    const history = reactive({
        events: [],
        toolName: '',
        loading: false,
        error: null,
        fromDate: '',
        toDate: ''
    })

    // Valid states for the dropdown
    const validStates = [
        { value: 'UP', label: 'Up', class: 'status-up' },
        { value: 'UP_WITH_ISSUES', label: 'Up with Issues', class: 'status-up-with-issues' },
        { value: 'MAINTENANCE', label: 'Maintenance', class: 'status-maintenance' },
        { value: 'DOWN', label: 'Down', class: 'status-down' }
    ]

    // Getters
    const hasActiveHistoryFilters = computed(() => {
        return history.fromDate !== '' || history.toDate !== ''
    })

    const shouldShowEtaField = computed(() => {
        return statusForm.state !== 'UP'
    })

    // Actions

    /**
     * Fetch tool details from the API
     */
    async function fetchTool(toolId) {
        loading.value = true
        error.value = null
        tool.value = null

        const { data, error: apiError, status } = await get(`/api/tools/${toolId}`)

        if (status === 401) {
            authStore.clearAuth()
            error.value = 'Session expired. Please log in again.'
        } else if (status === 404) {
            error.value = 'Tool not found'
        } else if (apiError) {
            error.value = apiError
        } else {
            tool.value = data.tool
        }

        loading.value = false
    }

    /**
     * Format a date/time value for datetime-local input
     */
    function formatDateTimeForInput(dateStr) {
        if (!dateStr) return ''
        try {
            const date = new Date(dateStr)
            if (isNaN(date.getTime())) return ''
            // Format as YYYY-MM-DDTHH:MM for datetime-local input
            return date.toISOString().slice(0, 16)
        } catch {
            return ''
        }
    }

    /**
     * Open status update form with current tool values pre-filled
     */
    function openStatusForm() {
        if (!tool.value) return

        statusForm.state = tool.value.state || ''
        statusForm.issue_description = tool.value.issue_description || ''
        statusForm.comment = tool.value.comment || ''
        statusForm.eta_to_up = formatDateTimeForInput(tool.value.eta_to_up)
        statusForm.error = null
        statusForm.visible = true
    }

    /**
     * Close the status update form without saving
     */
    function closeStatusForm() {
        statusForm.visible = false
        statusForm.error = null
    }

    /**
     * Submit the status update form
     */
    async function submitStatusForm(toolId) {
        if (!statusForm.state) {
            statusForm.error = 'Status is required'
            return false
        }

        statusForm.submitting = true
        statusForm.error = null

        // Build request payload
        const payload = {
            state: statusForm.state
        }

        // Only include optional fields if they have values
        if (statusForm.issue_description.trim()) {
            payload.issue_description = statusForm.issue_description.trim()
        }
        if (statusForm.comment.trim()) {
            payload.comment = statusForm.comment.trim()
        }
        // Only include ETA if state is not UP and field has value
        if (statusForm.state !== 'UP' && statusForm.eta_to_up) {
            payload.eta_to_up = statusForm.eta_to_up
        }

        const { data, error: apiError, status } = await post(`/api/tools/${toolId}/status`, payload)

        if (status === 401) {
            authStore.clearAuth()
            statusForm.error = 'Session expired. Please log in again.'
            statusForm.submitting = false
            return false
        } else if (apiError) {
            statusForm.error = apiError
            statusForm.submitting = false
            return false
        } else {
            tool.value = data.tool
            statusForm.visible = false
            statusForm.submitting = false
            return true
        }
    }

    /**
     * Fetch tool history from the API
     */
    async function fetchHistory(toolId) {
        history.loading = true
        history.error = null
        history.events = []

        // Build query string for date filters
        const params = new URLSearchParams()
        if (history.fromDate) {
            params.set('from', history.fromDate)
        }
        if (history.toDate) {
            params.set('to', history.toDate)
        }
        const queryString = params.toString()
        const url = `/api/tools/${toolId}/history${queryString ? '?' + queryString : ''}`

        const { data, error: apiError, status } = await get(url)

        if (status === 401) {
            authStore.clearAuth()
            history.error = 'Session expired. Please log in again.'
        } else if (status === 404) {
            history.error = 'Tool not found'
        } else if (apiError) {
            history.error = apiError
        } else {
            history.events = data.events || []
            history.toolName = data.tool_name || ''
        }

        history.loading = false
    }

    /**
     * Apply date filters and re-fetch history
     */
    function applyHistoryFilters(toolId) {
        if (toolId) {
            fetchHistory(toolId)
        }
    }

    /**
     * Clear date filters and re-fetch history
     */
    function clearHistoryFilters(toolId) {
        history.fromDate = ''
        history.toDate = ''
        if (toolId) {
            fetchHistory(toolId)
        }
    }

    /**
     * Export history to CSV
     */
    function exportHistoryCsv(toolId) {
        if (!toolId) return

        const params = new URLSearchParams()
        if (history.fromDate) {
            params.set('from', history.fromDate)
        }
        if (history.toDate) {
            params.set('to', history.toDate)
        }
        const queryString = params.toString()
        const url = `/api/tools/${toolId}/history.csv${queryString ? '?' + queryString : ''}`

        window.open(url, '_blank')
    }

    /**
     * Clear tool detail state
     */
    function clearTool() {
        tool.value = null
        error.value = null
        statusForm.visible = false
        statusForm.error = null
    }

    /**
     * Clear history state
     */
    function clearHistory() {
        history.events = []
        history.toolName = ''
        history.error = null
        history.fromDate = ''
        history.toDate = ''
    }

    return {
        // Tool state
        tool,
        loading,
        error,
        // Status form state
        statusForm,
        validStates,
        // History state
        history,
        // Getters
        hasActiveHistoryFilters,
        shouldShowEtaField,
        // Actions
        fetchTool,
        formatDateTimeForInput,
        openStatusForm,
        closeStatusForm,
        submitStatusForm,
        fetchHistory,
        applyHistoryFilters,
        clearHistoryFilters,
        exportHistoryCsv,
        clearTool,
        clearHistory
    }
})
