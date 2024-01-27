local Sync = {
    errorBuffer = nil
}

if not vim.fn.executable('rsync') then
    vim.api.nvim_err_writeln('Rsync required. Please install rsync to use FTPSync')

    return
end

function Sync.Split(input, separator)
    if separator == nil then
        separator = "%s" -- default separator is space
    end

    local results = {}
    for str in string.gmatch(input, "([^" .. separator .. "]+)") do
        table.insert(results, str)
    end

    return results
end

function Sync.LoadConfiguration()
    local config = {}
    local configFile = vim.fn.filereadable(".nvim-rsync.config.lua")

    if configFile > 0 then
        local filePath = vim.fn.getcwd() .. "/.nvim-rsync.config.lua"
        config = dofile(filePath)
    else
        vim.api.nvim_err_writeln("Failed to load configuration file")
    end

    config["local_path"] = config["local_path"] or vim.fn.getcwd()
    config["remote_or_local"] = config["remote_or_local"] or "remote"
    config["local_options"] = config["local_options"] or "-vr"
    config["remote_options"] = config["remote_options"] or "-vzr"

    return config
end

function Sync.HasKeyOrRemoteDetails(config)
    if not config["use_key"] then
        if not config["remote_user"] or not config["remote_password"] then
            vim.api.nvim_err_writeln("Either specify use key or specify remote_user and remote_password in the configuration file")

            return false
        end
    end

    return true
end

function Sync.GetIgnoredPathsForRsync(ignoredPaths)
    local excluded = {}

    if ignoredPaths then
        for _, path in pairs(ignoredPaths) do
            table.insert(excluded, "--exclude '" .. path .. "'")
        end
    end

    if next(excluded) == nil then
        return ""
    end

    return table.concat(excluded, " ")
end

function Sync.PrepareCommands()
    local config = Sync.LoadConfiguration()

    if not Sync.HasKeyOrRemoteDetails(config) then
        vim.api.nvim_err_writeln("Either specify use key or specify remote_user and remote_password in the configuration file")

        return
    end

    local remoteOrLocal = config["remote_or_local"]
    local host = config["remote_host"]
    local port = config["remote_port"]
    local usingKeyFile = config["use_key"]
    local remoteOptions = config["remote_options"]
    local localOptions = config["local_options"]
    local ignoreDotfiles = config["ignore_dotfiles"]
    local remoteUser = config["remote_user"] or ""
    local remotePassword = config["remote_password"] or ""

    local rsyncCommands = {}

    for _, path in pairs(config["paths"]) do
        local remotePath = path["remote_path"]
        local localPath = path["local_path"]
        local ignoredPaths = path["ignored"]

        local command = {}

        if remoteOrLocal == "remote" then
            command = {
                (usingKeyFile and "" or "sshpass -p " .. remotePassword),
                "rsync",
                remoteOptions,
                (port and "-e 'ssh -p " .. port .. "'" or ""),
                (ignoreDotfiles and "--exclude '.*'" or ""),
                Sync.GetIgnoredPathsForRsync(ignoredPaths),
                localPath,
                (usingKeyFile and host .. ":" .. remotePath or remoteUser .. "@" .. host .. ":" .. remotePath),
            }
        elseif remoteOrLocal == "local" then
            command = {
                "rsync",
                localOptions,
                (ignoreDotfiles and "--exclude '.*'" or ""),
                Sync.GetIgnoredPathsForRsync(ignoredPaths),
                localPath,
                remotePath,
            }
        else
            vim.api.nvim_err_writeln("Specify remote_or_local as 'remote' or 'local' in the configuration file")

            return
        end

        table.insert(rsyncCommands, table.concat(command, " "))
    end

    Sync.DisplayError(nil, rsyncCommands)

    return rsyncCommands
end

function Sync.FormatErrors(errors)
    return table.concat(errors, "\n")
end

function Sync.DisplayError(commands, data)
    if commands == nil then
        return
    end

    local dataAsString = table.concat(data, '')

    for _, command in pairs(commands) do
        if string.match(dataAsString, command) then
            return
        end
    end

    if dataAsString == "" then
        return
    end

    Sync.OpenErrorBuffer()

    local lineCount = vim.api.nvim_buf_line_count(Sync.errorBuffer)
    vim.api.nvim_buf_set_lines(Sync.errorBuffer, lineCount, -1, false, data)
end

function Sync.ClearErrorBuffer()
    if Sync.errorBuffer and vim.api.nvim_buf_is_valid(Sync.errorBuffer) then
        vim.api.nvim_buf_set_lines(Sync.errorBuffer, 0, -1, false, {})
    end
end

function Sync.OpenErrorBuffer()
    if not Sync.errorBuffer or not vim.api.nvim_buf_is_valid(Sync.errorBuffer) then
        Sync.errorBuffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(Sync.errorBuffer, 'buftype', 'nofile')
    end

    local win_found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == Sync.errorBuffer then
            win_found = true
            break
        end
    end

    if not win_found then
        vim.cmd("vsplit")
        vim.api.nvim_win_set_buf(0, Sync.errorBuffer)
    end
end

function Sync.Execute()
    Sync.ClearErrorBuffer()
    local commands = Sync.PrepareCommands()

    if commands then
        for _, command in pairs(commands) do
            vim.fn.jobstart(command, {
                on_stderr = function(_, data) Sync.DisplayError(commands, data) end,
                on_exit = function() print("Rsync completed") end,
            })
        end
    end
end

vim.api.nvim_create_user_command('FTPSync', Sync.Execute, {})

vim.api.nvim_create_augroup('FTPSync', { clear = true })
vim.api.nvim_create_autocmd({ 'DirChanged' }, {
    group = 'FTPSync',
    callback = Sync.Execute,
})

