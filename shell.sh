# shell operations

# import 
. ./file.sh

get_shell_sourcefile(){
    local shell_name="$1"
    # echo "$HOME/.config/$shell_name/sourcefile"
    echo "$HOME/.${shell_name}rc"
}

add_source(){
    local shell_name="$1"
    local to_source="$2"
    local source_file=$(get_shell_sourcefile "$shell_name")
    if [ -f "$source_file" ]; then
        append_if_missing "$source_file" "source $to_source"
    fi
}