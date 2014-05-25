local http = require("socket.http")

WolframAlpha = {}

local api_key = "XXXXXXXXXXXXXXXX"

function WolframAlpha.init()

end

function WolframAlpha.cleanup()

end

function WolframAlpha.name()
  return "wolfram alpha"
end

function WolframAlpha.description()
  return "no description"
end

function WolframAlpha.listen(from, to, input)
    return false
end

function WolframAlpha.query(query)
  if query ~= nil then
    ret, status = http.request("http://api.wolframalpha.com/v2/query?appid="..api_key.."&input="..query)
    if ret ~= nil then
      return ret
    end
  end

  return nil
end

return WolframAlpha
