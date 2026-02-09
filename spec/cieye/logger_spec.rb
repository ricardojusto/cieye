# frozen_string_literal: true

RSpec.describe Cieye::Logger do
  before do
    allow(described_class).to receive(:info).and_call_original
    allow(described_class).to receive(:error).and_call_original
    allow(described_class).to receive(:warn).and_call_original
    allow(described_class).to receive(:deprecated).and_call_original
  end

  describe ".info" do
    it "writes an INFO tagged message to stderr" do
      expect { described_class.info("server started") }
        .to output("[Cieye] INFO: server started\n").to_stderr
    end
  end

  describe ".error" do
    it "writes an ERROR tagged message to stderr" do
      expect { described_class.error("connection refused") }
        .to output("[Cieye] ERROR: connection refused\n").to_stderr
    end
  end

  describe ".warn" do
    it "writes a WARNING tagged message to stderr" do
      expect { described_class.warn("retrying in 5 seconds") }
        .to output("[Cieye] WARNING: retrying in 5 seconds\n").to_stderr
    end
  end

  describe ".deprecated" do
    it "writes a DEPRECATED tagged message to stderr" do
      expect { described_class.deprecated("use Cieye.monitor instead") }
        .to output("[Cieye] DEPRECATED: use Cieye.monitor instead\n").to_stderr
    end
  end

  describe "message format" do
    it "prefixes all messages with [Cieye]" do
      expect { described_class.info("test") }
        .to output(/\[Cieye\]/).to_stderr
    end

    it "includes the level between the prefix and the message" do
      expect { described_class.error("boom") }
        .to output(/\[Cieye\] ERROR: boom/).to_stderr
    end
  end
end
