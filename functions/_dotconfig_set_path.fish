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
