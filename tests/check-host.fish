# Read-only checks of the fish startup environment on this host.
#
# Unlike tests/run.fish, this script looks at the REAL $HOME. It only writes
# to a temporary directory and to the file given to `save`.

function _check_host_usage
    echo "\
USAGE:
    fish tests/check-host.fish <command>

COMMAND:
    save <file>
        Write a snapshot (PATH, MANPATH, fish_complete_path and
        __direnv_export_eval) of a fresh fish to <file>.

    diff <file>
        Take a fresh snapshot and compare it with <file> (diff -u).

    status
        Show the direnv binary used by __direnv_export_eval, and how
        dotconfig load is ordered against Homebrew's vendor direnv hook
        at startup." >&2
end

# Run fish in $HOME with an almost empty environment, so the result does not
# depend on the calling shell. The child is a login + interactive shell
# (`fish -l -i`) like a new terminal window: on macOS, fish builds PATH and
# MANPATH from /etc/paths(.d) and /etc/manpaths(.d) (path_helper style) only
# for login shells. With -c no prompt is drawn and no fish_prompt event is
# fired, so the direnv hook is defined but `direnv export` does not run.
function _check_host_fish
    set -l term dumb
    set -q TERM; and set term $TERM
    set -l user (id -un)
    set -q USER; and set user $USER
    set -l old_pwd $PWD
    cd $HOME
    or return 1
    env -i HOME=$HOME USER=$user TERM=$term (status fish-path) -l -i $argv
    set -l result $status
    cd $old_pwd
    return $result
end

function _check_host_snapshot
    _check_host_fish -c '
        echo "## PATH"
        string join \n -- $PATH
        echo "## MANPATH"
        string join \n -- $MANPATH
        echo "## fish_complete_path"
        string join \n -- $fish_complete_path
        echo "## __direnv_export_eval"
        if functions -q __direnv_export_eval
            functions __direnv_export_eval
        else
            echo "(not defined)"
        end
    '
end

function _check_host_status
    set -l tmp (mktemp -d $tmp_base/dotconfig-check-host.XXXXXX)
    or return 1

    # Informational only: the vendor hook and dotconfig's direnv module may
    # embed similar paths, so this cannot tell which definition won. The
    # startup order below is the verdict.
    echo "## direnv binary in __direnv_export_eval (informational)"
    set -l body (_check_host_fish -c 'functions __direnv_export_eval 2>/dev/null')
    or begin
        rm -rf $tmp
        return 1
    end
    set -l bins (string match -ar '/[^\s"\';|]*/direnv(?=["\']?\s+export)' -- $body)
    if test (count $bins) -eq 0
        echo "(__direnv_export_eval is not defined or has no direnv path)"
    else
        printf '%s\n' $bins | sort -u
    end

    echo
    echo "## startup order (fish --profile-startup)"
    _check_host_fish --profile-startup=$tmp/profile -c exit
    or begin
        rm -rf $tmp
        return 1
    end

    # Lines that the vendor conf.d snippets use to install the direnv hook,
    # e.g. "/opt/homebrew/Cellar/direnv/<ver>/bin/direnv hook fish | source".
    set -l vendor_dirs (_check_host_fish -c 'string join \n -- $__fish_vendor_confdirs')
    set -l vendor_hooks
    for file in $vendor_dirs/*.fish
        set -a vendor_hooks (string trim < $file | string match -er 'direnv hook fish')
    end

    # Profile lines look like "<time> <sum> --> command"; they are in
    # execution order, so the line number tells the order.
    set -l loads
    set -l vendor
    set -l n 0
    while read -l line
        set n (math $n + 1)
        set -l cmd (string replace -r '^\s*\d+\s+\d+\s+-*>\s' '' -- $line)
        or continue
        if string match -qr '^dotconfig load(\s|$)' -- $cmd
            set -a loads $n
        else if contains -- (string trim -- $cmd) $vendor_hooks
            set -a vendor $n
        end
    end < $tmp/profile
    rm -rf $tmp

    echo "dotconfig load runs: "(count $loads)" time(s) (profile lines: $loads)"
    if test (count $vendor) -eq 0
        echo "vendor direnv hook: not found"
    else
        echo "vendor direnv hook: profile line(s) $vendor"
        if test (count $loads) -eq 0
            echo "last dotconfig load vs vendor hook: n/a (dotconfig load not run)"
        else if test $loads[-1] -gt $vendor[-1]
            echo "last dotconfig load vs vendor hook: AFTER (dotconfig wins)"
        else
            echo "last dotconfig load vs vendor hook: BEFORE (vendor hook wins)"
        end
    end
end

set tmp_base /tmp
set -q TMPDIR; and set tmp_base (string trim -r -c / $TMPDIR)
set -q argv[2]; and set argv[2] (path resolve $argv[2])

switch "$argv[1]"
    case save
        if test (count $argv) -ne 2
            _check_host_usage
            exit 2
        end
        _check_host_snapshot > $argv[2]
    case diff
        if test (count $argv) -ne 2
            _check_host_usage
            exit 2
        end
        set tmp (mktemp $tmp_base/dotconfig-snapshot.XXXXXX)
        or exit 1
        _check_host_snapshot > $tmp
        or begin
            rm -f $tmp
            exit 1
        end
        diff -u $argv[2] $tmp
        set result $status
        rm -f $tmp
        exit $result
    case status
        _check_host_status
    case '*'
        _check_host_usage
        exit 2
end
