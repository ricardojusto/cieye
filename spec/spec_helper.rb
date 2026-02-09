# frozen_string_literal: true

require "cieye"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Silence Cieye::Logger globally so log output does not leak into rspec progress.
  # Individual specs that need to verify logger behaviour can override with
  # allow(...).and_call_original or expect(...).to receive(...).
  config.before do
    allow(Cieye::Logger).to receive(:info)
    allow(Cieye::Logger).to receive(:warn)
    allow(Cieye::Logger).to receive(:error)
    allow(Cieye::Logger).to receive(:deprecated)
  end
end
