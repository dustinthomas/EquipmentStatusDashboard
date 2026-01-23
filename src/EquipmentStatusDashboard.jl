# QCI Equipment Status Dashboard
# Main module file for package compilation

module EquipmentStatusDashboard

using Genie
using SearchLight
using SearchLightSQLite

# Export database configuration functions
export database_config, connect_database, disconnect_database, is_connected

end # module
