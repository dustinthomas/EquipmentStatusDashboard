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

    @testset "Layout and Styles" begin
        # Test base layout template exists
        layout_path = joinpath(@__DIR__, "..", "src", "views", "layouts", "app.jl.html")
        @test isfile(layout_path)

        # Test layout has required HTML5 structure
        layout_content = read(layout_path, String)
        @test occursin("<!DOCTYPE html>", layout_content)
        @test occursin("<html", layout_content)
        @test occursin("<head>", layout_content)
        @test occursin("<body>", layout_content)

        # Test layout includes Raleway font
        @test occursin("Raleway", layout_content)
        @test occursin("fonts.googleapis.com", layout_content)

        # Test layout has navigation
        @test occursin("<nav", layout_content)
        @test occursin("navbar", layout_content)

        # Test layout has footer with QCI copyright
        @test occursin("<footer", layout_content)
        @test occursin("QCI", layout_content)

        # Test layout references QCI CSS
        @test occursin("qci.css", layout_content)

        # Test CSS files exist
        @test isfile(joinpath(@__DIR__, "..", "public", "css", "qci.css"))
        @test isfile(joinpath(@__DIR__, "..", "public", "css", "qci-theme.css"))

        # Test CSS has QCI brand colors defined
        css_content = read(joinpath(@__DIR__, "..", "public", "css", "qci-theme.css"), String)
        @test occursin("#1E204B", css_content) || occursin("#1e204b", css_content)  # Dark navy
        @test occursin("Raleway", css_content)  # Font family

        # Test main CSS imports theme
        main_css = read(joinpath(@__DIR__, "..", "public", "css", "qci.css"), String)
        @test occursin("qci-theme.css", main_css)
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

        # Cleanup test database (handles Windows SQLite file locking)
        cleanup_test_database(test_db_path)

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
        @testset "User Model" begin
            # Use a temp file for model testing
            test_db_path = joinpath(tempdir(), "test_user_model_$(rand(UInt32)).sqlite")
            ENV["DATABASE_PATH"] = test_db_path

            # Include database configuration and connect
            include(joinpath(@__DIR__, "..", "config", "database.jl"))
            @test connect_database() == true

            # Include the User model
            include(joinpath(@__DIR__, "..", "src", "models", "User.jl"))
            using .Users: User, VALID_ROLES, validate_role, is_admin, find_by_username

            # Run migration to create users table
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122195602_create_users.jl"))
            CreateUsers.up()

            @testset "Role validation" begin
                @test validate_role("admin") == true
                @test validate_role("operator") == true
                @test validate_role("user") == false
                @test validate_role("invalid") == false
                @test validate_role("") == false
            end

            @testset "VALID_ROLES constant" begin
                @test "admin" in VALID_ROLES
                @test "operator" in VALID_ROLES
                @test length(VALID_ROLES) == 2
            end

            @testset "User creation and retrieval" begin
                # Create a test user
                user = User(
                    username = "testuser",
                    password_hash = "hashed_password_123",
                    name = "Test User",
                    role = "operator",
                    is_active = true
                )

                # Save to database
                saved_user = SearchLight.save!(user)
                @test saved_user.id.value !== nothing

                # Retrieve from database using findone
                retrieved = SearchLight.findone(User; id = saved_user.id.value)
                @test retrieved !== nothing
                @test retrieved.username == "testuser"
                @test retrieved.name == "Test User"
                @test retrieved.role == "operator"
                @test retrieved.is_active == true
            end

            @testset "Find by username" begin
                # Create another user for this test
                admin_user = User(
                    username = "adminuser",
                    password_hash = "admin_hash_456",
                    name = "Admin User",
                    role = "admin",
                    is_active = true
                )
                SearchLight.save!(admin_user)

                # Find by username
                found = find_by_username("adminuser")
                @test found !== nothing
                @test found.username == "adminuser"
                @test found.role == "admin"

                # Test non-existent user
                not_found = find_by_username("nonexistent")
                @test not_found === nothing
            end

            @testset "is_admin helper" begin
                admin = User(role = "admin")
                operator = User(role = "operator")

                @test is_admin(admin) == true
                @test is_admin(operator) == false
            end

            @testset "User fields" begin
                user = User()
                # Check default values
                @test user.username == ""
                @test user.password_hash == ""
                @test user.name == ""
                @test user.role == "operator"
                @test user.is_active == true
                @test user.last_login_at == ""
                @test !isempty(user.created_at)  # Should have default timestamp
                @test !isempty(user.updated_at)  # Should have default timestamp
            end

            # Cleanup (handles Windows SQLite file locking)
            cleanup_test_database(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end

        @testset "Tool Model" begin
            # Use a temp file for model testing
            test_db_path = joinpath(tempdir(), "test_tool_model_$(rand(UInt32)).sqlite")
            ENV["DATABASE_PATH"] = test_db_path

            # Include database configuration and connect
            include(joinpath(@__DIR__, "..", "config", "database.jl"))
            @test connect_database() == true

            # Include the Tool model
            include(joinpath(@__DIR__, "..", "src", "models", "Tool.jl"))
            using .Tools: Tool, VALID_STATES, VALID_CRITICALITIES, validate_state, validate_criticality,
                          find_active_tools, find_by_area, find_down_tools

            # Run migration to create tools table
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122201046_create_tools.jl"))
            CreateTools.up()

            @testset "State validation" begin
                @test validate_state("UP") == true
                @test validate_state("UP_WITH_ISSUES") == true
                @test validate_state("MAINTENANCE") == true
                @test validate_state("DOWN") == true
                @test validate_state("UNKNOWN") == false
                @test validate_state("") == false
                @test validate_state("up") == false  # Case-sensitive
            end

            @testset "Criticality validation" begin
                @test validate_criticality("critical") == true
                @test validate_criticality("high") == true
                @test validate_criticality("medium") == true
                @test validate_criticality("low") == true
                @test validate_criticality("CRITICAL") == false  # Case-sensitive
                @test validate_criticality("urgent") == false
                @test validate_criticality("") == false
            end

            @testset "VALID_STATES constant" begin
                @test "UP" in VALID_STATES
                @test "UP_WITH_ISSUES" in VALID_STATES
                @test "MAINTENANCE" in VALID_STATES
                @test "DOWN" in VALID_STATES
                @test length(VALID_STATES) == 4
            end

            @testset "VALID_CRITICALITIES constant" begin
                @test "critical" in VALID_CRITICALITIES
                @test "high" in VALID_CRITICALITIES
                @test "medium" in VALID_CRITICALITIES
                @test "low" in VALID_CRITICALITIES
                @test length(VALID_CRITICALITIES) == 4
            end

            @testset "Tool creation and retrieval" begin
                # Create a test tool
                tool = Tool(
                    name = "ASML-001",
                    area = "Litho",
                    bay = "Bay 1",
                    criticality = "critical",
                    is_active = true,
                    current_state = "UP"
                )

                # Save to database
                saved_tool = SearchLight.save!(tool)
                @test saved_tool.id.value !== nothing

                # Retrieve from database
                retrieved = SearchLight.findone(Tool; id = saved_tool.id.value)
                @test retrieved !== nothing
                @test retrieved.name == "ASML-001"
                @test retrieved.area == "Litho"
                @test retrieved.bay == "Bay 1"
                @test retrieved.criticality == "critical"
                @test retrieved.is_active == true
                @test retrieved.current_state == "UP"
            end

            @testset "Tool with status fields" begin
                # Create tool with status information
                tool = Tool(
                    name = "Etch-002",
                    area = "Etch",
                    bay = "Bay 2",
                    criticality = "high",
                    is_active = true,
                    current_state = "DOWN",
                    current_issue_description = "PM required",
                    current_comment = "Scheduled maintenance",
                    current_eta_to_up = "2026-01-23T08:00:00"
                )

                saved = SearchLight.save!(tool)
                retrieved = SearchLight.findone(Tool; id = saved.id.value)

                @test retrieved.current_state == "DOWN"
                @test retrieved.current_issue_description == "PM required"
                @test retrieved.current_comment == "Scheduled maintenance"
                @test retrieved.current_eta_to_up == "2026-01-23T08:00:00"
            end

            @testset "Find active tools" begin
                # Clear and create fresh tools
                SearchLight.delete_all(Tool)

                tool1 = Tool(name = "Tool-A", area = "Area1", is_active = true)
                tool2 = Tool(name = "Tool-B", area = "Area1", is_active = true)
                tool3 = Tool(name = "Tool-C", area = "Area2", is_active = false)  # Inactive

                SearchLight.save!(tool1)
                SearchLight.save!(tool2)
                SearchLight.save!(tool3)

                active = find_active_tools()
                @test length(active) == 2
                @test all(t -> t.is_active, active)
            end

            @testset "Find by area" begin
                # Already have tools from previous test
                area1_tools = find_by_area("Area1")
                @test length(area1_tools) == 2
                @test all(t -> t.area == "Area1", area1_tools)
            end

            @testset "Find down tools" begin
                # Clear and create fresh tools
                SearchLight.delete_all(Tool)

                tool_up = Tool(name = "Tool-Up", area = "Test", current_state = "UP", is_active = true)
                tool_down1 = Tool(name = "Tool-Down1", area = "Test", current_state = "DOWN", is_active = true)
                tool_down2 = Tool(name = "Tool-Down2", area = "Test", current_state = "DOWN", is_active = true)
                tool_down_inactive = Tool(name = "Tool-Inactive", area = "Test", current_state = "DOWN", is_active = false)

                SearchLight.save!(tool_up)
                SearchLight.save!(tool_down1)
                SearchLight.save!(tool_down2)
                SearchLight.save!(tool_down_inactive)

                down_tools = find_down_tools()
                @test length(down_tools) == 2  # Only active DOWN tools
                @test all(t -> t.current_state == "DOWN" && t.is_active, down_tools)
            end

            @testset "Tool fields default values" begin
                tool = Tool()
                # Check default values
                @test tool.name == ""
                @test tool.area == ""
                @test tool.bay == ""
                @test tool.criticality == "medium"
                @test tool.is_active == true
                @test tool.current_state == "UP"
                @test tool.current_issue_description == ""
                @test tool.current_comment == ""
                @test tool.current_eta_to_up == ""
                @test !isempty(tool.created_at)  # Should have default timestamp
                @test !isempty(tool.updated_at)  # Should have default timestamp
            end

            # Cleanup (handles Windows SQLite file locking)
            cleanup_test_database(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end

        @testset "StatusEvent Model" begin
            # Use a temp file for model testing
            test_db_path = joinpath(tempdir(), "test_status_event_model_$(rand(UInt32)).sqlite")
            ENV["DATABASE_PATH"] = test_db_path

            # Include database configuration and connect
            include(joinpath(@__DIR__, "..", "config", "database.jl"))
            @test connect_database() == true

            # Include models
            include(joinpath(@__DIR__, "..", "src", "models", "User.jl"))
            include(joinpath(@__DIR__, "..", "src", "models", "Tool.jl"))
            include(joinpath(@__DIR__, "..", "src", "models", "StatusEvent.jl"))
            using .Users: User
            using .Tools: Tool
            using .StatusEvents: StatusEvent, VALID_STATES, validate_state, find_by_tool_id,
                                 find_by_tool_id_in_range, find_latest_by_tool_id, find_by_user_id,
                                 create_status_event!

            # Run migrations to create all tables
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122195602_create_users.jl"))
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122201046_create_tools.jl"))
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122203749_create_status_events.jl"))
            CreateUsers.up()
            CreateTools.up()
            CreateStatusEvents.up()

            # Create test user and tool for FK references
            test_user = User(
                username = "testoperator",
                password_hash = "hash123",
                name = "Test Operator",
                role = "operator"
            )
            SearchLight.save!(test_user)

            test_tool = Tool(
                name = "Test-Tool-001",
                area = "TestArea",
                bay = "Bay 1",
                criticality = "medium"
            )
            SearchLight.save!(test_tool)

            @testset "State validation" begin
                @test validate_state("UP") == true
                @test validate_state("UP_WITH_ISSUES") == true
                @test validate_state("MAINTENANCE") == true
                @test validate_state("DOWN") == true
                @test validate_state("UNKNOWN") == false
                @test validate_state("") == false
                @test validate_state("up") == false  # Case-sensitive
            end

            @testset "VALID_STATES constant" begin
                @test "UP" in VALID_STATES
                @test "UP_WITH_ISSUES" in VALID_STATES
                @test "MAINTENANCE" in VALID_STATES
                @test "DOWN" in VALID_STATES
                @test length(VALID_STATES) == 4
            end

            @testset "StatusEvent creation and retrieval" begin
                # Create a status event
                event = StatusEvent(
                    tool_id = test_tool.id,
                    state = "DOWN",
                    issue_description = "Vacuum pump failure",
                    comment = "Scheduled PM for tomorrow",
                    eta_to_up = "2026-01-23T08:00:00",
                    created_by_user_id = test_user.id
                )

                # Save to database
                saved_event = SearchLight.save!(event)
                @test saved_event.id.value !== nothing

                # Retrieve from database
                retrieved = SearchLight.findone(StatusEvent; id = saved_event.id.value)
                @test retrieved !== nothing
                @test retrieved.tool_id.value == test_tool.id.value
                @test retrieved.state == "DOWN"
                @test retrieved.issue_description == "Vacuum pump failure"
                @test retrieved.comment == "Scheduled PM for tomorrow"
                @test retrieved.eta_to_up == "2026-01-23T08:00:00"
                @test retrieved.created_by_user_id.value == test_user.id.value
                @test !isempty(retrieved.created_at)
            end

            @testset "create_status_event! helper" begin
                event = create_status_event!(
                    test_tool.id,
                    test_user.id,
                    "MAINTENANCE";
                    issue_description = "Scheduled PM",
                    comment = "Weekly maintenance"
                )

                @test event.id.value !== nothing
                @test event.state == "MAINTENANCE"
                @test event.issue_description == "Scheduled PM"

                # Test that ETA is cleared when state is UP
                up_event = create_status_event!(
                    test_tool.id,
                    test_user.id,
                    "UP";
                    eta_to_up = "2026-01-24T10:00:00"  # Should be ignored
                )
                @test up_event.eta_to_up == ""
            end

            @testset "Invalid state in create_status_event!" begin
                @test_throws ErrorException create_status_event!(
                    test_tool.id,
                    test_user.id,
                    "INVALID_STATE"
                )
            end

            @testset "find_by_tool_id" begin
                # Clear existing events
                SearchLight.delete_all(StatusEvent)

                # Create multiple events for the same tool
                create_status_event!(test_tool.id, test_user.id, "UP")
                sleep(0.01)  # Small delay to ensure different timestamps
                create_status_event!(test_tool.id, test_user.id, "DOWN"; issue_description = "Issue 1")
                sleep(0.01)
                create_status_event!(test_tool.id, test_user.id, "UP")

                events = find_by_tool_id(test_tool.id)
                @test length(events) == 3
                # Should be ordered by created_at descending (newest first)
                @test events[1].state == "UP"  # Most recent
                @test events[3].state == "UP"  # Oldest
            end

            @testset "find_latest_by_tool_id" begin
                latest = find_latest_by_tool_id(test_tool.id)
                @test latest !== nothing
                @test latest.state == "UP"  # Most recent event
            end

            @testset "find_by_user_id" begin
                events = find_by_user_id(test_user.id)
                @test length(events) >= 3  # At least the 3 we created
                @test all(e -> e.created_by_user_id.value == test_user.id.value, events)
            end

            @testset "StatusEvent fields default values" begin
                event = StatusEvent()
                @test event.state == "UP"
                @test event.issue_description == ""
                @test event.comment == ""
                @test event.eta_to_up == ""
                @test !isempty(event.created_at)  # Should have default timestamp
            end

            @testset "find_by_tool_id_in_range" begin
                # Clear and create events with specific timestamps
                SearchLight.delete_all(StatusEvent)

                # Events in range
                event1 = StatusEvent(
                    tool_id = test_tool.id,
                    state = "DOWN",
                    created_by_user_id = test_user.id,
                    created_at = "2026-01-15T10:00:00"
                )
                SearchLight.save!(event1)

                event2 = StatusEvent(
                    tool_id = test_tool.id,
                    state = "UP",
                    created_by_user_id = test_user.id,
                    created_at = "2026-01-20T10:00:00"
                )
                SearchLight.save!(event2)

                # Event outside range
                event3 = StatusEvent(
                    tool_id = test_tool.id,
                    state = "MAINTENANCE",
                    created_by_user_id = test_user.id,
                    created_at = "2026-01-10T10:00:00"
                )
                SearchLight.save!(event3)

                # Query for range 2026-01-14 to 2026-01-21
                events = find_by_tool_id_in_range(
                    test_tool.id,
                    "2026-01-14T00:00:00",
                    "2026-01-21T23:59:59"
                )

                @test length(events) == 2
                @test all(e -> e.state in ["DOWN", "UP"], events)
            end

            # Cleanup (handles Windows SQLite file locking)
            cleanup_test_database(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end

        @testset "Seed Data" begin
            # Use a temp file for seed testing
            test_db_path = joinpath(tempdir(), "test_seed_$(rand(UInt32)).sqlite")
            ENV["DATABASE_PATH"] = test_db_path

            # Include database configuration and connect
            include(joinpath(@__DIR__, "..", "config", "database.jl"))
            @test connect_database() == true

            # Run migrations to create all tables
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122195602_create_users.jl"))
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122201046_create_tools.jl"))
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122203749_create_status_events.jl"))
            CreateUsers.up()
            CreateTools.up()
            CreateStatusEvents.up()

            # Include the seed data module
            include(joinpath(@__DIR__, "..", "db", "seeds", "seed_data.jl"))

            @testset "hash_password function" begin
                # Test password hashing
                hash1 = hash_password("changeme")
                @test length(hash1) == 64  # SHA256 produces 64 hex characters
                @test hash1 == hash_password("changeme")  # Same password = same hash

                # Different passwords produce different hashes
                hash2 = hash_password("different")
                @test hash1 != hash2
            end

            @testset "seed_admin_user!" begin
                # First run should create admin
                admin = seed_admin_user!()
                @test admin !== nothing
                @test admin.username == "admin"
                @test admin.name == "System Administrator"
                @test admin.role == "admin"
                @test admin.is_active == true
                @test admin.password_hash == hash_password("changeme")

                # Second run should be idempotent (skip existing)
                admin2 = seed_admin_user!()
                @test admin2 === nothing

                # Verify only one admin exists
                using .Users: find_by_username
                existing = find_by_username("admin")
                @test existing !== nothing
                @test existing.id.value == admin.id.value
            end

            @testset "seed_sample_tools!" begin
                # First run should create tools
                tools = seed_sample_tools!()
                @test length(tools) == 5

                # Verify tool properties
                tool_names = [t.name for t in tools]
                @test "CVD-01" in tool_names
                @test "ETCH-01" in tool_names
                @test "LITH-01" in tool_names
                @test "IMPL-01" in tool_names
                @test "CLEAN-01" in tool_names

                # Verify states
                using .Tools: Tool
                etch = SearchLight.find(Tool, SQLWhereExpression("name = ?", "ETCH-01"))
                @test !isempty(etch)
                @test first(etch).current_state == "DOWN"
                @test first(etch).current_issue_description == "RF generator failure"

                lith = SearchLight.find(Tool, SQLWhereExpression("name = ?", "LITH-01"))
                @test !isempty(lith)
                @test first(lith).current_state == "UP_WITH_ISSUES"

                # Second run should be idempotent (skip existing)
                tools2 = seed_sample_tools!()
                @test length(tools2) == 0  # No new tools created

                # Verify total count unchanged
                all_tools = SearchLight.all(Tool)
                @test length(all_tools) == 5
            end

            @testset "seed! main function" begin
                # Clear database
                using .Users: User
                using .Tools: Tool
                SearchLight.delete_all(Tool)
                SearchLight.delete_all(User)

                # Run full seed
                seed!()

                # Verify admin user created
                admin = SearchLight.find(User, SQLWhereExpression("username = ?", "admin"))
                @test length(admin) == 1

                # Verify tools created
                tools = SearchLight.all(Tool)
                @test length(tools) == 5

                # Verify idempotency - run again
                seed!()

                # Counts should remain the same
                admin_count = length(SearchLight.find(User, SQLWhereExpression("username = ?", "admin")))
                tool_count = length(SearchLight.all(Tool))
                @test admin_count == 1
                @test tool_count == 5
            end

            # Cleanup (handles Windows SQLite file locking)
            cleanup_test_database(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end
    end

    @testset "Controllers" begin
        @testset "DashboardController" begin
            @testset "DashboardController file exists" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                @test isfile(controller_file)

                # Verify key functions are defined
                controller_content = read(controller_file, String)
                @test occursin("module DashboardController", controller_content)
                @test occursin("function index", controller_content)
                @test occursin("find_active_tools", controller_content)
                @test occursin("state_sort_order", controller_content)
                @test occursin("truncate_text", controller_content)
                @test occursin("format_timestamp", controller_content)
                @test occursin("state_css_class", controller_content)
                @test occursin("state_display_text", controller_content)
            end

            @testset "Dashboard view template exists" begin
                view_file = joinpath(@__DIR__, "..", "src", "views", "dashboard", "index.jl.html")
                @test isfile(view_file)

                # Verify key elements are present
                view_content = read(view_file, String)
                @test occursin("Equipment Status Dashboard", view_content)
                @test occursin("<table", view_content)
                @test occursin("status-badge", view_content)
                @test occursin("tool-row", view_content)
                @test occursin("/tools/", view_content)  # Links to tool detail
            end

            @testset "Dashboard route defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                @test occursin("DashboardController", routes_content)
                @test occursin("/dashboard", routes_content)
            end

            @testset "Dashboard styling" begin
                css_file = joinpath(@__DIR__, "..", "public", "css", "qci.css")
                css_content = read(css_file, String)

                # Check for dashboard-specific styles
                @test occursin(".dashboard-card", css_content)
                @test occursin(".tool-row", css_content)
                @test occursin(".tool-row-status-down", css_content)
                @test occursin(".tool-row-status-up", css_content)
                @test occursin(".tool-row-status-maintenance", css_content)
                @test occursin(".tool-row-status-up-with-issues", css_content)
            end

            @testset "Helper functions" begin
                # Include the controller to test helper functions
                include(joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl"))
                using .DashboardController: state_sort_order, truncate_text, format_timestamp,
                                            state_css_class, state_display_text

                @testset "state_sort_order" begin
                    @test state_sort_order("DOWN") == 1
                    @test state_sort_order("MAINTENANCE") == 2
                    @test state_sort_order("UP_WITH_ISSUES") == 3
                    @test state_sort_order("UP") == 4
                    @test state_sort_order("UNKNOWN") == 5
                end

                @testset "truncate_text" begin
                    @test truncate_text("short") == "short"
                    @test truncate_text("a" ^ 100, 50) == ("a" ^ 47) * "..."
                    @test truncate_text("exactly50chars" * "a" ^ 36, 50) == "exactly50chars" * "a" ^ 36  # Exactly 50, no truncation
                    @test truncate_text("exactly51chars" * "a" ^ 37, 50) == "exactly51chars" * "a" ^ 33 * "..."  # 51 chars gets truncated
                    @test truncate_text("", 50) == ""
                end

                @testset "format_timestamp" begin
                    @test format_timestamp("2026-01-22T14:30:00") == "2026-01-22 14:30"
                    @test format_timestamp("") == ""
                    @test format_timestamp("short") == "short"  # Handles invalid gracefully
                end

                @testset "state_css_class" begin
                    @test state_css_class("UP") == "status-up"
                    @test state_css_class("DOWN") == "status-down"
                    @test state_css_class("MAINTENANCE") == "status-maintenance"
                    @test state_css_class("UP_WITH_ISSUES") == "status-up-with-issues"
                    @test state_css_class("UNKNOWN") == ""
                end

                @testset "state_display_text" begin
                    @test state_display_text("UP") == "Up"
                    @test state_display_text("DOWN") == "Down"
                    @test state_display_text("MAINTENANCE") == "Maintenance"
                    @test state_display_text("UP_WITH_ISSUES") == "Up with Issues"
                    @test state_display_text("UNKNOWN") == "UNKNOWN"  # Fallback to raw value
                end
            end

            @testset "Filter and sort functions" begin
                # Use a temp file for filter/sort testing
                test_db_path = joinpath(tempdir(), "test_filter_sort_$(rand(UInt32)).sqlite")
                ENV["DATABASE_PATH"] = test_db_path

                # Include database configuration and connect
                include(joinpath(@__DIR__, "..", "config", "database.jl"))
                @test connect_database() == true

                # Include the Tool model and run migration
                include(joinpath(@__DIR__, "..", "src", "models", "Tool.jl"))
                using .Tools: Tool, VALID_STATES
                include(joinpath(@__DIR__, "..", "db", "migrations", "20260122201046_create_tools.jl"))
                CreateTools.up()

                # Define filter/sort functions locally for testing
                # (Avoiding the need to load entire DashboardController with auth dependencies)

                function test_get_unique_areas(tools)::Vector{String}
                    areas = unique([t.area for t in tools])
                    sort!(areas)
                    return areas
                end

                function test_filter_tools(tools, state_filter::String, area_filter::String, search::String)
                    filtered = tools
                    if !isempty(state_filter) && state_filter != "all"
                        filtered = filter(t -> t.current_state == state_filter, filtered)
                    end
                    if !isempty(area_filter) && area_filter != "all"
                        filtered = filter(t -> t.area == area_filter, filtered)
                    end
                    if !isempty(search)
                        search_lower = lowercase(search)
                        filtered = filter(t -> occursin(search_lower, lowercase(t.name)), filtered)
                    end
                    return collect(filtered)
                end

                function test_state_sort_order(state::String)::Int
                    order = Dict("DOWN" => 1, "MAINTENANCE" => 2, "UP_WITH_ISSUES" => 3, "UP" => 4)
                    return get(order, state, 5)
                end

                function test_sort_tools(tools, sort_col::String, sort_dir::String)
                    sort_columns = Dict(
                        "name" => :name,
                        "area" => :area,
                        "state" => :current_state,
                        "updated" => :current_status_updated_at,
                        "eta" => :current_eta_to_up
                    )
                    if !haskey(sort_columns, sort_col)
                        sort_col = "state"
                    end
                    if sort_dir != "asc" && sort_dir != "desc"
                        sort_dir = "asc"
                    end
                    field = sort_columns[sort_col]
                    if sort_col == "state"
                        key_fn = t -> test_state_sort_order(t.current_state)
                    elseif sort_col == "eta"
                        key_fn = t -> (isempty(t.current_eta_to_up) ? 1 : 0, t.current_eta_to_up)
                    elseif sort_col == "updated"
                        key_fn = t -> (isempty(t.current_status_updated_at) ? 1 : 0, t.current_status_updated_at)
                    else
                        key_fn = t -> lowercase(getfield(t, field))
                    end
                    return sort(tools, by = key_fn, rev = (sort_dir == "desc"))
                end

                function test_build_query_string(params::Dict; exclude::Vector{String}=String[])::String
                    filtered = filter(kv -> !(string(kv[1]) in exclude) && !isempty(string(kv[2])), params)
                    if isempty(filtered)
                        return ""
                    end
                    return "?" * join(["$(k)=$(v)" for (k, v) in filtered], "&")
                end

                function test_get_sort_url(current_params::Dict, column::String, current_sort::String, current_dir::String)::String
                    new_params = copy(current_params)
                    new_params["sort"] = column
                    if column == current_sort
                        new_params["dir"] = (current_dir == "asc") ? "desc" : "asc"
                    else
                        new_params["dir"] = "asc"
                    end
                    return "/dashboard" * test_build_query_string(new_params)
                end

                # Create test tools
                SearchLight.delete_all(Tool)

                tool1 = Tool(name = "ASML-001", area = "Litho", current_state = "UP", is_active = true)
                tool2 = Tool(name = "Etch-001", area = "Etch", current_state = "DOWN", is_active = true)
                tool3 = Tool(name = "CVD-001", area = "Deposition", current_state = "MAINTENANCE", is_active = true)
                tool4 = Tool(name = "ASML-002", area = "Litho", current_state = "UP_WITH_ISSUES", is_active = true)
                tool5 = Tool(name = "Clean-001", area = "Cleaning", current_state = "UP", is_active = true)

                SearchLight.save!(tool1)
                SearchLight.save!(tool2)
                SearchLight.save!(tool3)
                SearchLight.save!(tool4)
                SearchLight.save!(tool5)

                tools = SearchLight.all(Tool)

                @testset "get_unique_areas" begin
                    areas = test_get_unique_areas(tools)
                    @test length(areas) == 4
                    @test "Cleaning" in areas
                    @test "Deposition" in areas
                    @test "Etch" in areas
                    @test "Litho" in areas
                    # Should be sorted alphabetically
                    @test areas == ["Cleaning", "Deposition", "Etch", "Litho"]
                end

                @testset "filter_tools - by state" begin
                    # Filter by DOWN state
                    filtered = test_filter_tools(tools, "DOWN", "", "")
                    @test length(filtered) == 1
                    @test filtered[1].name == "Etch-001"

                    # Filter by UP state
                    filtered = test_filter_tools(tools, "UP", "", "")
                    @test length(filtered) == 2
                    @test all(t -> t.current_state == "UP", filtered)

                    # No filter (all states)
                    filtered = test_filter_tools(tools, "", "", "")
                    @test length(filtered) == 5

                    # "all" should show all
                    filtered = test_filter_tools(tools, "all", "", "")
                    @test length(filtered) == 5
                end

                @testset "filter_tools - by area" begin
                    # Filter by Litho area
                    filtered = test_filter_tools(tools, "", "Litho", "")
                    @test length(filtered) == 2
                    @test all(t -> t.area == "Litho", filtered)

                    # Filter by Etch area
                    filtered = test_filter_tools(tools, "", "Etch", "")
                    @test length(filtered) == 1
                    @test filtered[1].name == "Etch-001"
                end

                @testset "filter_tools - by search" begin
                    # Search for "ASML"
                    filtered = test_filter_tools(tools, "", "", "ASML")
                    @test length(filtered) == 2
                    @test all(t -> occursin("ASML", t.name), filtered)

                    # Search is case-insensitive
                    filtered = test_filter_tools(tools, "", "", "asml")
                    @test length(filtered) == 2

                    # Search for "001"
                    filtered = test_filter_tools(tools, "", "", "001")
                    @test length(filtered) == 4

                    # Search for non-existent tool
                    filtered = test_filter_tools(tools, "", "", "nonexistent")
                    @test length(filtered) == 0
                end

                @testset "filter_tools - combined filters" begin
                    # Filter by state AND area
                    filtered = test_filter_tools(tools, "UP", "Litho", "")
                    @test length(filtered) == 1
                    @test filtered[1].name == "ASML-001"

                    # Filter by area AND search
                    filtered = test_filter_tools(tools, "", "Litho", "001")
                    @test length(filtered) == 1
                    @test filtered[1].name == "ASML-001"

                    # Filter by all three
                    filtered = test_filter_tools(tools, "UP_WITH_ISSUES", "Litho", "ASML")
                    @test length(filtered) == 1
                    @test filtered[1].name == "ASML-002"
                end

                @testset "sort_tools - by name" begin
                    sorted = test_sort_tools(tools, "name", "asc")
                    names = [t.name for t in sorted]
                    # Sorted case-insensitively: "asml" < "clean" < "cvd" < "etch"
                    @test names == ["ASML-001", "ASML-002", "Clean-001", "CVD-001", "Etch-001"]

                    sorted = test_sort_tools(tools, "name", "desc")
                    names = [t.name for t in sorted]
                    @test names == ["Etch-001", "CVD-001", "Clean-001", "ASML-002", "ASML-001"]
                end

                @testset "sort_tools - by area" begin
                    sorted = test_sort_tools(tools, "area", "asc")
                    areas = [t.area for t in sorted]
                    @test areas[1] == "Cleaning"
                    @test areas[end] == "Litho"
                end

                @testset "sort_tools - by state" begin
                    # Default state sort: DOWN first, UP last
                    sorted = test_sort_tools(tools, "state", "asc")
                    states = [t.current_state for t in sorted]
                    @test states[1] == "DOWN"  # DOWN first
                    @test states[end] in ["UP"]  # UP last

                    # Descending: UP first, DOWN last
                    sorted = test_sort_tools(tools, "state", "desc")
                    states = [t.current_state for t in sorted]
                    @test states[1] in ["UP"]
                    @test states[end] == "DOWN"
                end

                @testset "sort_tools - invalid column defaults to state" begin
                    sorted = test_sort_tools(tools, "invalid_column", "asc")
                    states = [t.current_state for t in sorted]
                    @test states[1] == "DOWN"  # Default state sorting
                end

                @testset "build_query_string" begin
                    params = Dict("state" => "DOWN", "area" => "Litho")
                    qs = test_build_query_string(params)
                    @test occursin("state=DOWN", qs)
                    @test occursin("area=Litho", qs)
                    @test startswith(qs, "?")

                    # Empty values are excluded
                    params = Dict("state" => "DOWN", "area" => "")
                    qs = test_build_query_string(params)
                    @test occursin("state=DOWN", qs)
                    @test !occursin("area=", qs)

                    # Empty params returns empty string
                    params = Dict{String, String}()
                    qs = test_build_query_string(params)
                    @test qs == ""
                end

                @testset "get_sort_url" begin
                    params = Dict{String, String}("state" => "DOWN")

                    # Clicking new column sets asc
                    url = test_get_sort_url(params, "name", "state", "asc")
                    @test occursin("sort=name", url)
                    @test occursin("dir=asc", url)
                    @test occursin("state=DOWN", url)

                    # Clicking same column toggles direction
                    url = test_get_sort_url(params, "state", "state", "asc")
                    @test occursin("dir=desc", url)

                    url = test_get_sort_url(params, "state", "state", "desc")
                    @test occursin("dir=asc", url)
                end

                # Cleanup (handles Windows SQLite file locking)
                cleanup_test_database(test_db_path)
                delete!(ENV, "DATABASE_PATH")
            end

            @testset "Dashboard view with filters" begin
                view_file = joinpath(@__DIR__, "..", "src", "views", "dashboard", "index.jl.html")
                @test isfile(view_file)

                view_content = read(view_file, String)

                # Check filter form elements
                @test occursin("filter-form", view_content)
                @test occursin("name=\"state\"", view_content)
                @test occursin("name=\"area\"", view_content)
                @test occursin("name=\"search\"", view_content)
                @test occursin("type=\"submit\"", view_content)

                # Check sortable headers
                @test occursin("sortable-header", view_content)
                @test occursin("sort-link", view_content)
                @test occursin("sort-indicator", view_content)
                @test occursin("sort_urls", view_content)

                # Check filter state persistence in URL
                @test occursin("state_filter", view_content)
                @test occursin("area_filter", view_content)
            end

            @testset "Dashboard CSS for filters and sorting" begin
                css_file = joinpath(@__DIR__, "..", "public", "css", "qci.css")
                css_content = read(css_file, String)

                # Check filter styles
                @test occursin(".filter-card", css_content)
                @test occursin(".filter-form", css_content)
                @test occursin(".filter-row", css_content)
                @test occursin(".filter-group", css_content)

                # Check sortable header styles
                @test occursin(".sortable-header", css_content)
                @test occursin(".sort-link", css_content)
                @test occursin(".sort-indicator", css_content)
            end
        end
    end

    @testset "API" begin
        @testset "ApiHelpers module" begin
            @testset "api_helpers.jl file exists" begin
                helpers_file = joinpath(@__DIR__, "..", "src", "lib", "api_helpers.jl")
                @test isfile(helpers_file)

                # Verify key functions are defined
                helpers_content = read(helpers_file, String)
                @test occursin("module ApiHelpers", helpers_content)
                @test occursin("api_success", helpers_content)
                @test occursin("api_error", helpers_content)
                @test occursin("api_unauthorized", helpers_content)
                @test occursin("api_forbidden", helpers_content)
                @test occursin("api_not_found", helpers_content)
                @test occursin("api_bad_request", helpers_content)
            end

            @testset "API helper functions" begin
                # Include the API helpers module
                include(joinpath(@__DIR__, "..", "src", "lib", "api_helpers.jl"))
                using .ApiHelpers: api_success, api_error, api_unauthorized, api_forbidden,
                                   api_not_found, api_bad_request

                # Helper function to get header value from Genie response
                function get_header(response, name)
                    for (k, v) in response.headers
                        if lowercase(k) == lowercase(name)
                            return v
                        end
                    end
                    return nothing
                end

                # Helper function to extract JSON from Genie response body
                # The response body contains the full HTTP response text, so we extract the JSON part
                function extract_json(response)
                    body_str = String(response.body)
                    # Find the JSON object (starts with { and ends with })
                    json_start = findlast('{', body_str)
                    json_end = findlast('}', body_str)
                    if json_start !== nothing && json_end !== nothing
                        return JSON3.read(body_str[json_start:json_end])
                    end
                    return nothing
                end

                # Test api_success returns correct status and content type
                response = api_success(Dict("data" => "test"))
                @test response.status == 200
                @test startswith(get_header(response, "Content-Type"), "application/json")
                body = extract_json(response)
                @test body.data == "test"

                # Test api_success with custom status
                response = api_success(Dict("created" => true), status=201)
                @test response.status == 201

                # Test api_error returns correct format
                response = api_error("Something went wrong")
                @test response.status == 500
                @test startswith(get_header(response, "Content-Type"), "application/json")
                body = extract_json(response)
                @test body.error == "Something went wrong"

                # Test api_error with custom status
                response = api_error("Custom error", status=418)
                @test response.status == 418

                # Test api_unauthorized
                response = api_unauthorized()
                @test response.status == 401
                body = extract_json(response)
                @test body.error == "Unauthorized"

                response = api_unauthorized("Session expired")
                body = extract_json(response)
                @test body.error == "Session expired"

                # Test api_forbidden
                response = api_forbidden()
                @test response.status == 403
                body = extract_json(response)
                @test body.error == "Forbidden"

                response = api_forbidden("Admin access required")
                body = extract_json(response)
                @test body.error == "Admin access required"

                # Test api_not_found
                response = api_not_found()
                @test response.status == 404
                body = extract_json(response)
                @test body.error == "Not found"

                response = api_not_found("Tool not found")
                body = extract_json(response)
                @test body.error == "Tool not found"

                # Test api_bad_request
                response = api_bad_request()
                @test response.status == 400
                body = extract_json(response)
                @test body.error == "Bad request"

                response = api_bad_request("Invalid JSON")
                body = extract_json(response)
                @test body.error == "Invalid JSON"
            end

            @testset "Controllers use ApiHelpers" begin
                # Check DashboardController uses ApiHelpers
                dashboard_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                dashboard_content = read(dashboard_file, String)
                @test occursin("using .ApiHelpers", dashboard_content)
                @test occursin("api_success", dashboard_content)

                # Check AuthController uses ApiHelpers
                auth_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                auth_content = read(auth_file, String)
                @test occursin("using .ApiHelpers", auth_content)
                @test occursin("api_success", auth_content)
                @test occursin("api_bad_request", auth_content)
                @test occursin("api_unauthorized", auth_content)

                # Check auth_helpers uses ApiHelpers
                helpers_file = joinpath(@__DIR__, "..", "src", "lib", "auth_helpers.jl")
                helpers_content = read(helpers_file, String)
                @test occursin("using .ApiHelpers", helpers_content)
                @test occursin("api_unauthorized", helpers_content)
            end
        end

        @testset "DashboardController API" begin
            @testset "api_index function exists" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                controller_content = read(controller_file, String)

                # Verify api_index function is defined
                @test occursin("function api_index", controller_content)
                @test occursin("export", controller_content) && occursin("api_index", controller_content)
                @test occursin("json", controller_content)  # Uses JSON rendering
            end

            @testset "API route defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                @test occursin("/api/tools", routes_content)
                @test occursin("api_index", routes_content)
                @test occursin("require_authentication_api", routes_content)
            end

            @testset "API auth helper exists" begin
                helpers_file = joinpath(@__DIR__, "..", "src", "lib", "auth_helpers.jl")
                helpers_content = read(helpers_file, String)

                @test occursin("require_authentication_api", helpers_content)
                @test occursin("401", helpers_content)  # Returns 401 for unauth
                @test occursin("Unauthorized", helpers_content)
            end

            @testset "api_show function exists" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                controller_content = read(controller_file, String)

                # Verify api_show function is defined
                @test occursin("function api_show", controller_content)
                @test occursin("export", controller_content) && occursin("api_show", controller_content)

                # Verify it returns proper tool fields
                @test occursin("\"name\"", controller_content)
                @test occursin("\"area\"", controller_content)
                @test occursin("\"bay\"", controller_content)
                @test occursin("\"criticality\"", controller_content)
                @test occursin("\"state\"", controller_content)
                @test occursin("\"issue_description\"", controller_content)
                @test occursin("\"comment\"", controller_content)
                @test occursin("\"eta_to_up\"", controller_content)
                @test occursin("\"status_updated_at\"", controller_content)
                @test occursin("\"status_updated_by\"", controller_content)

                # Verify error handling
                @test occursin("Tool not found", controller_content)
                @test occursin("status=404", controller_content)
            end

            @testset "api_show route defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                @test occursin("/api/tools/:id", routes_content)
                @test occursin("api_show", routes_content)
                @test occursin("require_authentication_api", routes_content)
            end

            @testset "api_update_status function exists" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                controller_content = read(controller_file, String)

                # Verify api_update_status function is defined
                @test occursin("function api_update_status", controller_content)
                @test occursin("export", controller_content) && occursin("api_update_status", controller_content)

                # Verify it accepts required fields
                @test occursin("state", controller_content)
                @test occursin("issue_description", controller_content)
                @test occursin("comment", controller_content)
                @test occursin("eta_to_up", controller_content)

                # Verify it creates StatusEvent
                @test occursin("create_status_event!", controller_content)

                # Verify it updates Tool status
                @test occursin("update_current_status!", controller_content)

                # Verify error handling
                @test occursin("State is required", controller_content)
                @test occursin("Invalid state", controller_content)
                @test occursin("api_bad_request", controller_content)
                @test occursin("api_not_found", controller_content)
            end

            @testset "api_update_status route defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                @test occursin("/api/tools/:id", routes_content)
                @test occursin("/status", routes_content)
                @test occursin("api_update_status", routes_content)
                @test occursin("method = POST", routes_content)
                @test occursin("require_authentication_api", routes_content)
            end

            @testset "api_update_status validation" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "DashboardController.jl")
                controller_content = read(controller_file, String)

                # Verify validates state is one of VALID_STATES
                @test occursin("validate_state", controller_content)
                @test occursin("Invalid state. Must be one of", controller_content)

                # Verify request body parsing
                @test occursin("jsonpayload", controller_content)
                @test occursin("Invalid JSON payload", controller_content)
                @test occursin("Request body is required", controller_content)

                # Verify tool lookup and 404 handling
                @test occursin("Tool not found", controller_content)
            end
        end

        @testset "AuthController API" begin
            @testset "API functions exist" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                controller_content = read(controller_file, String)

                # Verify api_login function is defined
                @test occursin("function api_login", controller_content)
                @test occursin("POST /api/auth/login", controller_content)
                @test occursin("jsonpayload", controller_content)

                # Verify api_logout function is defined
                @test occursin("function api_logout", controller_content)
                @test occursin("POST /api/auth/logout", controller_content)

                # Verify api_me function is defined
                @test occursin("function api_me", controller_content)
                @test occursin("GET /api/auth/me", controller_content)

                # Verify JSON rendering is used
                @test occursin("Genie.Renderer.Json: json", controller_content)
            end

            @testset "Auth API routes defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                # Verify all auth API routes are defined
                @test occursin("/api/auth/login", routes_content)
                @test occursin("/api/auth/logout", routes_content)
                @test occursin("/api/auth/me", routes_content)

                # Verify correct HTTP methods
                @test occursin("api_login", routes_content)
                @test occursin("api_logout", routes_content)
                @test occursin("api_me", routes_content)
            end

            @testset "Auth API response formats" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                controller_content = read(controller_file, String)

                # Verify login returns user data on success
                @test occursin("\"user\"", controller_content)
                @test occursin("\"id\"", controller_content)
                @test occursin("\"username\"", controller_content)
                @test occursin("\"name\"", controller_content)
                @test occursin("\"role\"", controller_content)

                # Verify logout returns success
                @test occursin("\"success\" => true", controller_content)

                # Verify error responses use api_helpers (consistent error handling)
                @test occursin("api_bad_request", controller_content)  # 400 Bad request
                @test occursin("api_unauthorized", controller_content)  # 401 Unauthorized
                @test occursin("api_error", controller_content)  # 500 Server error
            end

            @testset "Auth API input validation" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                controller_content = read(controller_file, String)

                # Verify empty credentials validation
                @test occursin("Username and password are required", controller_content)

                # Verify invalid credentials error
                @test occursin("Invalid username or password", controller_content)

                # Verify JSON parsing error handling
                @test occursin("Invalid JSON payload", controller_content)

                # Verify not authenticated error for api_me
                @test occursin("Not authenticated", controller_content)
            end
        end
    end

    @testset "Authentication" begin
        @testset "AuthCore - Password Hashing" begin
            # Include only the AuthCore module (no Genie dependencies)
            include(joinpath(@__DIR__, "..", "src", "lib", "AuthCore.jl"))
            using .AuthCore: hash_password, verify_password

            @testset "hash_password function" begin
                # Test hashing produces consistent results
                hash1 = hash_password("testpassword")
                hash2 = hash_password("testpassword")
                @test hash1 == hash2

                # Test hashing produces 64 hex characters (SHA256)
                @test length(hash1) == 64

                # Test different passwords produce different hashes
                hash3 = hash_password("differentpassword")
                @test hash1 != hash3

                # Test empty password can be hashed (but shouldn't be used in practice)
                hash_empty = hash_password("")
                @test length(hash_empty) == 64
            end

            @testset "verify_password function" begin
                password = "mysecretpassword"
                hash = hash_password(password)

                # Test correct password verifies
                @test verify_password(password, hash) == true

                # Test incorrect password fails
                @test verify_password("wrongpassword", hash) == false

                # Test empty password against non-empty hash
                @test verify_password("", hash) == false

                # Test invalid hash format (not 64 chars) returns false
                @test verify_password(password, "shorthash") == false
            end
        end

        @testset "User Authentication" begin
            # Use a temp file for auth testing
            test_db_path = joinpath(tempdir(), "test_auth_$(rand(UInt32)).sqlite")
            ENV["DATABASE_PATH"] = test_db_path

            # Include database configuration and connect
            include(joinpath(@__DIR__, "..", "config", "database.jl"))
            @test connect_database() == true

            # Run user migration
            include(joinpath(@__DIR__, "..", "db", "migrations", "20260122195602_create_users.jl"))
            CreateUsers.up()

            # Include models and auth core
            include(joinpath(@__DIR__, "..", "src", "models", "User.jl"))
            include(joinpath(@__DIR__, "..", "src", "lib", "AuthCore.jl"))
            using .Users: User, find_by_username
            using .AuthCore: hash_password, verify_password

            # Define authenticate_user function for testing
            # (This mirrors the function in authentication.jl but without session dependencies)
            function test_authenticate_user(username::String, password::String)
                user = find_by_username(username)
                if user === nothing
                    return nothing
                end
                if !user.is_active
                    return nothing
                end
                if !verify_password(password, user.password_hash)
                    return nothing
                end
                return user
            end

            @testset "authenticate_user function" begin
                test_user = User(
                    username = "authtest",
                    password_hash = hash_password("correctpassword"),
                    name = "Auth Test User",
                    role = "operator",
                    is_active = true
                )
                SearchLight.save!(test_user)

                # Test successful authentication
                auth_result = test_authenticate_user("authtest", "correctpassword")
                @test auth_result !== nothing
                @test auth_result.username == "authtest"

                # Test failed authentication - wrong password
                @test test_authenticate_user("authtest", "wrongpassword") === nothing

                # Test failed authentication - user not found
                @test test_authenticate_user("nonexistent", "anypassword") === nothing

                # Test inactive user cannot authenticate
                inactive_user = User(
                    username = "inactiveuser",
                    password_hash = hash_password("password123"),
                    name = "Inactive User",
                    role = "operator",
                    is_active = false
                )
                SearchLight.save!(inactive_user)
                @test test_authenticate_user("inactiveuser", "password123") === nothing
            end

            # Cleanup (handles Windows SQLite file locking)
            cleanup_test_database(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end

        @testset "Authentication Configuration" begin
            # Test that authentication module file exists and has expected structure
            auth_file = joinpath(@__DIR__, "..", "config", "initializers", "authentication.jl")
            @test isfile(auth_file)

            auth_content = read(auth_file, String)

            # Verify key components are present
            @test occursin("hash_password", auth_content)
            @test occursin("verify_password", auth_content)
            @test occursin("authenticate_user", auth_content)
            @test occursin("login!", auth_content)
            @test occursin("logout!", auth_content)
            @test occursin("current_user", auth_content)
            @test occursin("is_authenticated", auth_content)
            @test occursin("is_admin", auth_content)
            @test occursin("SESSION_TIMEOUT_SECONDS", auth_content)
            @test occursin("AUTH_USER_ID_KEY", auth_content)
            @test occursin("GenieSession", auth_content)

            # Test AuthCore module exists
            auth_core_file = joinpath(@__DIR__, "..", "src", "lib", "AuthCore.jl")
            @test isfile(auth_core_file)
        end

        @testset "Login Views and Routes" begin
            @testset "AuthController file exists" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                @test isfile(controller_file)

                # Verify key functions are defined
                controller_content = read(controller_file, String)
                @test occursin("login_form", controller_content)
                @test occursin("login", controller_content)
                @test occursin("logout", controller_content)
                @test occursin("module AuthController", controller_content)
            end

            @testset "Login view template exists" begin
                view_file = joinpath(@__DIR__, "..", "src", "views", "auth", "login.jl.html")
                @test isfile(view_file)

                # Verify key elements are present
                view_content = read(view_file, String)
                @test occursin("<form", view_content)
                @test occursin("action=\"/login\"", view_content)
                @test occursin("method=\"POST\"", view_content)
                @test occursin("username", view_content)
                @test occursin("password", view_content)
                @test occursin("type=\"submit\"", view_content)
                @test occursin("error_message", view_content)
            end

            @testset "Auth routes defined" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                @test isfile(routes_file)

                routes_content = read(routes_file, String)
                @test occursin("\"/login\"", routes_content)
                @test occursin("\"/logout\"", routes_content)
                @test occursin("GET", routes_content)
                @test occursin("POST", routes_content)
            end

            @testset "Login page styling" begin
                css_file = joinpath(@__DIR__, "..", "public", "css", "qci.css")
                css_content = read(css_file, String)

                # Check for login-specific styles
                @test occursin(".login-page", css_content)
                @test occursin(".login-card", css_content)
                @test occursin(".login-header", css_content)
                @test occursin(".btn-block", css_content)
            end
        end

        @testset "Route Protection (Auth Helpers)" begin
            @testset "auth_helpers.jl file exists" begin
                helpers_file = joinpath(@__DIR__, "..", "src", "lib", "auth_helpers.jl")
                @test isfile(helpers_file)

                # Verify key functions are defined
                helpers_content = read(helpers_file, String)
                @test occursin("module AuthHelpers", helpers_content)
                @test occursin("require_authentication", helpers_content)
                @test occursin("require_admin", helpers_content)
                @test occursin("current_user", helpers_content)
                @test occursin("is_authenticated", helpers_content)
                @test occursin("is_admin", helpers_content)
                @test occursin("store_redirect_url", helpers_content)
                @test occursin("get_redirect_url", helpers_content)
                @test occursin("check_session_timeout", helpers_content)
                @test occursin("REDIRECT_URL_KEY", helpers_content)
                @test occursin("LAST_ACTIVITY_KEY", helpers_content)
            end

            @testset "Routes use auth middleware" begin
                routes_file = joinpath(@__DIR__, "..", "config", "routes.jl")
                routes_content = read(routes_file, String)

                # Verify AuthHelpers is loaded
                @test occursin("using .AuthHelpers", routes_content)

                # Verify protected routes use require_authentication
                @test occursin("require_authentication", routes_content)

                # Verify dashboard route is protected
                @test occursin("/dashboard", routes_content)
            end

            @testset "AuthController uses redirect URL" begin
                controller_file = joinpath(@__DIR__, "..", "src", "controllers", "AuthController.jl")
                controller_content = read(controller_file, String)

                # Verify it imports get_redirect_url
                @test occursin("get_redirect_url", controller_content)

                # Verify it uses get_redirect_url after login
                @test occursin("redirect_url = get_redirect_url", controller_content)
            end

            @testset "Session timeout configuration" begin
                auth_file = joinpath(@__DIR__, "..", "config", "initializers", "authentication.jl")
                auth_content = read(auth_file, String)

                # Verify session timeout is configurable
                @test occursin("SESSION_TIMEOUT", auth_content)
                @test occursin("28800", auth_content)  # Default 8 hours
            end
        end
    end
end
