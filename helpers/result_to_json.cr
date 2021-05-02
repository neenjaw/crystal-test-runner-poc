require "json"
require "xml"

spec_output = ARGV[0]?
junit_file = ARGV[1]?
scaffold_json = ARGV[2]?
output_file = ARGV[3]?

PASS  = "pass"
FAIL  = "fail"
ERROR = "error"

TAG_TESTSUITE = "testsuite"
TAG_TESTCASE  = "testcase"
TAG_FAILURE   = "failure"
TAG_SKIPPED   = "skipped"

ATTR_MESSAGE = "message"
ATTR_NAME    = "name"

class TestCase
  include JSON::Serializable

  getter name : String
  getter test_code : String?
  property status : String?
  property message : String?
  property output : String?

  def initialize(@name, @test_code, @status, @message, @output)
  end
end

class TestRun
  include JSON::Serializable

  getter version : Int32
  property status : String?
  property message : String?
  property tests : Array(TestCase)
end

def find_element(node : XML::Node, name : String)
  node.children.find do |child|
    child.name == name
  end
end

def find_testsuite(document : XML::Node)
  find_element(document, TAG_TESTSUITE).not_nil!
end

def convert_to_test_cases(test_suite : XML::Node)
  test_suite.children
    .map do |test_case|
      if test_case.name != TAG_TESTCASE
        next nil
      end

      failure = find_element(test_case, TAG_FAILURE)
      skipped = find_element(test_case, TAG_SKIPPED)

      status = failure ? FAIL : (skipped ? ERROR : PASS)
      message = failure ? failure.not_nil![ATTR_MESSAGE] : (
        skipped ? "Test case unexpectedly skipped" : nil
      )

      TestCase.new(
        test_case[ATTR_NAME],
        nil,
        status,
        message,
        nil
      )
    end
    .compact
end

def merge_test_cases(a : Array(TestCase), b : Array(TestCase))
  a.zip(b).map do |a, b|
    a.status = b.status
    a.message = b.message
    a.output = b.output
    a
  end
end

def set_test_run_status(test_run : TestRun, document : XML::Node)
  testcase_count = document["tests"].not_nil!.to_i
  skipped_count = document["skipped"].not_nil!.to_i
  errors_count = document["errors"].not_nil!.to_i
  failures_count = document["failures"].not_nil!.to_i

  status = (testcase_count - skipped_count - failures_count - errors_count) == testcase_count ? PASS : FAIL

  test_run.status = status
end

def set_test_run_error(test_run : TestRun, spec_output : String?)
  test_run.status = ERROR
  test_run.message = spec_output
  test_run.tests.each do |test_case|
    test_case.status = FAIL
  end
end

#
# Main start
#

unless spec_output && junit_file && scaffold_json && output_file
  puts <<-USAGE
    Usage:
    > result_to_json <captured spec> <junit xml> <scaffold json> <output file>
    USAGE
  exit 1
end

puts "* Reading scaffold json 📖"

test_run = TestRun.from_json(File.read(scaffold_json))

puts "* Checking if junit xml exists 🔍"

if !File.exists?(junit_file)
  puts "* Failed finding junit xml ❌"

  set_test_run_error(test_run, File.read(spec_output))

  puts "* Writing error result json to: #{output_file} 🖊"

  File.write(output_file, test_run.to_json)
  exit
end

puts "* Reading junit xml ✅"

junit_xml = File.read(junit_file)
junit_document = XML.parse(junit_xml)
junit_testsuite = find_testsuite(junit_document)

test_cases = convert_to_test_cases(junit_testsuite)
test_run.tests = merge_test_cases(test_run.tests, test_cases)
set_test_run_status(test_run, junit_testsuite)

puts "* Writing merged result json to: #{output_file} 🖊"

File.write(output_file, test_run.to_json)

puts "* All done! 🏁"
