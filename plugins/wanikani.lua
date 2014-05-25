local http = require("socket.http")
local url  = require("socket.url")

local Wanikani = {}
local api_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

function Wanikani.init()

end

function Wanikani.cleanup()

end

function Wanikani.name()
  return "wanikani"
end

function Wanikani.description()
  return "no description"
end

function Wanikani.listen(from, to, input)
  if string.match(input, "show my wk queue") ~= nil then
    ret, status = http.request("https://www.wanikani.com/api/user/"..api_key.."/study-queue")
    if ret ~= nil then
      lessons_now, reviews_now, reviews_time, reviews_next_hour, reviews_next_day = string.match(ret, ".*\"requested_information\":{.-(%d+).-(%d+).-(%d+).-(%d+).-(%d+)}")

      time = "available now"
      diff = os.difftime(reviews_time, os.time())
      if diff > 0 then
        time = (diff/60/60).."hours"
      end
      
      send("PRIVMSG", to, bold("Reviews: ")..reviews_now..", "..bold("Lessons: ")..lessons_now..", "..bold("Reviews in: ")..time..", "..bold("Next hour: ")..reviews_next_hour..", "..bold("Next day: ")..reviews_next_day) 
      return true
    end

  elseif string.match(input, "show my wk stats") ~=nil then
    ret, status = http.request("https://www.wanikani.com/api/user/"..api_key.."/srs-distribution")
    if ret ~= nil then
      appr_radical, appr_kanji, appr_vocabulary, appr_total = string.match(ret, "\"apprentice\":{.-(%d+).-(%d+).-(%d+).-(%d+)}")
      guru_radical, guru_kanji, guru_vocabulary, guru_total = string.match(ret, "\"guru\":{.-(%d+).-(%d+).-(%d+).-(%d+)}")
      master_radical, master_kanji, master_vocabulary, master_total = string.match(ret, "\"master\":{.-(%d+).-(%d+).-(%d+).-(%d+)}")
      enlighten_radical, enlighten_kanji, enlighten_vocabulary, enlighten_total = string.match(ret, ".*\"enlighten\":{.-(%d+).-(%d+).-(%d+).-(%d+)}")
      burned_radical, burned_kanji, burned_vocabulary, burned_total = string.match(ret, "\"burned\":{.-(%d+).-(%d+).-(%d+).-(%d+)}")

      send("PRIVMSG", to, bold("Radicals").." -> "..bold("Apprentice: ")..appr_radical..", "..bold("Guru: ")..guru_radical..", "..bold("Master: ")..master_radical..", "..bold("Enlighten: ")..enlighten_radical..", "..bold("Burned: ")..burned_radical)
      send("PRIVMSG", to, bold("Kanji   ").." -> "..bold("Apprentice: ")..appr_kanji..", "..bold("Guru: ")..guru_kanji..", "..bold("Master: ")..master_kanji..", "..bold("Enlighten: ")..enlighten_kanji..", "..bold("Burned: ")..burned_kanji)
      send("PRIVMSG", to, bold("Vocab   ").." -> "..bold("Apprentice: ")..appr_vocabulary..", "..bold("Guru: ")..guru_vocabulary..", "..bold("Master: ")..master_vocabulary..", "..bold("Enlighten: ")..enlighten_vocabulary..", "..bold("Burned: ")..burned_vocabulary)
      send("PRIVMSG", to, bold("Total   ").." -> "..bold("Apprentice: ")..appr_total..", "..bold("Guru: ")..guru_total..", "..bold("Master: ")..master_total..", "..bold("Enlighten: ")..enlighten_total..", "..bold("Burned: ")..burned_total)
 
      return true
    end
  end

  return false
end

return Wanikani
