function _dotconfig_clone -a repo
    if test -z $repo
        echo "No repository was provided." >&2
        _dotconfig_help $argv >&2
        return 1
    end

    git clone https://github.com/$repo.git $dotconfig_config_dir
end
