/**
 * API composable for making authenticated requests
 * Centralizes fetch logic with 401 handling
 */

import { useAuthStore } from '@/stores/auth'

/**
 * Create a fetch wrapper with authentication handling
 */
export function useApi() {
    /**
     * Make an API request
     * @param {string} url - The URL to fetch
     * @param {Object} options - Fetch options
     * @returns {Promise<{data: any, error: string|null, status: number}>}
     */
    async function request(url, options = {}) {
        const authStore = useAuthStore()

        const defaultOptions = {
            credentials: 'same-origin',
            headers: {
                'Accept': 'application/json',
                ...(options.body ? { 'Content-Type': 'application/json' } : {})
            }
        }

        const mergedOptions = {
            ...defaultOptions,
            ...options,
            headers: {
                ...defaultOptions.headers,
                ...options.headers
            }
        }

        try {
            const response = await fetch(url, mergedOptions)

            // Handle 401 - session expired
            if (response.status === 401) {
                authStore.clearAuth()
                return {
                    data: null,
                    error: 'Session expired. Please log in again.',
                    status: 401
                }
            }

            // Handle 403 - forbidden
            if (response.status === 403) {
                return {
                    data: null,
                    error: 'You do not have permission to access this resource.',
                    status: 403
                }
            }

            // Try to parse JSON response
            let data = null
            const contentType = response.headers.get('content-type')
            if (contentType && contentType.includes('application/json')) {
                data = await response.json()
            } else {
                data = await response.text()
            }

            if (!response.ok) {
                return {
                    data: null,
                    error: data?.error || `Request failed with status ${response.status}`,
                    status: response.status
                }
            }

            return {
                data,
                error: null,
                status: response.status
            }
        } catch (err) {
            console.error('API request failed:', err)
            return {
                data: null,
                error: 'Unable to connect to server. Please try again.',
                status: 0
            }
        }
    }

    /**
     * Make a GET request
     */
    function get(url, options = {}) {
        return request(url, { ...options, method: 'GET' })
    }

    /**
     * Make a POST request
     */
    function post(url, body, options = {}) {
        return request(url, {
            ...options,
            method: 'POST',
            body: body ? JSON.stringify(body) : undefined
        })
    }

    /**
     * Make a PUT request
     */
    function put(url, body, options = {}) {
        return request(url, {
            ...options,
            method: 'PUT',
            body: body ? JSON.stringify(body) : undefined
        })
    }

    /**
     * Make a DELETE request
     */
    function del(url, options = {}) {
        return request(url, { ...options, method: 'DELETE' })
    }

    return {
        request,
        get,
        post,
        put,
        del
    }
}
