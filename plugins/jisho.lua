local http = require("socket.http")
local url  = require("socket.url")

local Jisho = {}

function Jisho.init()

end

function Jisho.cleanup()

end

function Jisho.name()
  return "jisho"
end

function Jisho.description()
  return "no description"
end

function Jisho.listen(from, to, input)
  match = string.match(input, "jisho me (.*)")
  if match ~= nil then
    ret, status = http.request("http://beta.jisho.org/search/"..url.escape(match))
    ret = string.gsub(ret, "[\n\r\t]", "")
    if ret ~= nil then
      if string.find(ret, "zen_bar") ~= nil then
        -- make a sentence lookup
        t = {}
        out = ""
        for p, f, w in string.gmatch(ret, "data%-pos=\"(.-)\".-furigana.->(.-)</span><.->(.-)</.-></li>") do
          table.insert(t, {w, f, p})
        end

        offset = 0
        for i, entry in ipairs(t) do
          s, e = string.find(match, entry[1], offset, true)

          if s - offset ~= 1 then
            send("PRIVMSG", to, string.sub(match, offset+1, s-1))
          end
        
          out = bold(entry[1])
          if entry[2] ~= "" then
            out = out.." ("..entry[2]..")"
          end
          out = out.." ["..entry[3].."]"

          send("PRIVMSG", to, out)
          offset = e
        end
        return true
      else
        -- do a normal lookup
        item_count = 0
        for item, body in string.gmatch(ret, "concept_light\">.-\"text\">(.-)</span>%s-<[^s].-(.-)Details ▸") do
          send("PRIVMSG", to, bold(string.gsub(item, "[%s%w<>/]+", "")))

          out = ""
          for index, pos, meaning in string.gmatch(body, "section_divider\">(%d-)<.-meaning%-tags\">(.-)<.-meaning%-meaning\">(.-)<") do
            out = out..bold(red(index)..". "..pos).." "..meaning.." "
          end

          sentence = ""
          for word in string.gmatch(body, "unlinked\">(.-)<") do
            sentence = sentence .. word
          end

          send("PRIVMSG", to, out)
          if sentence ~= "" then
            sentence_english = string.match(body, "english\">(.-)</li>")
            send("PRIVMSG", to, bold("Example sentence: ")..sentence.." - "..sentence_english)
          end

          item_count = item_count + 1
          if item_count == 3 then
            break
          end
        end

        if item_count == 0 then
          send("PRIVMSG", to, "No search results")
        end

        return true
      end
    end
  end

  return false
end

return Jisho