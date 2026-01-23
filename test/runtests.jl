# QCI Equipment Status Dashboard - Test Suite

using Test
using HTTP
using JSON3

# Load Genie for route testing
using Genie
using Genie.Router
using Genie.Renderer.Json: json

# Load SearchLight for database testing
using SearchLight
using SearchLightSQLite

# Set test environment
ENV["GENIE_ENV"] = "test"
ENV["SEARCHLIGHT_ENV"] = "test"

@testset "EquipmentStatusDashboard" begin
    @testset "Configuration" begin
        # Test that config files exist
        @test isfile(joinpath(@__DIR__, "..", "config", "routes.jl"))
        @test isfile(joinpath(@__DIR__, "..", "config", "env", "dev.jl"))
        @test isfile(joinpath(@__DIR__, "..", "config", "env", "prod.jl"))
        @test isfile(joinpath(@__DIR__, "..", "app.jl"))

        # Test database config files exist
        @test isfile(joinpath(@__DIR__, "..", "config", "database.jl"))
        @test isfile(joinpath(@__DIR__, "..", "config", "initializers", "searchlight.jl"))
        @test isfile(joinpath(@__DIR__, "..", "db", "connection.yml"))
    end

    @testset "Database Configuration" begin
        # Use a temp file for testing
        test_db_path = joinpath(tempdir(), "test_qci_$(rand(UInt32)).sqlite")
        ENV["DATABASE_PATH"] = test_db_path

        # Include database configuration
        include(joinpath(@__DIR__, "..", "config", "database.jl"))

        # Test database_path function respects env var
        @test database_path() == test_db_path

        # Test connection
        @test connect_database() == true
        @test is_connected() == true

        # Test basic query works (returns a DataFrame)
        result = SearchLight.query("SELECT 1 as test_col")
        @test size(result, 1) == 1  # 1 row in the DataFrame

        # Test disconnect
        disconnect_database()

        # Cleanup test database
        isfile(test_db_path) && rm(test_db_path)

        # Reset DATABASE_PATH for other tests
        delete!(ENV, "DATABASE_PATH")
    end

    @testset "Database Path Environment Variable" begin
        # Test custom path from environment
        test_path = "/tmp/test_qci_status_custom.sqlite"
        ENV["DATABASE_PATH"] = test_path

        include(joinpath(@__DIR__, "..", "config", "database.jl"))
        @test database_path() == test_path

        # Test without env var falls back to test environment path
        delete!(ENV, "DATABASE_PATH")
        @test database_path() == joinpath("db", "qci_status_test.sqlite")
    end

    @testset "Routes" begin
        # Include routes to test they load without error
        include(joinpath(@__DIR__, "..", "config", "routes.jl"))
        @test true  # If we get here, routes loaded successfully
    end

    @testset "Health Endpoint" begin
        # Test that json function returns proper response
        response = json(Dict("status" => "ok"))
        @test response.status == 200
        body = JSON3.read(String(response.body))
        @test body.status == "ok"
    end

    @testset "Models" begin
        # TODO: Add model tests
        @test true  # Placeholder
    end

    @testset "Controllers" begin
        # TODO: Add controller tests
        @test true  # Placeholder
    end

    @testset "Authentication" begin
        # TODO: Add auth tests
        @test true  # Placeholder
    end
end
