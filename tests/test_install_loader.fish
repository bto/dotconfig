source (path dirname (status filename))/helper.fish

set config_file $__fish_config_dir/config.fish
set loader_line 'type -q dotconfig; and dotconfig load'
set loader_block (printf '\n# Added by dotconfig\n%s\n' $loader_line | string collect -N)

function count_loader_lines
    # count prints 0 when the file is missing or has no loader line.
    count (string match -- $loader_line < $config_file 2> /dev/null)
end

# The test environment must start without config.fish.
assert_not_ok "config.fish does not exist at the start" test -e $config_file

# No config.fish: the loader block is created.
rm -f $config_file
_dotconfig_install_loader
assert_file_content $loader_block $config_file \
    "creates config.fish with only the loader block"
assert_eq 1 (count_loader_lines) "adds exactly one loader line"

# config.fish without a trailing newline: the loader goes on its own line.
rm -f $config_file
printf 'set x 1' > $config_file
_dotconfig_install_loader
assert_file_content "set x 1$loader_block" $config_file \
    "keeps the last line and appends the loader on its own line"

# A hand-written dotconfig load (indented) is respected.
rm -f $config_file
set content (printf 'if status is-interactive\n    dotconfig load\nend\n' | string collect -N)
printf '%s' $content > $config_file
_dotconfig_install_loader
assert_file_content $content $config_file \
    "does not append when config.fish already runs dotconfig load"

# Idempotent.
rm -f $config_file
_dotconfig_install_loader
_dotconfig_install_loader
assert_eq 1 (count_loader_lines) "running twice adds the loader only once"
assert_file_content $loader_block $config_file "running twice leaves one block"

# dotconfig init adds the loader (no modules exist).
rm -f $config_file
assert_ok "dotconfig init succeeds without modules" dotconfig init
assert_eq 1 (count_loader_lines) "dotconfig init adds the loader line"

# An unreadable or unwritable config.fish makes the loader fail loudly.
rm -f $config_file
echo 'set x 1' > $config_file
chmod 222 $config_file
assert_not_ok "fails on an unreadable config.fish" _dotconfig_install_loader
chmod 444 $config_file
assert_not_ok "fails on an unwritable config.fish" _dotconfig_install_loader
chmod 644 $config_file
assert_eq 0 (count_loader_lines) "leaves an unreadable or unwritable config.fish as is"

# Startup order: with the loader in config.fish and conf.d/zz_dotconfig.fish
# still present, dotconfig load runs twice and the last run comes after
# conf.d. zzz_marker.fish sorts after zz_dotconfig.fish.
rm -f $config_file
_dotconfig_install_loader
set module_dir $XDG_CONFIG_HOME/dotconfig/modules
set marker_file $__fish_config_dir/conf.d/zzz_marker.fish
mkdir -p $module_dir/order
echo 'set -ga test_runs (set -q test_confd_done; and echo after; or echo before)' \
    > $module_dir/order/config.fish
echo 'set -g test_confd_done 1' > $marker_file
assert_eq "before after" (fish -c 'echo $test_runs') \
    "fresh fish runs dotconfig load from conf.d and again after conf.d"
rm -rf $module_dir/order $marker_file

# Plugin removed (e.g. fisher remove) while config.fish keeps the loader:
# a fresh fish must start without errors. Keep this last, since it deletes
# the plugin files from the temporary config dir.
rm -f $config_file
_dotconfig_install_loader
rm -f $__fish_config_dir/functions/*dotconfig*.fish \
    $__fish_config_dir/conf.d/zz_dotconfig.fish \
    $__fish_config_dir/completions/dotconfig.fish
assert_eq 1 (count_loader_lines) "config.fish has the loader line"
assert_not_ok "dotconfig is gone in a fresh fish" fish -c 'type -q dotconfig'

# fish exits 0 even when config.fish fails, so check stderr instead.
set err (fish -c true 2>&1 > /dev/null)
assert_eq "" "$err" "fresh fish prints no error without the plugin"

set err (fish -i -c true 2>&1 > /dev/null)
assert_eq "" "$err" "fresh interactive fish prints no error without the plugin"

test_finish
