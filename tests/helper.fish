# Minimal assertion helpers for dotconfig tests.
# Usage (in a test file):
#     source (path dirname (status filename))/helper.fish
#     assert_eq expected actual "name"
#     assert_ok "name" command args...
#     assert_file_content expected file "name"
#     test_finish

set -g _test_count 0
set -g _test_failures 0

function _test_report -a result name
    set -g _test_count (math $_test_count + 1)
    if test $result -eq 0
        echo "ok $_test_count - $name"
    else
        set -g _test_failures (math $_test_failures + 1)
        echo "not ok $_test_count - $name"
    end
end

function assert_eq -a expected actual name -d "Assert that two strings are equal"
    if test "$expected" = "$actual"
        _test_report 0 $name
    else
        _test_report 1 $name
        echo "#   expected: '$expected'"
        echo "#   actual:   '$actual'"
    end
end

function assert_ok -a name -d "Assert that a command exits with status 0"
    set -l cmd $argv[2..-1]
    $cmd
    set -l result $status
    _test_report $result $name
    if test $result -ne 0
        echo "#   command failed (status $result): $cmd"
    end
end

function assert_not_ok -a name -d "Assert that a command exits with non-zero status"
    set -l cmd $argv[2..-1]
    $cmd
    set -l result $status
    if test $result -eq 0
        _test_report 1 $name
        echo "#   command unexpectedly succeeded: $cmd"
    else
        _test_report 0 $name
    end
end

function assert_file_content -a expected file name -d "Assert the exact content of a file"
    # string collect -N keeps trailing newlines, so they are compared too.
    set -l actual "<no such file: $file>"
    test -f $file; and set actual (string collect -N < $file)
    assert_eq $expected $actual $name
end

function test_finish -d "Print the plan and exit non-zero if any assertion failed"
    echo "1..$_test_count"
    if test $_test_failures -ne 0
        echo "# $_test_failures of $_test_count assertion(s) failed"
        exit 1
    end
    exit 0
end
