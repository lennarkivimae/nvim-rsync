# nvim-rsync

## Intro
Oh hi there! Fancy seeing you here. This plugin was heavily inspired from (nvim-arsync)[https://github.com/KenN7/vim-arsync].
For me the plugin lacked to sync multiple directories. I couldn't find anything else, so here we are. I'm using it primarly with ssh keys. The keys are defined in config, using configuration set host with rsync.
The plugin should also support ssh password via sshpass. Again, I have not tested whether it works or not.

The plugin only supports uploading files or known as up direction. It lacks down direction. It should work with local directories. However I have not tested it as I do not have the need for it myself. This is public source, if anyone else benefits from the unbelivably average and mediocre plugin. I'm more than happy for you!

Plugin notifies on successful rsync command. If there are errors, it opens separate buffer with output for more convenient debugging.

Licence MIT - AKA do whatever you want license

## Installation

I can comment only on using Lazy, as I'm using Lazy for package management. Include it like so:
```lua
{ 'lennarkivimae/nvim-rsync' }
```
No additional configuration is required. The plugin sync is automatically triggered on project buffer save.

## Configuration

Configuration should be in root directory of the project.
 - It must be named .nvim-rsync.config.lua.
 - If configuration file is not found, the plugin silently fails.

Opting for lua configuration was a choice, as I didn't have to do any additional work to get structure I wanted from a config file.

```lua
return {
    remote_host = "", -- Required
    remote_port = 22, -- Optional. It must be defined, if you are not using ssh config that specifies the port
    use_key = true, -- Optional, triggers if should use ssh user and password
    remote_user = "", -- Optional
    remote_pass = "", -- Optional
    paths = {
        {
            remote_path = "", -- Path to remote directory
            local_path = "", -- Path to local directory
            ignored = {}, -- Array of ignored files
        },
    },
    remote_options = "-vzr" -- Optional, you can pass in custom rsync flags.
    local_options = "-vr" -- Optional, used for local strategy
    ignore_dotfiles = true, -- Optional
    remote_or_local = "remote", -- Required, either remote or local
}
```

## Final thoughts
Well this is my first attempt at lua. Go easy on me. Thank you and have a nice day!

