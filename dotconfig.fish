function dotconfig -a cmd -d "dotfiles manager"
    set -q XDG_CACHE_HOME; or set XDG_CACHE_HOME ~/.cache
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    set -q XDG_DATA_HOME; or set XDG_DATA_HOME ~/.local/share

    set -q DOTCONFIG_CACHE_HOME; or set -g DOTCONFIG_CACHE_HOME $XDG_CACHE_HOME/dotconfig
    set -q DOTCONFIG_CONFIG_HOME; or set -g DOTCONFIG_CONFIG_HOME $XDG_CONFIG_HOME/dotconfig
    set -q DOTCONFIG_DATA_HOME; or set -g DOTCONFIG_DATA_HOME $XDG_DATA_HOME/dotconfig

    switch "$cmd"
        case help
            _dotconfig_help
        case init
            _dotconfig_init
        case load
            _dotconfig_load
        case \*
            echo "dotconfig: unknown command \"$cmd\"" >&2
            _dotconfig_help >&2
            return 1
    end
end

function _dotconfig_help
    echo "usage: dotconfig help   Show this help"
    echo "       dotconfig init   Initialize all packages"
    echo "       dotconfig load   Load config.fish of all packages"
end

function _dotconfig_init
    for file in $DOTCONFIG_CONFIG_HOME/modules/*/dot.*
        set dotfile ~/(string replace -r '^dot' '' (basename $file))
        if test -f $dotfile
            continue
        end
        ln -s $file $dotfile
    end

    for file in $DOTCONFIG_CONFIG_HOME/modules/*/init.fish
        source $file
    end
end

function _dotconfig_load
    for file in $DOTCONFIG_CONFIG_HOME/modules/*/config.fish
        source $file
    end
end
