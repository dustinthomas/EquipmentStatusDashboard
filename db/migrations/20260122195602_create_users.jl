# Migration: Create users table
# Stores user accounts for authentication and audit trail

module CreateUsers

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
    create_table(:users) do
        [
            primary_key()
            column(:username, :string, limit = 50)
            column(:password_hash, :string, limit = 255)
            column(:name, :string, limit = 100)
            column(:role, :string, limit = 20, default = "'operator'")
            column(:is_active, :bool, default = "1")
            column(:last_login_at, :datetime)
            column(:created_at, :datetime)
            column(:updated_at, :datetime)
        ]
    end

    # Add unique constraint on username
    add_index(:users, :username, unique = true)

    # Add index on role for filtering
    add_index(:users, :role)

    # Add index on is_active for filtering active users
    add_index(:users, :is_active)
end

function down()
    drop_table(:users)
end

end # module CreateUsers
