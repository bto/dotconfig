complete -c dotconfig --no-files
complete -c dotconfig -n __fish_use_subcommand -a clone    -d "Clone dotconfig config repository"
complete -c dotconfig -n __fish_use_subcommand -a help     -d "Show usage help"
complete -c dotconfig -n __fish_use_subcommand -a init     -d "Initialize all packages"
complete -c dotconfig -n __fish_use_subcommand -a load     -d "Load script(config.fish for default) of all modules"
complete -c dotconfig -n __fish_use_subcommand -a set_path -d "Set path variable"
complete -c dotconfig -n __fish_use_subcommand -a setup    -d "Clone, Initialize, Load"
