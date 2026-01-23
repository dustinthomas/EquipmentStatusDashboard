# Authentication Core Functions
# Core password hashing and user authentication functions
# These functions are independent of session/web framework concerns

module AuthCore

using SHA
using Logging

export hash_password, verify_password

"""
    hash_password(password::String) -> String

Hash a password using SHA256.
Returns the hex-encoded hash string (64 characters).

# Example
```julia
hash = hash_password("mysecretpassword")
```
"""
function hash_password(password::String)::String
    return bytes2hex(sha256(password))
end

"""
    verify_password(password::String, hash::String) -> Bool

Verify a password against a stored hash.
Supports SHA256 hashes (64 hex characters).

Returns true if the password matches the hash, false otherwise.

# Example
```julia
hash = hash_password("mysecretpassword")
verify_password("mysecretpassword", hash)  # returns true
verify_password("wrongpassword", hash)     # returns false
```
"""
function verify_password(password::String, hash::String)::Bool
    # SHA256 produces 64 hex characters
    if length(hash) == 64
        return hash_password(password) == hash
    end
    return false
end

end # module AuthCore
