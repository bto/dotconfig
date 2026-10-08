function _dotconfig_install_loader -d "Add the dotconfig loader to config.fish."
    # $__fish_config_dir is where fish reads config.fish from, and it is set
    # even when this runs before `dotconfig` sets $fish_config_dir.
    set config_file $__fish_config_dir/config.fish
    if test -e $config_file; and not test -r $config_file
        echo "dotconfig: cannot read $config_file" >&2
        return 1
    end
    if command grep -qE '^[[:space:]]*(type -q dotconfig; and )?dotconfig load[[:space:]]*$' $config_file 2> /dev/null
        return
    end
    if not printf '\n# Added by dotconfig\n%s\n' 'type -q dotconfig; and dotconfig load' >> $config_file
        echo "dotconfig: failed to update $config_file" >&2
        return 1
    end
end
