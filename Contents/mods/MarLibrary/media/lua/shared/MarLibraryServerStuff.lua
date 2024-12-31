local function onClientCommand(module, command, player, data)
    if module ~= "MarLibrary" then return end
    sendServerCommand(module, command, data)
end

Events.OnClientCommand.Add(onClientCommand) --what the server gets from the client
