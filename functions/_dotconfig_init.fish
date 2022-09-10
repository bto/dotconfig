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
