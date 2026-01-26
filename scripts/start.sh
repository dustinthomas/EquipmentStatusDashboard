#!/bin/bash
# Start the QCI Equipment Status Dashboard

set -e

cd "$(dirname "$0")/.."

echo "Starting QCI Equipment Status Dashboard..."
julia --project=. -e 'include("app.jl")'
