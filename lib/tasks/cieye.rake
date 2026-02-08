# frozen_string_literal: true

require "cieye"

desc "Run specs with Cieye monitor"
task :spec_with_cieye do
  # Ensure we have parallel_tests installed
  unless system("which parallel_rspec > /dev/null 2>&1")
    puts "⚠️  parallel_tests gem not found. Installing..."
    system("gem install parallel_tests")
  end

  # Use Cieye to monitor the test run
  Cieye.monitor(4) do
    system("parallel_rspec -o '-I lib -r cieye/adapters/rspec_adapter -f Cieye::Adapters::RSpecAdapter --out /dev/null' spec/")
  end
end

desc "Run specs with Cieye monitor (no HTML reports)"
task :spec_with_cieye_no_html do
  Cieye.monitor(4, generate_html: false) do
    system("parallel_rspec -o '-I lib -r cieye/adapters/rspec_adapter -f Cieye::Adapters::RSpecAdapter --out /dev/null' spec/")
  end
end
