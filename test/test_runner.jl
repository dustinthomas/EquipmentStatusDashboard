# Test Runner Helper for MCP REPL
# Captures test output to a file to avoid overwhelming the REPL
# Usage: include("test/test_runner.jl"); run_tests()

module TestRunner

export run_tests, read_test_output, test_output_path

const TEST_OUTPUT_FILE = joinpath(@__DIR__, "..", "tmp", "test_output.log")

"""
    test_output_path()

Returns the path to the test output file.
"""
function test_output_path()
    TEST_OUTPUT_FILE
end

"""
    run_tests(; verbose=false)

Run the full test suite with output captured to a file.
Returns a summary dict with :passed, :failed, :total, and :duration.

If verbose=true, prints the last 50 lines of output after completion.
"""
function run_tests(; verbose::Bool=false)
    # Ensure tmp directory exists
    tmp_dir = dirname(TEST_OUTPUT_FILE)
    isdir(tmp_dir) || mkpath(tmp_dir)

    start_time = time()
    test_passed = false
    error_msg = nothing

    # Capture all output to file
    open(TEST_OUTPUT_FILE, "w") do io
        redirect_stdout(io) do
            redirect_stderr(io) do
                try
                    # Set test environment
                    ENV["GENIE_ENV"] = "test"
                    ENV["SEARCHLIGHT_ENV"] = "test"

                    # Run tests
                    include(joinpath(@__DIR__, "runtests.jl"))
                    test_passed = true
                catch e
                    error_msg = sprint(showerror, e, catch_backtrace())
                    println(io, "\n\n=== TEST ERROR ===")
                    println(io, error_msg)
                end
            end
        end
    end

    duration = round(time() - start_time, digits=1)

    # Parse output for summary
    output = read(TEST_OUTPUT_FILE, String)
    summary = parse_test_summary(output)
    summary[:duration] = duration
    summary[:output_file] = TEST_OUTPUT_FILE

    if error_msg !== nothing
        summary[:error] = true
    end

    # Print summary
    println("=== Test Results ===")
    println("Duration: $(duration)s")
    println("Passed: $(summary[:passed])")
    println("Failed: $(summary[:failed])")
    println("Total: $(summary[:total])")
    println("Output: $(TEST_OUTPUT_FILE)")

    if summary[:failed] > 0 || error_msg !== nothing
        println("\n⚠️  Tests had failures! Run `read_test_output()` to see details.")
    else
        println("\n✓ All tests passed!")
    end

    if verbose
        println("\n=== Last 50 lines of output ===")
        lines = split(output, '\n')
        for line in lines[max(1, end-49):end]
            println(line)
        end
    end

    summary
end

"""
    read_test_output(; lines=100, from_end=true)

Read test output from the log file.
- lines: number of lines to return (default 100)
- from_end: if true, return last N lines; if false, return first N lines
"""
function read_test_output(; lines::Int=100, from_end::Bool=true)
    if !isfile(TEST_OUTPUT_FILE)
        println("No test output file found. Run `run_tests()` first.")
        return nothing
    end

    content = read(TEST_OUTPUT_FILE, String)
    all_lines = split(content, '\n')

    if from_end
        selected = all_lines[max(1, end-lines+1):end]
    else
        selected = all_lines[1:min(lines, end)]
    end

    for line in selected
        println(line)
    end

    nothing
end

"""
Parse test output to extract pass/fail counts.
"""
function parse_test_summary(output::String)
    summary = Dict{Symbol,Any}(:passed => 0, :failed => 0, :total => 0)

    # Look for Test Summary line like: "Test Summary: | Pass  Total  Time"
    # Followed by results like: "EquipmentStatusDashboard |  640    640  34.6s"
    for line in split(output, '\n')
        # Match lines with test counts: "Name | Pass Fail Total Time" or "Name | Pass Total Time"
        m = match(r"\|\s*(\d+)\s+(\d+)\s+[\d.]+s\s*$", line)
        if m !== nothing
            if length(m.captures) >= 2
                passed = parse(Int, m.captures[1])
                total = parse(Int, m.captures[2])
                # Update if this is the main summary (largest total)
                if total > summary[:total]
                    summary[:passed] = passed
                    summary[:total] = total
                    summary[:failed] = total - passed
                end
            end
        end

        # Also check for explicit fail counts
        m2 = match(r"\|\s*(\d+)\s+(\d+)\s+(\d+)\s+[\d.]+s\s*$", line)
        if m2 !== nothing
            passed = parse(Int, m2.captures[1])
            failed = parse(Int, m2.captures[2])
            total = parse(Int, m2.captures[3])
            if total > summary[:total]
                summary[:passed] = passed
                summary[:failed] = failed
                summary[:total] = total
            end
        end
    end

    summary
end

end # module

using .TestRunner
