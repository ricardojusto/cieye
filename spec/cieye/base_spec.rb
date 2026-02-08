# frozen_string_literal: true

RSpec.describe Cieye do
  describe "base module methods" do
    describe ".artifact_path" do
      it "returns default artifact path" do
        expect(Cieye.artifact_path).to eq(File.join(Dir.pwd, "tmp/cieye"))
      end

      it "returns custom artifact path when set" do
        original_path = Cieye.artifact_path
        custom_path = "/custom/path"

        Cieye.artifact_path = custom_path
        expect(Cieye.artifact_path).to eq(custom_path)

        # Reset to original
        Cieye.artifact_path = original_path
      end

      it "memoizes the default path" do
        path1 = Cieye.artifact_path
        path2 = Cieye.artifact_path
        expect(path1).to equal(path2)
      end
    end

    describe ".artifact_path=" do
      it "sets custom artifact path" do
        original_path = Cieye.artifact_path
        new_path = "/tmp/custom_cieye"

        Cieye.artifact_path = new_path
        expect(Cieye.artifact_path).to eq(new_path)

        # Cleanup
        Cieye.artifact_path = original_path
      end
    end

    describe ".ensure_artifact_dir!" do
      let(:test_path) { File.join(Dir.pwd, "tmp/test_cieye_#{Time.now.to_i}") }

      before do
        Cieye.artifact_path = test_path
      end

      after do
        FileUtils.rm_rf(test_path) if File.exist?(test_path)
        Cieye.artifact_path = File.join(Dir.pwd, "tmp/cieye")
      end

      it "creates artifact directory if it doesn't exist" do
        expect(File.exist?(test_path)).to be false

        Cieye.ensure_artifact_dir!

        expect(File.exist?(test_path)).to be true
        expect(File.directory?(test_path)).to be true
      end

      it "doesn't raise error if directory already exists" do
        FileUtils.mkdir_p(test_path)

        expect { Cieye.ensure_artifact_dir! }.not_to raise_error
      end

      it "creates nested directories" do
        nested_path = File.join(test_path, "nested/deep")
        Cieye.artifact_path = nested_path

        Cieye.ensure_artifact_dir!

        expect(File.exist?(nested_path)).to be true
        expect(File.directory?(nested_path)).to be true
      end
    end

    describe ".config_path" do
      let(:project_config) { File.join(Dir.pwd, ".cieye_rspec") }
      let(:gem_config) { File.join(File.dirname(__FILE__), "../lib/cieye/config", ".cieye_rspec") }

      context "when project has .cieye_rspec file" do
        before do
          File.write(project_config, "# test config")
        end

        after do
          File.delete(project_config) if File.exist?(project_config)
        end

        it "returns project config path" do
          expect(Cieye.config_path).to eq(project_config)
        end
      end

      context "when project doesn't have .cieye_rspec file" do
        before do
          File.delete(project_config) if File.exist?(project_config)
        end

        it "returns gem's default config path" do
          config_path = Cieye.config_path
          expect(config_path).to include("lib/cieye/config/.cieye_rspec")
        end
      end
    end
  end
end
