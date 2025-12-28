# lsetup
Store my personal configurations

## File structure
/
|---bash
    |---.config/bash
    |---.bashrc
    |---.bash_profile
    ...
|---zsh
|---tmux
    |---.config/tmux
    |---.tmux.conf
|---vim
    |---.config/vim
    |---.vimrc
|---v2ray
    |---.config/v2ray
    |---.local/bin/v2ray

## How to use
Please install stow(a symlink manager)
```
    sudo apt install stow
```
### Set symlink
```
    stow <module_name>
```
### Unset symlink
```
    stow -D <module_name>
```


## Softwares

### Proxy (mihomo)
Using systemd to run proxy background.
Using [mihomo-tui](https://github.com/potoo0/mihomo-tui) as the front-end manager.
The RESTful API for management listening at port 9090.
