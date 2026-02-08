# frozen_string_literal: true

module Cieye
  # Handle data from sockets
  class Store
    attr_reader :workers, :logs, :failed_specs, :start_time, :mutex

    def initialize(worker_count)
      @start_time = Time.now
      @mutex = Mutex.new
      @logs = {}
      @failed_specs = []
      @workers = {}

      (1..worker_count).each { |i| workers[i.to_s] = initial_state }
    end

    def update(data)
      mutex.synchronize do
        if data["type"] == "log"
          process_log(data)
        else
          process_result(data)
        end
      end
    end

    def all_finished?
      mutex.synchronize { workers.values.all? { |w| w[:percent] >= 1.0 } }
    end

    def worker_active?(worker)
      worker[:passed].positive? || worker[:failed].positive? || worker[:pending].positive? || worker[:percent].positive?
    end

    # Allow workers data to be read safely
    def current_workers
      mutex.synchronize { workers.dup }
    end

    # Allow logs data to be read safely
    def current_logs
      mutex.synchronize { logs.dup }
    end

    def summary_table_stats
      mutex.synchronize do
        initial = { passed: 0, failed: 0, pending: 0, total_pct: 0.0, active_count: 0 }

        stats = workers.values.each_with_object(initial) do |w, acc|
          acc[:passed]  += w[:passed]
          acc[:failed]  += w[:failed]
          acc[:pending] += w[:pending]

          if worker_active?(w)
            acc[:total_pct] += w[:percent]
            acc[:active_count] += 1
          end
        end

        stats[:avg_progress] = stats[:active_count].positive? ? (stats[:total_pct] / stats[:active_count]) : 0.0
        stats
      end
    end

    def info_logs
      logs.select { |_, d| %w[info log].include?(d[:level].to_s) }
          .sort_by { |_, d| -d[:count] }
    end

    def debug_logs
      logs.select { |_, d| %w[error warn debug].include?(d[:level].to_s) }
          .sort_by { |_, d| [-severity_weight(d[:level]), -d[:count]] }
    end

    private

    def initial_state
      {
        passed: 0,
        failed: 0,
        pending: 0,
        percent: 0.0,
        file: "Waiting..."
      }
    end

    def process_log(data)
      msg = data["message"].strip
      logs[msg] ||= { count: 0, level: data["level"], stream: data["stream"] }
      logs[msg][:count] += 1
    end

    def process_result(data)
      return unless (worker = workers[data["worker"].to_s])

      save_status(worker, data)
      worker[:percent] = data["percent"].to_f
      worker[:file] = data["file"] if data["file"]
    end

    def save_status(worker, data)
      status = data["status"]&.to_sym
      file = data["file"]

      worker[status] += 1 if worker.key?(status)
      return if status != :failed || !file || failed_specs.include?(file)

      failed_specs << file
    end

    def severity_weight(level)
      { "error" => 3, "warn" => 2, "debug" => 1 }[level.to_s.downcase] || 0
    end
  end
end
