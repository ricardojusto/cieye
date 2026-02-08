# frozen_string_literal: true

RSpec.describe Cieye::Monitor do
  describe ".start" do
    let(:worker_count) { 4 }
    let(:dummy_pid) { spawn("sleep 30") }

    before do
      allow(described_class).to receive(:spawn).and_return(dummy_pid)
    end

    after do
      Process.kill("TERM", dummy_pid)
      Process.wait(dummy_pid)
    rescue Errno::ESRCH, Errno::ECHILD
      # Already stopped
    end

    it "spawns a monitor process and returns a pid" do
      pid = described_class.start(worker_count)

      expect(pid).to be_a(Integer)
      expect(pid).to be > 0
      expect(pid).to eq(dummy_pid)
    end

    it "calls spawn with the monitor script and worker count" do
      expect(described_class).to receive(:spawn)
        .with(a_string_matching(/ruby.*monitor\.rb.*#{worker_count}/))
        .and_return(dummy_pid)

      described_class.start(worker_count)
    end
  end

  describe ".stop" do
    context "with a running process" do
      let(:monitor_pid) { spawn("sleep 30") }

      after do
        Process.kill("TERM", monitor_pid)
        Process.wait(monitor_pid)
      rescue Errno::ESRCH, Errno::ECHILD
        # Already stopped
      end

      it "stops the monitor process" do
        expect { Process.kill(0, monitor_pid) }.not_to raise_error

        Cieye::Monitor.stop(monitor_pid)

        sleep 0.2

        expect { Process.kill(0, monitor_pid) }.to raise_error(Errno::ESRCH)
      end

      it "restores cursor visibility after stopping" do
        expect { Cieye::Monitor.stop(monitor_pid) }
          .to output(/\e\[\?25h/).to_stdout
      end
    end

    context "with nil pid" do
      it "returns without error" do
        expect { Cieye::Monitor.stop(nil) }.not_to raise_error
      end
    end

    context "with an already stopped process" do
      it "handles gracefully" do
        fake_pid = 999_999

        expect { Cieye::Monitor.stop(fake_pid) }.not_to raise_error
      end
    end
  end

  describe "#initialize" do
    let(:worker_count) { 4 }
    let(:test_artifact_path) { File.join(Dir.pwd, "tmp/test_monitor_#{Process.pid}_#{Time.now.to_i}") }

    before do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)
      FileUtils.mkdir_p(test_artifact_path)
    end

    after do
      FileUtils.rm_rf(test_artifact_path) if File.exist?(test_artifact_path)
    end

    it "creates a monitor instance" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor).to be_a(Cieye::Monitor)
    end

    it "sets the socket path under the artifact directory" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.socket_path).to eq(File.join(test_artifact_path, "cieye.sock"))
    end

    it "initializes a Store" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.store).to be_a(Cieye::Store)
    end

    it "initializes a Server" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.server).to be_a(Cieye::Server)
    end

    it "initializes a Tui" do
      monitor = Cieye::Monitor.new(worker_count)

      expect(monitor.tui).to be_a(Cieye::Tui)
    end

    it "converts a string worker count to integer" do
      monitor = Cieye::Monitor.new("4")

      expect(monitor.store).to be_a(Cieye::Store)
    end
  end

  describe "#run" do
    let(:worker_count) { 2 }
    let(:test_artifact_path) { File.join(Dir.pwd, "tmp/test_monitor_run_#{Process.pid}_#{Time.now.to_i}") }
    let(:monitor) { Cieye::Monitor.new(worker_count) }

    before do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)
      FileUtils.mkdir_p(test_artifact_path)

      # Stub all TUI methods to prevent terminal hijacking
      allow(monitor.tui).to receive(:screen_setup)
      allow(monitor.tui).to receive(:screen_restore)
      allow(monitor.tui).to receive(:render)
      allow(monitor.tui).to receive(:finalize)
    end

    after do
      FileUtils.rm_rf(test_artifact_path) if File.exist?(test_artifact_path)
    end

    it "calls screen_setup on the TUI" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect(monitor.tui).to receive(:screen_setup)

      monitor.run
    end

    it "renders the TUI while running" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect(monitor.tui).to receive(:render).at_least(:once)

      monitor.run
    end

    it "finalizes the TUI when complete" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect(monitor.tui).to receive(:finalize).with(monitor.store)

      monitor.run
    end

    it "starts and stops the server" do
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect(monitor.server).to receive(:start)
      expect(monitor.server).to receive(:stop)

      monitor.run
    end

    it "exits when all tests are finished" do
      allow(monitor.server).to receive(:start)
      allow(monitor.server).to receive(:stop)
      allow(monitor.store).to receive(:all_finished?).and_return(true)

      expect { monitor.run }.not_to raise_error
    end

    it "restores screen and stops server on error" do
      allow(monitor.server).to receive(:start)
      allow(monitor.store).to receive(:all_finished?).and_raise(StandardError, "Test error")

      expect(monitor.tui).to receive(:screen_restore)
      expect(monitor.server).to receive(:stop)

      expect { monitor.run }.to raise_error(Cieye::Error, "Test error")
    end
  end
end
