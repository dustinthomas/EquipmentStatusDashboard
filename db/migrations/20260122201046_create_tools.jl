# Migration: Create tools table
# Stores equipment/tool data with denormalized current status

module CreateTools

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
    create_table(:tools) do
        [
            primary_key()
            column(:name, :string, limit = 100)
            column(:area, :string, limit = 50)
            column(:bay, :string, limit = 50)
            column(:criticality, :string, limit = 20, default = "'medium'")
            column(:is_active, :bool, default = "1")
            # Denormalized current status fields
            column(:current_state, :string, limit = 20, default = "'UP'")
            column(:current_issue_description, :text)
            column(:current_comment, :text)
            column(:current_eta_to_up, :datetime)
            column(:current_status_updated_at, :datetime)
            column(:current_status_updated_by_user_id, :int)
            # Timestamps
            column(:created_at, :datetime)
            column(:updated_at, :datetime)
        ]
    end

    # Index on name for quick lookups
    add_index(:tools, :name)

    # Index on area for filtering by fab area
    add_index(:tools, :area)

    # Index on current_state for dashboard filtering
    add_index(:tools, :current_state)

    # Index on is_active for filtering active tools
    add_index(:tools, :is_active)

    # Index on criticality for sorting/filtering
    add_index(:tools, :criticality)
end

function down()
    drop_table(:tools)
end

end # module CreateTools
