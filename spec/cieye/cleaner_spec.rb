# frozen_string_literal: true

RSpec.describe Cieye::Cleaner do
  let(:test_artifact_path) { File.join(Dir.pwd, "tmp/test_cleaner_#{Time.now.to_i}") }

  before do
    FileUtils.mkdir_p(test_artifact_path)
  end

  after do
    FileUtils.rm_rf(test_artifact_path) if File.exist?(test_artifact_path)
  end

  describe ".cleanup" do
    let(:json_file1) { File.join(test_artifact_path, "rspec_results1.json") }
    let(:json_file2) { File.join(test_artifact_path, "rspec_results2.json") }
    let(:execution_report) { File.join(test_artifact_path, "rspec_execution_report.html") }
    let(:failed_report) { File.join(test_artifact_path, "rspec_failed_report.html") }

    before do
      # Create test files
      File.write(json_file1, '{"test": "data"}')
      File.write(json_file2, '{"test": "data"}')
      File.write(execution_report, "<html>Execution Report</html>")
      File.write(failed_report, "<html>Failed Report</html>")
    end

    it "removes all JSON result files" do
      expect(File.exist?(json_file1)).to be true
      expect(File.exist?(json_file2)).to be true

      Cieye::Cleaner.cleanup(test_artifact_path)

      expect(File.exist?(json_file1)).to be false
      expect(File.exist?(json_file2)).to be false
    end

    it "removes HTML report files" do
      expect(File.exist?(execution_report)).to be true
      expect(File.exist?(failed_report)).to be true

      Cieye::Cleaner.cleanup(test_artifact_path)

      expect(File.exist?(execution_report)).to be false
      expect(File.exist?(failed_report)).to be false
    end

    it "prints cleanup message" do
      expect { Cieye::Cleaner.cleanup(test_artifact_path) }
        .to output(/🧹 Old RSpec reports/).to_stdout
    end

    it "uses default artifact path when none provided" do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)

      Cieye::Cleaner.cleanup

      expect(File.exist?(json_file1)).to be false
      expect(File.exist?(json_file2)).to be false
    end

    it "handles missing files gracefully" do
      FileUtils.rm_f(json_file1)

      expect { Cieye::Cleaner.cleanup(test_artifact_path) }.not_to raise_error
    end

    it "handles non-existent directory gracefully" do
      non_existent_path = "/tmp/non_existent_#{Time.now.to_i}"

      expect { Cieye::Cleaner.cleanup(non_existent_path) }.not_to raise_error
    end
  end

  describe ".cleanup_before_run" do
    it "calls cleanup with provided path" do
      expect(Cieye::Cleaner).to receive(:cleanup).with(test_artifact_path)

      Cieye::Cleaner.cleanup_before_run(test_artifact_path)
    end

    it "calls cleanup with default path when none provided" do
      expect(Cieye::Cleaner).to receive(:cleanup).with(nil)

      Cieye::Cleaner.cleanup_before_run
    end
  end

  describe ".cleanup_after_run" do
    let(:json_file) { File.join(test_artifact_path, "rspec_results1.json") }
    let(:html_file) { File.join(test_artifact_path, "rspec_execution_report.html") }

    before do
      File.write(json_file, '{"test": "data"}')
      File.write(html_file, "<html>Report</html>")
    end

    it "removes only JSON files, not HTML reports" do
      Cieye::Cleaner.cleanup_after_run(test_artifact_path)

      expect(File.exist?(json_file)).to be false
      expect(File.exist?(html_file)).to be true
    end

    it "uses default artifact path when none provided" do
      allow(Cieye).to receive(:artifact_path).and_return(test_artifact_path)

      Cieye::Cleaner.cleanup_after_run

      expect(File.exist?(json_file)).to be false
    end
  end
end
