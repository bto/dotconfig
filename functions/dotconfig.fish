function dotconfig -d "dotfiles manager"
    set -q XDG_CACHE_HOME; or set XDG_CACHE_HOME ~/.cache
    set -q XDG_CONFIG_HOME; or set XDG_CONFIG_HOME ~/.config
    set -q XDG_DATA_HOME; or set XDG_DATA_HOME ~/.local/share

    set -g dotconfig_cache_dir $XDG_CACHE_HOME/dotconfig
    set -g dotconfig_config_dir $XDG_CONFIG_HOME/dotconfig
    set -g dotconfig_data_dir $XDG_DATA_HOME/dotconfig
    set -g dotconfig_module_dir $dotconfig_config_dir/modules

    set -g fish_config_dir $XDG_CONFIG_HOME/fish
    set -g fish_function_dir $fish_config_dir/functions

    set options_spec h/help
    argparse $options_spec -- $argv 2> /dev/null
    if test $status -ne 0
        echo "Invalid option was provided." >&2
        _dotconfig_help $argv >&2
        return 1
    end

    if set --query _flag_help
        _dotconfig_help $argv
        return
    end

    set command $argv[1]
    set argv $argv[2..-1]
    switch $command
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
            echo "Invalid command '$argv[1]' was provided." >&2
            _dotconfig_help >&2
            return 1
    end
end
