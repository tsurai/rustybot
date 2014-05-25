-- manager.lua
dofile("utils.lua")

local plugin_list = {}
local plugin_path = ""

local Manager = {}

local function is_valid_plugin(plugin)
  ret = true
  function_names = {"init", "cleanup", "name", "description", "listen"}

  for i, fn in ipairs(function_names) do
    if type(plugin[fn]) ~= "function" then
      print("Error: no " .. fn .. " function found")
       ret = false
    end
  end

  return ret
end

function Manager.load_plugins(path)
  ret = true
  plugin_path = path
  
  -- load all plugins
  for filename in io.popen("ls "..path):lines() do
    if string.find(filename, "%.lua$") then
      filepath = path.."/"..filename
      plugin, err = loadfile(filepath)
 
      if plugin ~= nil then
        plugin = plugin()

        if is_valid_plugin(plugin) then
          plugin_list[plugin.name()] = plugin
        end
      else
        ret = false
        print("Error: failed to load plugin.", err)  
      end
    end
  end

  -- initialize plugins
  for name, plugin in pairs(plugin_list) do
    if name == "core" then
      plugin.init(Manager, plugin_list)
    else
      plugin.init()
    end
  end

  return ret
end

function Manager.unload_plugins(path)
  for name, plugin in pairs(plugin_list) do
    plugin.cleanup()
    plugin_list[name] = nil
  end
end

function Manager.process_plugins(from, to, input)
  for name, plugin in pairs(plugin_list) do
    ret = plugin.listen(from, to, input)
    if ret == nil then
      print("error in plugin", name)
    elseif ret == true then
      return
    end
  end

  send("PRIVMSG", to, "I don't know that command")
end

return Manager