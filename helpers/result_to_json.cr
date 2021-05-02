require "json"

#
# Convert captured test result to json
#

SECTION_PENDING         = "Pending:"
SECTION_FAILURES        = "Failures:"
SECTION_SUMMARY         = "Finished"
SECTION_EXAMPLES        = "Failed examples:"
SUMMARY_TEST_PASS       = '.'
SUMMARY_TEST_FAIL       = 'F'
SUMMARY_TEST_PENDING    = '*'
TEST_SUMMARY_LINE_INDEX = 0

TEST_FAILURE_DETAIL_START_PREFIX = /^  \d+/
TEST_FAILURE_DETAIL_END_PREFIX   = /^     #/

test_result_file = ARGV[0]?
scaffold_json = ARGV[1]?

PASS  = "pass"
FAIL  = "fail"
ERROR = "error"

class TestCase
  include JSON::Serializable

  getter name : String
  getter test_code : String
  property status : String?
  property message : String?
  property output : String?
end

class TestRun
  include JSON::Serializable

  getter version : Int32
  property status : String?
  property message : String?
  getter tests : Array(TestCase)
end

enum ParsingState
  SEARCH
  SECTION_SHORT_SUMMARY
  SECTION_PENDING
  SECTION_FAILURES
  SECTION_FAILURE_DETAIL
  SECTION_SUMMARY
  SECTION_EXAMPLES
end

class ReadState
  getter test_run : TestRun
  private property state : ParsingState
  private property failed_test_indexes : Array(Int32)

  def initialize(@test_run : TestRun)
    @state = ParsingState::SEARCH
    @failed_test_indexes = Array(Int32).new
  end

  def handle_line(line : String)
    case state
    when ParsingState::SEARCH
      handle_search(line)
    when ParsingState::SECTION_FAILURES
      parse_failures(line)
    when ParsingState::SECTION_FAILURE_DETAIL
      parse_failure_detail(line)
    else
      raise "state #{state} not handled"
    end

    self
  end

  private def handle_search(line : String)
    case line
    when .blank?
      nil
    when .starts_with?(SECTION_FAILURES)
      set_state(ParsingState::SECTION_FAILURES)
    end
  end

  private def parse_short_summary(line : String)
    line.chars.each_with_index do |char, idx|
      case char
      when SUMMARY_TEST_PASS
        test_run.tests[idx].status = PASS
      when SUMMARY_TEST_FAIL
        test_run.tests[idx].status = FAIL
        failed_test_indexes << idx
      when SUMMARY_TEST_PENDING
        test_run.tests[idx].status = ERROR
        test_run.tests[idx].message = "Test case not run, unexpectedly skipped."
      else
        raise "Unexpected test status '#{char}'"
      end
    end

    set_state(ParsingState::SEARCH)
  end

  private def parse_failures(line : String)
    if failed_test_indexes.size.zero?
      set_state(ParsingState::SEARCH)
      return
    end

    if line.matches?(TEST_FAILURE_DETAIL_START_PREFIX)
      set_state(ParsingState::SECTION_FAILURE_DETAIL)
      parse_failure_detail(line)
    end
  end

  private def parse_failure_detail(line : String)
    test_case_idx = failed_test_indexes.first
    test_case = test_run.tests[test_case_idx]

    if message = test_case.message
      test_case.message = message + "\n" + line
    else
      test_case.message = line
    end

    if line.matches?(TEST_FAILURE_DETAIL_END_PREFIX)
      failed_test_indexes.shift
      set_state(ParsingState::SECTION_FAILURES)
    end
  end

  private def set_state(state : ParsingState)
    self.state = state
  end
end

#
# Main start
#

unless test_result_file && scaffold_json
  puts <<-USAGE
    Usage:
    > result_to_json <captured 'crystal spec' output> <scaffold json file>
    USAGE
  exit 1
end

test_run = TestRun.from_json(File.read(scaffold_json))
# pp test_run

test_result = File.read(test_result_file)
  .lines
  .reduce(ReadState.new(test_run)) do |state, line|
    state.handle_line(line)
  end
  .test_run

pp test_result
# test_count = summary.size
# failure_count = summary.count "F"

# # failures_list_index = test_result_lines.index { |line| line == FAILURES_LINE_START }
# # failed_examples_index = test_result_lines.index { |line| line == FAILED_EXAMPLES_LINE_START }

# # failures_list = if failures_list_index && failed_examples_index
# #                   test_result_lines[(failures_list_index + 2)..(failed_examples_index - 2)]
# #                 else
# #                   [] of String
# #                 end

# puts summary
# puts test_count
# puts failure_count

# arr = Array(String).new(2)
# puts arr
