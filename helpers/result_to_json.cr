#
# Convert captured test result to json
#

FAILURES_LINE_START        = "Failures:"
FAILED_EXAMPLES_LINE_START = "Failed examples:"
SUMMARY_TEST_FAIL          = "F"
TEST_SUMMARY_LINE_INDEX    = 0

test_result_file = ARGV[0]?

#
# Main start
#

unless test_result_file
  puts <<-USAGE
    Usage:
    > result_to_json <captured 'crystal spec' output>
    USAGE
  exit 1
end

test_result_lines = File.read(test_result_file).lines

summary = test_result_lines[TEST_SUMMARY_LINE_INDEX]
test_count = summary.size
failure_count = summary.count "F"

# failures_list_index = test_result_lines.index { |line| line == FAILURES_LINE_START }
# failed_examples_index = test_result_lines.index { |line| line == FAILED_EXAMPLES_LINE_START }

# failures_list = if failures_list_index && failed_examples_index
#                   test_result_lines[(failures_list_index + 2)..(failed_examples_index - 2)]
#                 else
#                   [] of String
#                 end

puts summary
puts test_count
puts failure_count

arr = Array(String).new(2)
puts arr
