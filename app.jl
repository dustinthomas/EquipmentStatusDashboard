# QCI Equipment Status Dashboard
# Application entry point

using Genie
using Logging

# Configure logging
global_logger(ConsoleLogger(stderr, Logging.Info))

# Load environment configuration
const PORT = parse(Int, get(ENV, "PORT", "8000"))
const DATABASE_PATH = get(ENV, "DATABASE_PATH", "db/qci_status.sqlite")

@info "Starting QCI Equipment Status Dashboard"
@info "Port: $PORT"
@info "Database: $DATABASE_PATH"

# Initialize Genie
Genie.loadapp()

# Start server
up(PORT; async=false)
