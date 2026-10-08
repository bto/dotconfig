# Run dotconfig tests in isolated temporary environments.
#
# USAGE:
#     fish tests/run.fish [test files...]
#
# Each test file runs in a new fish with a clean environment whose HOME and
# XDG_* directories point into a fresh temporary directory. The plugin files
# (functions, conf.d, completions) are copied there, so the real ~/.config is
# never read or written. Set KEEP_TMP=1 to keep the temporary directories.
#
# NOTE: the environment is not fully hermetic. Only the user's config
# (~/.config, ~/.local, ~/.cache) is isolated; system-level files such as
# /opt/homebrew/share/fish/vendor_conf.d/*.fish and
# /opt/homebrew/etc/fish/config.fish are still loaded by the test shells.
#
# A test file passes only if it exits with status 0, prints the TAP plan
# line (1..N, printed by test_finish) and prints no "not ok" line. This
# catches files that stop midway, since fish keeps going after errors.

set repo_dir (path resolve (path dirname (status filename))/..)
set fish_bin (status fish-path)
set tmp_base /tmp
set -q TMPDIR; and set tmp_base (string trim -r -c / $TMPDIR)

set test_files $argv
if test (count $test_files) -eq 0
    set test_files $repo_dir/tests/test_*.fish
end

set -g tmp

function _run_cleanup --on-signal INT
    if test -n "$tmp"; and not set -q KEEP_TMP
        rm -rf $tmp
    end
    exit 130
end

set failed
for test_file in $test_files
    set test_file (path resolve $test_file)
    set name (string replace "$repo_dir/" '' $test_file)

    set -g tmp (mktemp -d $tmp_base/dotconfig-test.XXXXXX)
    or begin
        echo "Failed to create a temporary directory." >&2
        exit 1
    end

    mkdir -p $tmp/home $tmp/data $tmp/cache
    for dir in functions conf.d completions
        mkdir -p $tmp/config/fish/$dir
        cp $repo_dir/$dir/*.fish $tmp/config/fish/$dir/
    end

    echo "# $name"
    cd $tmp/home
    set output (env -i \
        HOME=$tmp/home \
        XDG_CONFIG_HOME=$tmp/config \
        XDG_DATA_HOME=$tmp/data \
        XDG_CACHE_HOME=$tmp/cache \
        PATH=(path dirname $fish_bin):/usr/bin:/bin:/usr/sbin:/sbin \
        TERM=dumb \
        TMPDIR=$tmp \
        $fish_bin $test_file 2>&1)
    set result $status
    cd $repo_dir
    printf '%s\n' $output

    set reasons
    test $result -eq 0; or set -a reasons "status $result"
    string match -qr '^1\.\.\d+$' -- $output; or set -a reasons "no plan line"
    string match -qr '^not ok' -- $output; and set -a reasons "not ok found"

    if test (count $reasons) -eq 0
        echo "# PASS $name"
    else
        echo "# FAIL $name ("(string join ', ' $reasons)")"
        set -a failed $name
    end

    if set -q KEEP_TMP
        echo "# kept temporary directory: $tmp"
    else
        rm -rf $tmp
    end
    set -g tmp
    echo
end

set total (count $test_files)
echo "# $(math $total - (count $failed))/$total test file(s) passed"
if test (count $failed) -ne 0
    for name in $failed
        echo "# failed: $name"
    end
    exit 1
end
