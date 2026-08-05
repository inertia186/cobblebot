require 'test_helper'
require 'fileutils'
require 'tmpdir'
require 'timeout'

class FileTailRuntimeTest < ActiveSupport::TestCase
  def setup
    @directory = Dir.mktmpdir('cobblebot-file-tail')
    @log_path = File.join(@directory, 'latest.log')
    File.write(@log_path, "historical line\n")
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def test_reads_appended_lines_without_replaying_history
    with_tail(expected_lines: 2) do |received|
      append("first new line\nsecond new line\n")
      wait_for(received, 2)

      assert_equal ["first new line\n", "second new line\n"], received
    end
  end

  def test_resumes_from_the_top_after_copy_truncate
    with_tail(expected_lines: 2) do |received|
      append("a deliberately long line before truncation\n")
      wait_for(received, 1)

      File.write(@log_path, "after truncate\n")
      wait_for(received, 2)

      assert_equal [
        "a deliberately long line before truncation\n",
        "after truncate\n"
      ], received
    end
  end

  def test_resumes_after_rename_and_a_temporary_missing_file
    rotated_path = File.join(@directory, 'latest.log.1')

    with_tail(expected_lines: 2) do |received|
      append("before rotation\n")
      wait_for(received, 1)

      File.rename(@log_path, rotated_path)
      sleep 0.05
      File.write(@log_path, "after rotation\n")
      wait_for(received, 2)

      assert_equal ["before rotation\n", "after rotation\n"], received
      assert_equal "historical line\nbefore rotation\n", File.read(rotated_path)
    end
  end

private
  def append(contents)
    File.open(@log_path, 'a') do |file|
      file.write(contents)
      file.flush
    end
  end

  def wait_for(received, count)
    Timeout.timeout(2) do
      sleep 0.005 until received.length >= count
    end
  end

  def with_tail(expected_lines:)
    received = []
    ready = Queue.new
    thread = Thread.new do
      File.open(@log_path) do |log|
        log.extend(File::Tail)
        log.interval = 0.01
        log.max_interval = 0.02
        log.suspicious_interval = 0.02
        log.backward(0)
        ready << true
        log.tail(expected_lines) { |line| received << line }
      end
    end

    Timeout.timeout(2) { ready.pop }
    yield received
    Timeout.timeout(2) { thread.join }
  ensure
    thread&.kill if thread&.alive?
    thread&.join
  end
end
