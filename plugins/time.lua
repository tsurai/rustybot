local Time = {}

function Time.init()

end

function Time.cleanup()

end

function Time.name()
  return "time"
end

function Time.description()
  return "no description"
end

function Time.listen(from, to, input)
  match = string.match(input, "time in (.*)")
  if match ~= nil then
    io.write(match.."\n")
    ret = WolframAlpha.query("time%20in%20"..match.."&format=plaintext")
    if ret ~= nil then
      x, y, time = string.find(ret, ".*<pod title='Result'.-<plaintext>(.-)</plaintext>")
      if x ~= nil then
        send("PRIVMSG", to, time)
        return true
      end
    end
  end

  return false
end

return Time