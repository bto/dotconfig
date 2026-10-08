source (path dirname (status filename))/helper.fish

set module_dir $XDG_CONFIG_HOME/dotconfig/modules

# The plugin under test must be the copy in the temporary config dir.
assert_eq $XDG_CONFIG_HOME/fish/functions/dotconfig.fish \
    (functions --details dotconfig) \
    "dotconfig is autoloaded from the temporary config dir"

# dotconfig load
mkdir -p $module_dir/a $module_dir/b
echo 'set -ga test_loaded a' > $module_dir/a/config.fish
echo 'set -ga test_loaded b' > $module_dir/b/config.fish
echo 'set -ga test_init_loaded a' > $module_dir/a/init.fish
echo 'set -ga test_init_loaded b' > $module_dir/b/init.fish

set -e test_loaded
set -e test_init_loaded
dotconfig load
assert_eq "a b" "$test_loaded" "load sources config.fish of every module"
assert_eq "" "$test_init_loaded" "load does not source init.fish"

set -e test_loaded
set -e test_init_loaded
dotconfig load init.fish
assert_eq "a b" "$test_init_loaded" "load init.fish sources init.fish of every module"
assert_eq "" "$test_loaded" "load init.fish does not source config.fish"

# dotconfig set_path
mkdir -p $HOME/d1 $HOME/d2
set -gx TEST_PATH /usr/bin $HOME/d1
dotconfig set_path TEST_PATH $HOME/d1 $HOME/missing $HOME/d2
# TEST_PATH ends with PATH, so fish treats it as a path variable and
# "$TEST_PATH" would be joined with colons. Join with spaces explicitly.
set first (string join " " $TEST_PATH)
assert_eq "$HOME/d2 $HOME/d1 /usr/bin" "$first" "set_path prepends existing dirs"
assert_not_ok "set_path skips non-existent dirs" \
    contains -- $HOME/missing $TEST_PATH

dotconfig set_path TEST_PATH $HOME/d1 $HOME/missing $HOME/d2
assert_eq "$first" (string join " " $TEST_PATH) "set_path is idempotent"
assert_eq (count $TEST_PATH) (count (printf '%s\n' $TEST_PATH | sort -u)) \
    "set_path leaves no duplicates"

# Startup: conf.d/zz_dotconfig.fish runs dotconfig load in a fresh fish.
mkdir -p $module_dir/startup
echo 'set -ga test_startup_count x' > $module_dir/startup/config.fish
assert_eq 1 (fish -c 'count $test_startup_count') \
    "fresh fish runs dotconfig load exactly once at startup"

test_finish
