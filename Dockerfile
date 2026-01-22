FROM julia:latest

WORKDIR /app

# Copy project files
COPY Project.toml .
COPY Manifest.toml* .

# Install dependencies
RUN julia --project=. -e "using Pkg; Pkg.instantiate()"

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Set environment variables
ENV PORT=8000
ENV DATABASE_PATH=/data/qci_status.sqlite
ENV LOG_LEVEL=info

# Create data directory
RUN mkdir -p /data

# Run the application
CMD ["julia", "--project=.", "-e", "include(\"app.jl\")"]
