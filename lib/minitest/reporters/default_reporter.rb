require_relative '../reporter_base'
require 'ansi/code'

module Minitest
  module Reporters
    # A reporter identical to the standard MiniTest reporter except with more
    # colors.
    #
    # Based upon Ryan Davis of Seattle.rb's MiniTest (MIT License).
    #
    # @see https://github.com/seattlerb/minitest MiniTest
    class DefaultReporter < ReporterBase
      include Minitest::RelativePosition

      def initialize(options = {})
        super(options)
        @count = @assertions = @passes = @failures = @skips = @errors = 0
        @start_time = Time.now
        @total_tests = options.fetch(:total_tests, 0)
        @detailed_skip = options.fetch(:detailed_skip, true)
        @slow_count = options.fetch(:slow_count, 0)
        @slow_suite_count = options.fetch(:slow_suite_count, 0)
        @fast_fail = options.fetch(:fast_fail, false)
        @test_times = []
        @suite_times = []
        @color = options.fetch(:color) do
          #output.tty? && (
          #  ENV["TERM"] =~ /^screen|color/ ||
          #  ENV["EMACS"] == "t"
          #)
        end
      end

      # Dead Code?
      def before_suites(suites, type)
        puts
        puts "# Running #{type}s:"
        puts
      end

      # Dead Code?
      def before_test(suite, test)
        @test_name = "#{suite}##{test}"
        print "#{@test_name} = " if verbose?
      end

      def pre_record(result)
        @count += 1
        @assertions += result.assertions
      end

      def pass(result)
        @passes += 1
        test_result(result, green('.'))
      end

      def skip(result)
        @skips += 1
        test_result(result, yellow('S'))
      end

      def failure(result)
        @failures += 1
        if @fast_fail
          puts
          puts suite.name
          print pad_test(test)
          print(red(pad_mark('FAIL')))
          puts
          print_info(test_runner.exception, false)
        else
          test_result(result, red('F'))
        end
      end

      def error(result)
        @errors += 1
        if @fast_fail
          puts
          puts suite.name
          print pad_test(test)
          print(red(pad_mark('ERROR')))
          puts
          print_info(test_runner.exception)
        else
          test_result(result, red('E'))
        end
      end

      def report
        time = Time.now - @start_time
        io.puts
        io.puts
        io.puts "Finished in %.6fs, %.4f, %.4f assertions/s" %
          [time, @count / time, @assertions / time]

        io.puts "%d runs, %d assertions, %d failures, %d errors, %d skips" %
          [@count, @assertions, @failures, @errors, @skips]
      end

      # Dead code?
      def after_suite(suite)
        time = Time.now - runner.suite_start_time
        @suite_times << [suite.name, time]
      end

      # Dead code?
      # Or perhaps this should be the #report function instead?
      def after_suites(suites, type)
        time = Time.now - @start_time
        status_line = "Finished %ss in %.6fs, %.4f tests/s, %.4f assertions/s." %
          [type, time, @count / time, @assert / time]

        puts
        puts
        puts colored_for(suite_result, status_line)

        unless @fast_fail
          runner.test_results.each do |suite, tests|
            tests.each do |test, test_runner|
              if message = message_for(test_runner)
                puts
                print colored_for(test_runner.result, message)
              end
            end
          end
        end

        if @slow_count > 0
          slow_tests = @test_times.sort_by { |x| x[1] }.reverse.take(@slow_count)

          puts
          puts "Slowest tests:"
          puts

          slow_tests.each do |slow_test|
            puts "%.6fs %s" % [slow_test[1], slow_test[0]]
          end
        end

        if @slow_suite_count > 0
          slow_suites = @suite_times.sort_by { |x| x[1] }.reverse.take(@slow_suite_count)

          puts
          puts "Slowest test classes:"
          puts

          slow_suites.each do |slow_suite|
            puts "%.6fs %s" % [slow_suite[1], slow_suite[0]]
          end
        end

        puts
        print colored_for(suite_result, result_line)
        puts
      end

      private

      def green(string)
        @color ? ANSI::Code.green(string) : string
      end

      def yellow(string)
        @color ? ANSI::Code.yellow(string) : string
      end

      def red(string)
        @color ? ANSI::Code.red(string) : string
      end

      def colored_for(result, string)
        case result
        when :failure, :error; red(string)
        when :skip; yellow(string)
        else green(string)
        end
      end

      # Dead Code
      def suite_result
        case
        when runner.failures > 0; :failure
        when runner.errors > 0; :error
        when runner.skips > 0; :skip
        else :pass
        end
      end

      def test_result(result, message)
        @test_times << [@test_name, result.time]

        print '%.2f s = ' % result.time if verbose?
        print message
        puts if verbose?
      end

      # Dead Code
      def location(exception)
        last_before_assertion = ''

        exception.backtrace.reverse_each do |s|
          break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
          last_before_assertion = s
        end

        last_before_assertion.sub(/:in .*$/, '')
      end

      # Dead Code?
      def message_for(test_runner)
        suite = test_runner.suite
        test = test_runner.test
        e = test_runner.exception

        case test_runner.result
        when :pass then nil
        when :skip
          if @detailed_skip
            "Skipped:\n#{test}(#{suite}) [#{location(e)}]:\n#{e.message}\n"
          end
        when :failure then "Failure:\n#{test}(#{suite}) [#{location(e)}]:\n#{e.message}\n"
        when :error
          bt = filter_backtrace(test_runner.exception.backtrace).join "\n    "
          "Error:\n#{test}(#{suite}):\n#{e.class}: #{e.message}\n    #{bt}\n"
        end
      end

      # Dead Code?
      def result_line
        '%d tests, %d assertions, %d failures, %d errors, %d skips' %
          [runner.test_count, runner.assertion_count, runner.failures, runner.errors, runner.skips]
      end

      def print_info(e, name = true)
        print "#{e.exception.class.to_s}: " if name
        e.message.each_line { |line| print_with_info_padding(line) }
        filter_backtrace(e.backtrace).each { |line| print_with_info_padding(line) }
      end
    end
  end
end
