function _dotconfig_help -d "Prints the help message for dotconfig."
    echo "\
USAGE:
    dotconfig [options] <command>

OPTIONS:
    -h, --help
        Print this help message.

COMMAND:
    clone <repository>
        Clone repository into $dotconfig_config_dir.

    help
        Print this help message.

    init
        Initialize all modules.

    load
        Load all modules.

    set_path
        Set path variable.

    setup
        Execute clone, init load commands.
"
end
