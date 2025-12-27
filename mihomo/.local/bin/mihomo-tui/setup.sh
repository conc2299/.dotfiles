PATH=$HOME/.local/bin/mihomo:$PATH

update_proxy_subscription(){
    if [ -z "$1" ]; then
        echo "Usage: update_proxy_subscription <subscription_url>"
        return 1
    fi
    local file_path="$HOME/.config/mihomo/config.yaml"
    if [ -f "$file_path" ]; then
        rm "$file_path"
    fi
    curl -s "$1" -o "$file_path"
}