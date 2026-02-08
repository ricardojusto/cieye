# Cieye - Agent Guide

This file provides a comprehensive overview of the `cieye` gem to help AI agents and developers understand the project's purpose, structure, and setup.

## Purpose and Problem Solving

`cieye` is designed to provide real-time visibility into Ruby test suite executions, solving several common pain points in modern CI/CD and local development:

- **Real-time Monitoring**: Offers a live Terminal User Interface (TUI) built with `lipgloss` to track test progress as it happens.
- **Support for Parallelism**: Specifically built to handle updates from multiple parallel workers, aggregate them, and display a unified status.
- **Low-Latency Communication**: Uses Unix sockets for extremely fast, low-overhead communication between test workers and the central monitor.
- **Automated Reporting**: Automatically generates HTML reports (`rspec_execution_report.html`) and JSON results for post-run analysis.
- **RSpec Integration**: Includes a ready-to-use RSpec adapter (`Cieye::Adapters::RSpecAdapter`) that hooks into the RSpec lifecycle.
- **Efficient UI**: The TUI provides clear visual cues for passes (green), failures (red), and pending tests (yellow), along with a summary of the current state.
- **Configurability**: Allows easy configuration of worker counts, artifact directories, and reporting options.

## Project Structure

```text
.
├── bin/
│   ├── cieye                   # Main executable
│   ├── test_with_cieye         # Test runner helper
│   ├── console                 # Interactive Ruby console
│   └── setup                   # Development environment setup
├── lib/
│   ├── cieye/                  # Core library logic
│   │   ├── adapters/           # Test framework adapters (e.g., RSpec)
│   │   ├── config/             # Configuration management
│   │   ├── templates/          # HTML report templates
│   │   ├── tui/                # TUI implementation details
│   │   ├── base.rb             # Base module definitions
│   │   ├── cleaner.rb          # Artifact and socket cleanup
│   │   ├── monitor.rb          # Central monitor process logic
│   │   ├── reporter.rb         # HTML and summary report generation
│   │   ├── server.rb           # Unix socket server
│   │   ├── socket_client.rb    # Client-side socket communication
│   │   ├── store.rb            # Real-time data storage and aggregation
│   │   ├── tui.rb              # Main TUI coordinator
│   │   └── version.rb          # Gem version
│   ├── tasks/                  # Rake tasks
│   └── cieye.rb                # Main entry point
├── spec/                       # RSpec test suite
│   ├── cieye/                  # Component-specific specs
│   └── spec_helper.rb          # RSpec configuration
├── sig/                        # RBS type signatures
├── cieye.gemspec               # Gem specification
├── Gemfile                     # Ruby dependencies
├── README.md                   # User documentation
└── AGENT.md                    # This file (Agent reference)
```
