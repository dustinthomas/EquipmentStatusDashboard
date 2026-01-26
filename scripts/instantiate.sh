#!/bin/bash
# Instantiate Julia package dependencies

set -e

cd "$(dirname "$0")/.."

echo "Instantiating Julia dependencies..."
julia --project=. -e "using Pkg; Pkg.instantiate()"
echo "Done."
