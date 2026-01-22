# Production environment configuration
using Genie
using Logging

Genie.Configuration.config!(
    server_port = parse(Int, get(ENV, "PORT", "8000")),
    server_host = "0.0.0.0",
    log_level = Logging.Info,
    log_to_file = false,
    server_handle_static_files = true,
    path_build = "build",
    format_julia_builds = false,
    format_html_output = false,
    watch = false
)

ENV["GENIE_ENV"] = "prod"
