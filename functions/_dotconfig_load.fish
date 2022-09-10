function _dotconfig_load -a script_name
    if test -z $script_name
        set script_name config.fish
    end

    for file in $dotconfig_module_dir/*/$script_name
        source $file
    end
end
