# Migration: Create statusevents table
# Stores immutable audit trail of equipment status changes

module CreateStatusEvents

import SearchLight.Migrations: create_table, column, primary_key, add_index, drop_table

function up()
    create_table(:statusevents) do
        [
            primary_key()
            column(:tool_id, :int)  # FK to tools.id
            column(:state, :string, limit = 20)
            column(:issue_description, :text)
            column(:comment, :text)
            column(:eta_to_up, :datetime)
            column(:created_by_user_id, :int)  # FK to users.id
            column(:created_at, :datetime)
        ]
    end

    # Index on tool_id for finding all events for a tool
    # (SearchLightSQLite doesn't support composite indexes via add_index,
    # so we use a single-column index on tool_id which is sufficient for our queries)
    add_index(:statusevents, :tool_id)

    # Index on created_at for date-range queries
    add_index(:statusevents, :created_at)

    # Index on created_by_user_id for finding events by user
    add_index(:statusevents, :created_by_user_id)

    # Index on state for filtering by status
    add_index(:statusevents, :state)
end

function down()
    drop_table(:statusevents)
end

end # module CreateStatusEvents
