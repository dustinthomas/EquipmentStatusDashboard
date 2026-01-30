import { defineStore } from 'pinia'
import { ref, reactive, computed } from 'vue'
import { useApi } from '@/composables/useApi'
import { useAuthStore } from './auth'

export const useAdminStore = defineStore('admin', () => {
    const { get, post, put } = useApi()
    const authStore = useAuthStore()

    // Current tab state
    const currentTab = ref('tools')

    // Tools state
    const tools = reactive({
        items: [],
        meta: {},
        loading: false,
        error: null,
        search: '',
        sortColumn: 'name',
        sortDirection: 'asc'
    })

    // Users state
    const users = reactive({
        items: [],
        meta: {},
        loading: false,
        error: null,
        search: '',
        sortColumn: 'name',
        sortDirection: 'asc'
    })

    // Tool modal state
    const toolModal = reactive({
        visible: false,
        mode: 'create',
        submitting: false,
        error: null,
        successMessage: null,
        id: null,
        name: '',
        area: '',
        bay: '',
        criticality: 'medium'
    })

    // User modal state
    const userModal = reactive({
        visible: false,
        mode: 'create',
        submitting: false,
        error: null,
        successMessage: null,
        id: null,
        username: '',
        name: '',
        password: '',
        role: 'operator'
    })

    // Password modal state
    const passwordModal = reactive({
        visible: false,
        submitting: false,
        error: null,
        successMessage: null,
        userId: null,
        userName: '',
        password: ''
    })

    // Valid criticality levels
    const validCriticalities = [
        { value: 'critical', label: 'Critical' },
        { value: 'high', label: 'High' },
        { value: 'medium', label: 'Medium' },
        { value: 'low', label: 'Low' }
    ]

    // Valid user roles
    const validRoles = [
        { value: 'admin', label: 'Admin' },
        { value: 'operator', label: 'Operator' }
    ]

    // Getters

    const filteredTools = computed(() => {
        let items = [...tools.items]

        // Apply search filter
        if (tools.search.trim()) {
            const searchLower = tools.search.toLowerCase().trim()
            items = items.filter(tool =>
                tool.name.toLowerCase().includes(searchLower)
            )
        }

        // Apply sorting
        const col = tools.sortColumn
        const dir = tools.sortDirection === 'asc' ? 1 : -1

        items.sort((a, b) => {
            let aVal = a[col]
            let bVal = b[col]

            if (col === 'criticality') {
                const priority = { 'critical': 0, 'high': 1, 'medium': 2, 'low': 3 }
                aVal = priority[aVal] ?? 4
                bVal = priority[bVal] ?? 4
            } else if (typeof aVal === 'string') {
                aVal = aVal.toLowerCase()
                bVal = bVal.toLowerCase()
            }

            if (aVal < bVal) return -1 * dir
            if (aVal > bVal) return 1 * dir
            return 0
        })

        return items
    })

    const filteredUsers = computed(() => {
        let items = [...users.items]

        // Apply search filter
        if (users.search.trim()) {
            const searchLower = users.search.toLowerCase().trim()
            items = items.filter(user =>
                user.username.toLowerCase().includes(searchLower) ||
                user.name.toLowerCase().includes(searchLower)
            )
        }

        // Apply sorting
        const col = users.sortColumn
        const dir = users.sortDirection === 'asc' ? 1 : -1

        items.sort((a, b) => {
            let aVal = a[col]
            let bVal = b[col]

            if (col === 'last_login_at') {
                aVal = aVal ? new Date(aVal).getTime() : (dir === 1 ? Infinity : -Infinity)
                bVal = bVal ? new Date(bVal).getTime() : (dir === 1 ? Infinity : -Infinity)
            } else if (col === 'role') {
                const priority = { 'admin': 0, 'operator': 1 }
                aVal = priority[aVal] ?? 2
                bVal = priority[bVal] ?? 2
            } else if (typeof aVal === 'string') {
                aVal = aVal.toLowerCase()
                bVal = bVal.toLowerCase()
            }

            if (aVal < bVal) return -1 * dir
            if (aVal > bVal) return 1 * dir
            return 0
        })

        return items
    })

    // Tool Actions

    async function fetchTools() {
        tools.loading = true
        tools.error = null

        const { data, error: apiError, status } = await get('/api/admin/tools')

        if (status === 401) {
            authStore.clearAuth()
            tools.error = 'Session expired. Please log in again.'
        } else if (status === 403) {
            tools.error = 'Access denied. Admin privileges required.'
        } else if (apiError) {
            tools.error = apiError
        } else {
            tools.items = data.tools || []
            tools.meta = data.meta || {}
        }

        tools.loading = false
    }

    function handleToolSortClick(column) {
        if (tools.sortColumn === column) {
            tools.sortDirection = tools.sortDirection === 'asc' ? 'desc' : 'asc'
        } else {
            tools.sortColumn = column
            tools.sortDirection = 'asc'
        }
    }

    function getToolSortClass(column) {
        if (tools.sortColumn !== column) {
            return 'sortable'
        }
        return tools.sortDirection === 'asc' ? 'sorted-asc' : 'sorted-desc'
    }

    function openAddToolModal() {
        toolModal.mode = 'create'
        toolModal.id = null
        toolModal.name = ''
        toolModal.area = ''
        toolModal.bay = ''
        toolModal.criticality = 'medium'
        toolModal.error = null
        toolModal.successMessage = null
        toolModal.visible = true
    }

    function openEditToolModal(tool) {
        toolModal.mode = 'edit'
        toolModal.id = tool.id
        toolModal.name = tool.name
        toolModal.area = tool.area
        toolModal.bay = tool.bay || ''
        toolModal.criticality = tool.criticality
        toolModal.error = null
        toolModal.successMessage = null
        toolModal.visible = true
    }

    function closeToolModal() {
        toolModal.visible = false
        toolModal.error = null
        toolModal.successMessage = null
    }

    async function submitToolModal() {
        if (!toolModal.name.trim()) {
            toolModal.error = 'Name is required'
            return false
        }
        if (!toolModal.area.trim()) {
            toolModal.error = 'Area is required'
            return false
        }

        toolModal.submitting = true
        toolModal.error = null

        const payload = {
            name: toolModal.name.trim(),
            area: toolModal.area.trim(),
            bay: toolModal.bay.trim(),
            criticality: toolModal.criticality
        }

        const isCreate = toolModal.mode === 'create'
        const url = isCreate ? '/api/admin/tools' : `/api/admin/tools/${toolModal.id}`
        const apiMethod = isCreate ? post : put

        const { data, error: apiError, status } = await apiMethod(url, payload)

        if (status === 401) {
            authStore.clearAuth()
            toolModal.error = 'Session expired. Please log in again.'
            toolModal.submitting = false
            return false
        } else if (apiError) {
            toolModal.error = apiError
            toolModal.submitting = false
            return false
        } else {
            toolModal.successMessage = isCreate
                ? 'Tool created successfully'
                : 'Tool updated successfully'

            await fetchTools()

            setTimeout(() => {
                closeToolModal()
            }, 1000)

            toolModal.submitting = false
            return true
        }
    }

    async function toggleToolActive(tool) {
        const action = tool.is_active ? 'deactivate' : 'activate'
        const confirmed = confirm(`Are you sure you want to ${action} "${tool.name}"?`)

        if (!confirmed) return

        const { data, error: apiError, status } = await post(`/api/admin/tools/${tool.id}/toggle-active`)

        if (status === 401) {
            authStore.clearAuth()
            tools.error = 'Session expired. Please log in again.'
        } else if (apiError) {
            tools.error = apiError || `Failed to ${action} tool`
        } else {
            await fetchTools()
        }
    }

    // User Actions

    async function fetchUsers() {
        users.loading = true
        users.error = null

        const { data, error: apiError, status } = await get('/api/admin/users')

        if (status === 401) {
            authStore.clearAuth()
            users.error = 'Session expired. Please log in again.'
        } else if (status === 403) {
            users.error = 'Access denied. Admin privileges required.'
        } else if (apiError) {
            users.error = apiError
        } else {
            users.items = data.users || []
            users.meta = data.meta || {}
        }

        users.loading = false
    }

    function handleUserSortClick(column) {
        if (users.sortColumn === column) {
            users.sortDirection = users.sortDirection === 'asc' ? 'desc' : 'asc'
        } else {
            users.sortColumn = column
            users.sortDirection = 'asc'
        }
    }

    function getUserSortClass(column) {
        if (users.sortColumn !== column) {
            return 'sortable'
        }
        return users.sortDirection === 'asc' ? 'sorted-asc' : 'sorted-desc'
    }

    function openAddUserModal() {
        userModal.mode = 'create'
        userModal.id = null
        userModal.username = ''
        userModal.name = ''
        userModal.password = ''
        userModal.role = 'operator'
        userModal.error = null
        userModal.successMessage = null
        userModal.visible = true
    }

    function openEditUserModal(user) {
        userModal.mode = 'edit'
        userModal.id = user.id
        userModal.username = user.username
        userModal.name = user.name
        userModal.password = ''
        userModal.role = user.role
        userModal.error = null
        userModal.successMessage = null
        userModal.visible = true
    }

    function closeUserModal() {
        userModal.visible = false
        userModal.error = null
        userModal.successMessage = null
    }

    async function submitUserModal() {
        if (!userModal.username.trim()) {
            userModal.error = 'Username is required'
            return false
        }
        if (!userModal.name.trim()) {
            userModal.error = 'Name is required'
            return false
        }
        if (userModal.mode === 'create' && !userModal.password.trim()) {
            userModal.error = 'Password is required'
            return false
        }

        userModal.submitting = true
        userModal.error = null

        const payload = {
            username: userModal.username.trim(),
            name: userModal.name.trim(),
            role: userModal.role
        }

        if (userModal.mode === 'create') {
            payload.password = userModal.password
        }

        const isCreate = userModal.mode === 'create'
        const url = isCreate ? '/api/admin/users' : `/api/admin/users/${userModal.id}`
        const apiMethod = isCreate ? post : put

        const { data, error: apiError, status } = await apiMethod(url, payload)

        if (status === 401) {
            authStore.clearAuth()
            userModal.error = 'Session expired. Please log in again.'
            userModal.submitting = false
            return false
        } else if (apiError) {
            userModal.error = apiError
            userModal.submitting = false
            return false
        } else {
            userModal.successMessage = isCreate
                ? 'User created successfully'
                : 'User updated successfully'

            await fetchUsers()

            setTimeout(() => {
                closeUserModal()
            }, 1000)

            userModal.submitting = false
            return true
        }
    }

    async function toggleUserActive(user) {
        const action = user.is_active ? 'deactivate' : 'activate'
        const confirmed = confirm(`Are you sure you want to ${action} "${user.name}"?`)

        if (!confirmed) return

        const { data, error: apiError, status } = await post(`/api/admin/users/${user.id}/toggle-active`)

        if (status === 401) {
            authStore.clearAuth()
            users.error = 'Session expired. Please log in again.'
        } else if (apiError) {
            users.error = apiError || `Failed to ${action} user`
        } else {
            await fetchUsers()
        }
    }

    // Password Reset Actions

    function openPasswordModal(user) {
        passwordModal.userId = user.id
        passwordModal.userName = user.name
        passwordModal.password = ''
        passwordModal.error = null
        passwordModal.successMessage = null
        passwordModal.visible = true
    }

    function closePasswordModal() {
        passwordModal.visible = false
        passwordModal.error = null
        passwordModal.successMessage = null
    }

    async function submitPasswordModal() {
        if (!passwordModal.password.trim()) {
            passwordModal.error = 'Password is required'
            return false
        }

        passwordModal.submitting = true
        passwordModal.error = null

        const { data, error: apiError, status } = await post(
            `/api/admin/users/${passwordModal.userId}/reset-password`,
            { password: passwordModal.password }
        )

        if (status === 401) {
            authStore.clearAuth()
            passwordModal.error = 'Session expired. Please log in again.'
            passwordModal.submitting = false
            return false
        } else if (apiError) {
            passwordModal.error = apiError
            passwordModal.submitting = false
            return false
        } else {
            passwordModal.successMessage = 'Password reset successfully'

            await fetchUsers()

            setTimeout(() => {
                closePasswordModal()
            }, 1000)

            passwordModal.submitting = false
            return true
        }
    }

    // Tab Management

    function switchTab(tab) {
        currentTab.value = tab
    }

    return {
        // State
        currentTab,
        tools,
        users,
        toolModal,
        userModal,
        passwordModal,
        validCriticalities,
        validRoles,
        // Getters
        filteredTools,
        filteredUsers,
        // Tool actions
        fetchTools,
        handleToolSortClick,
        getToolSortClass,
        openAddToolModal,
        openEditToolModal,
        closeToolModal,
        submitToolModal,
        toggleToolActive,
        // User actions
        fetchUsers,
        handleUserSortClick,
        getUserSortClass,
        openAddUserModal,
        openEditUserModal,
        closeUserModal,
        submitUserModal,
        toggleUserActive,
        // Password actions
        openPasswordModal,
        closePasswordModal,
        submitPasswordModal,
        // Tab management
        switchTab
    }
})
