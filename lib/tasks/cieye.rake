# frozen_string_literal: true

require "cieye"
require "fileutils"

namespace :cieye do
  desc "Run specs with Cieye monitor"
  task :test do
    Cieye.monitor(4) do
      system(
        "bundle", "exec", "parallel_rspec",
        "-o", "-I lib -r cieye/adapters/rspec_adapter -f Cieye::Adapters::RSpecAdapter --out /dev/null",
        "spec/"
      )
    end
  end

  desc "Run specs with Cieye monitor (no HTML reports)"
  task :test_no_html do
    Cieye.monitor(4, generate_html: false) do
      system(
        "bundle", "exec", "parallel_rspec",
        "-o", "-I lib -r cieye/adapters/rspec_adapter -f Cieye::Adapters::RSpecAdapter --out /dev/null",
        "spec/"
      )
    end
  end

  desc "Run a simulated demo of Cieye using dynamic RSpec examples"
  task :demo do
    demo_dir = File.join(Dir.pwd, "tmp/cieye_demo")
    FileUtils.mkdir_p(demo_dir)
    spec_path = File.join(demo_dir, "demo_spec.rb")

    File.open(spec_path, "w") do |f|
      f.puts "require 'spec_helper' rescue nil"
      f.puts "RSpec.describe 'Cieye Demo' do"

      50.times do |i|
        f.puts "  it 'demo example #{i}' do"
        f.puts "    sleep(rand(0.05..0.2))"
        f.puts "    puts \"[LOG] Processing item #{i}...\" if rand < 0.3"
        f.puts "    warn \"[WARN] Potential issue in item #{i}\" if rand < 0.1"
        f.puts "    case rand(1..10)"
        f.puts "    when 1..7 then expect(true).to be(true)"
        f.puts "    when 8..9 then expect(false).to be(true)"
        f.puts "    else pending('Work in progress')"
        f.puts "    end"
        f.puts "  end"
      end

      f.puts "end"
    end

    begin
      Cieye.monitor(4) do
        system(
          "bundle", "exec", "parallel_rspec",
          spec_path,
          "-n", "4",
          "-o", "-I lib -I spec -r cieye/adapters/rspec_adapter -f Cieye::Adapters::RSpecAdapter --out /dev/null"
        )
      end
    ensure
      FileUtils.rm_rf(demo_dir)
    end
  end
end
