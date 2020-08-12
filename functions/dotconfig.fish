function dotconfig -a cmd -d "dotfiles manager"
    set -q XDG_CACHE_HOME; or set XDG_CACHE_HOME ~/.cache
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    set -q XDG_DATA_HOME; or set XDG_DATA_HOME ~/.local/share

    set -g dotconfig_cache_dir $XDG_CACHE_HOME/dotconfig
    set -g dotconfig_config_dir $XDG_CONFIG_HOME/dotconfig
    set -g dotconfig_data_dir $XDG_DATA_HOME/dotconfig
    set -g dotconfig_module_dir $dotconfig_config_dir/modules

    set -g fish_config_dir $XDG_CONFIG_HOME/fish
    set -g fish_function_dir $fish_config_dir/functions

    set -e argv[1]
    switch "$cmd"
        case clone
            _dotconfig_clone $argv
        case help
            _dotconfig_help $argv
        case init
            _dotconfig_init $argv
        case load
            _dotconfig_load $argv
        case set_path
            _dotconfig_set_path $argv
        case setup
            _dotconfig_setup $argv
        case \*
            echo "dotconfig: unknown command \"$cmd\"" >&2
            _dotconfig_help >&2
            return 1
    end
end

function _dotconfig_clone -a repo
    if test -z $repo
        echo "no repository" >&2
        _dotconfig_help >&2
        return 1
    end
    git clone https://github.com/$repo.git $dotconfig_config_dir
end

function _dotconfig_help
    echo "usage: dotconfig clone    Clone dotconfig config repository"
    echo "       dotconfig help     Show this help"
    echo "       dotconfig init     Initialize all modules"
    echo "       dotconfig load     Load script(config.fish for default) of all modules"
    echo "       dotconfig set_path Set path variable"
    echo "       dotconfig setup    Clone, Initialize, Load"
end

function _dotconfig_init
    for file in $dotconfig_module_dir/*/dot.*
        set dotfile ~/(string replace -r '^dot' '' (basename $file))
        if test -f $dotfile
            continue
        end
        ln -s $file $dotfile
    end

    for file in $dotconfig_module_dir/*/functions/*.fish
        set function_file $fish_function_dir/(basename $file)
        if test -f $function_file
            continue
        end
        ln -s $file $function_file
    end

    _dotconfig_load init.fish
end

function _dotconfig_load -a script_name
    if test -z $script_name
        set script_name config.fish
    end
    for file in $dotconfig_module_dir/*/$script_name
        source $file
    end
end

function _dotconfig_set_path -a var_name
    set -e argv[1]
    for dir in $argv
        if not test -d $dir
            continue
        end
        set -gx $var_name (string match -v $dir $$var_name)
        set -gx $var_name $dir $$var_name
    end
end

function _dotconfig_setup -a repo
    _dotconfig_clone $repo
    _dotconfig_init
    _dotconfig_load
end
