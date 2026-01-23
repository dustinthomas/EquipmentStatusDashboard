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

            # Cleanup
            disconnect_database()
            isfile(test_db_path) && rm(test_db_path)
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

            # Cleanup
            disconnect_database()
            isfile(test_db_path) && rm(test_db_path)
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

            # Cleanup
            disconnect_database()
            isfile(test_db_path) && rm(test_db_path)
            delete!(ENV, "DATABASE_PATH")
        end
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
