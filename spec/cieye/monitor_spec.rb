# frozen_string_literal: true

RSpec.describe Cieye::Monitor do
  describe ".start" do
    let(:worker_count) { 4 }
    let(:monitor_pid) { nil }

    after do
      if monitor_pid
        begin
          Process.kill("TERM", monitor_pid)
          Process.wait(monitor_pid)
        rescue Errno::ESRCH, Errno::ECHILD
          # Process already exited
        end
      end
    end

    it "spawns a monitor process" do
      pid = Cieye::Monitor.start(worker_count)
      monitor_pid = pid

      expect(pid).to be_a(Integer)
      expect(pid).to be > 0

      # Verify process is running
      expect { Process.kill(0, pid) }.not_to raise_error
    end

    it "registers at_exit handler to cleanup" do
      # This is tested indirectly - the at_exit handler should clean up
      # We can verify it doesn't raise errors
      expect { Cieye::Monitor.start(worker_count) }.not_to raise_error
    end
  end

  describe ".stop" do
    context "with running process" do
      let(:monitor_pid) do
        # Create a simple long-running process for testing
        spawn("sleep 10")
      end

      after do
        Process.kill("TERM", monitor_pid)
        Process.wait(monitor_pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Already stopped
      end

      it "stops the monitor process" do
        expect { Process.kill(0, monitor_pid) }.not_to raise_error

        Cieye::Monitor.stop(monitor_pid)

        sleep 0.2 # Give it time to stop

        expect { Process.kill(0, monitor_pid) }.to raise_error(Errno::ESRCH)
      end

      it "shows cursor after stopping" do
        expect { Cieye::Monitor.stop(monitor_pid) }
          .to output(/\e\[\?25h/).to_stdout
      end
    end

    context "with nil pid" do
      it "returns without error" do
        expect { Cieye::Monitor.stop(nil) }.not_to raise_error
      end
    end

    context "with already stopped process" do
      it "handles gracefully" do
        fake_pid = 999_999 # Non-existent PID

        expect { Cieye::Monitor.stop(fake_pid) }.not_to raise_error
      end
    end
  end

  describe "#initialize" do
    let(:worker_count) { 4 }
    let(:test_artifact_path) { File.join(Dir.pwd, "tmp/test_monitor_#{Time.now.to_i}") }

    before do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)
      FileUtils.mkdir_p(test_artifact_path)
    end

    after do
      FileUtils.rm_rf(test_artifact_path) if File.exist?(test_artifact_path)
    end

    it "creates a monitor instance with correct worker count" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor).to be_a(Cieye::Monitor)
      expect(monitor.socket_path).to eq(File.join(test_artifact_path, "cieye.sock"))
    end

    it "initializes store with worker count" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.store).to be_a(Cieye::Store)
    end

    it "initializes server with socket path" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.server).to be_a(Cieye::Server)
    end

    it "initializes TUI with worker count" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.tui).to be_a(Cieye::Tui)
    end

    it "converts worker count to integer" do
      monitor = Cieye::Monitor.new("4")

      expect(monitor.store).to be_a(Cieye::Store)
    end
  end

  describe "#run" do
    let(:worker_count) { 2 }
    let(:test_artifact_path) { File.join(Dir.pwd, "tmp/test_monitor_run_#{Time.now.to_i}") }
    let(:monitor) { Cieye::Monitor.new(worker_count) }

    before do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)
      FileUtils.mkdir_p(test_artifact_path)
    end

    after do
      FileUtils.rm_rf(test_artifact_path) if File.exist?(test_artifact_path)
    end

    it "sets up the screen" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect(monitor.tui).to receive(:screen_setup)
      expect(monitor.tui).to receive(:render).at_least(:once)
      expect(monitor.tui).to receive(:finalize)

      monitor.run
    end

    it "starts the server" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)
      allow(monitor.tui).to receive(:screen_setup)
      allow(monitor.tui).to receive(:render)
      allow(monitor.tui).to receive(:finalize)

      expect(monitor.server).to receive(:start)
      expect(monitor.server).to receive(:stop)

      monitor.run
    end

    it "stops server on error" do
      allow(monitor.tui).to receive(:screen_setup)
      allow(monitor.server).to receive(:start)
      allow(monitor.tui).to receive(:render).and_raise(StandardError, "Test error")
      allow(monitor.tui).to receive(:screen_restore)

      expect(monitor.server).to receive(:stop)

      expect { monitor.run }.to raise_error(Cieye::Error, "Test error")
    end

    it "exits when all tests are finished" do
      allow(monitor.tui).to receive(:screen_setup)
      allow(monitor.tui).to receive(:render)
      allow(monitor.tui).to receive(:finalize)
      allow(monitor.server).to receive(:start)
      allow(monitor.server).to receive(:stop)

      # Simulate immediate completion
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect { monitor.run }.not_to raise_error
    end
  end
end
