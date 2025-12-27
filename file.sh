# file operations

append_if_missing(){
    local file="$1"
    local line="$2"
    grep -qxF "$line" "$file" || echo "$line" >> "$file"
}