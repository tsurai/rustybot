local Core = {}

local plugin_list = {}
local Manager = {}

function Core.init(manager, plugins)
  Manager = manager
  plugin_list = plugins
end

function Core.cleanup()

end

function Core.name()
  return "core"
end

function Core.description()
  return "no description"
end

function Core.listen(from, to, input)
  if string.match(input, "list all plugins") ~= nil then
    out = "My current plugins are: "
    for name, plugin in pairs(plugin_list) do
      out = out..string.lower(plugin.name())..", "
    end

    send("PRIVMSG", to, string.sub(out, 1, string.len(out)-2))
    return true

  --[[else
    match = string.match(input, "show commands for (.*)")
    if match ~= nil then
    if
    return true
  ]]--
  elseif string.match(input, "reload plugins") ~= nil then
    Manager.unload_plugins()
    if Manager.load_plugins(plugin_path) ~= true then
      send("PRIVMSG", to "Failed to reload script")
    else
      send("PRIVMSG", to, "Plugins have been reloaded")
    end
    return true

  elseif string.match(input, "who are you%??") ~= nil then
    send("PRIVMSG", to, "I'm a rustybot v"..version().." powered by Rust v0.10-pre")
    return true
  end

  return false
end

return Core