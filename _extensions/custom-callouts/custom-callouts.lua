-- custom-callouts.lua
-- Custom "Recap" and "Issue" environments with cross-page cross-referencing and hover preview

local counts = { recap = 0, iss = 0 }
local current_chapter = 1
local current_file = ""
local ref_map = {}
local global_refs = {}

local ref_file_path = "_custom-callout-refs.json"

function load_global_refs()
  local f = io.open(ref_file_path, "r")
  if f then
    local content = f:read("*all")
    f:close()
    -- Updated pattern to include title and preview
    for id, label, number, file, title, preview in content:gmatch('"([^"]+)":%s*{%s*"label":%s*"([^"]+)",%s*"number":%s*"([^"]+)",%s*"file":%s*"([^"]*)",%s*"title":%s*"([^"]*)",%s*"preview":%s*"([^"]*)"%s*}') do
      global_refs[id] = {
        label = label,
        number = number,
        file = file,
        title = title,
        preview = preview
      }
    end
  end
end

function save_refs()
  load_global_refs()
  
  for id, info in pairs(ref_map) do
    global_refs[id] = {
      label = info.label,
      number = info.number,
      file = current_file,
      title = info.title or "",
      preview = info.preview or ""
    }
  end
  
  local f = io.open(ref_file_path, "w")
  if f then
    f:write("{\n")
    local first = true
    for id, info in pairs(global_refs) do
      if not first then f:write(",\n") end
      first = false
      -- Escape quotes and newlines in preview
      local preview = (info.preview or ""):gsub('"', '\\"'):gsub("\n", " "):sub(1, 200)
      local title = (info.title or ""):gsub('"', '\\"')
      f:write(string.format('  "%s": {"label": "%s", "number": "%s", "file": "%s", "title": "%s", "preview": "%s"}', 
        id, info.label, info.number, info.file or "", title, preview))
    end
    f:write("\n}\n")
    f:close()
  end
end

function Meta(meta)
  load_global_refs()
  
  if meta["title"] then
    local title_str = pandoc.utils.stringify(meta["title"])
    local num = title_str:match("^(%d+)")
    if num then
      current_chapter = tonumber(num)
    end
  end
  
  if PANDOC_STATE and PANDOC_STATE.output_file then
    current_file = PANDOC_STATE.output_file:match("([^/]+)$") or ""
  end
  
  return meta
end

function Header(el)
  if el.level == 1 then
    counts = { recap = 0, iss = 0 }
  end
  return el
end

function Div(el)
  local kind = nil
  if el.classes:includes("recap") then 
    kind = "recap"
  elseif el.classes:includes("iss") then 
    kind = "iss"
  end

  if not kind then return el end

  counts[kind] = counts[kind] + 1
  local label_text = (kind == "recap") and "Recap" or "Issue"
  local display_num = tostring(current_chapter) .. "." .. tostring(counts[kind])

  local block_id = el.identifier or ""

  local title_inlines = pandoc.Inlines({})
  local new_content = pandoc.List({})
  local preview_text = ""
  
  for _, block in ipairs(el.content) do
    if block.t == "Header" and #title_inlines == 0 then
      title_inlines = block.content:clone()
    else
      new_content:insert(block)
      -- Capture first paragraph as preview
      if block.t == "Para" and preview_text == "" then
        preview_text = pandoc.utils.stringify(block.content):sub(1, 200)
      end
    end
  end
  
  local title_text = pandoc.utils.stringify(title_inlines)
  
  if block_id ~= "" then
    ref_map[block_id] = {
      label = label_text,
      number = display_num,
      title = title_text,
      preview = preview_text
    }
  end
  
  el.content = new_content

  local prefix = pandoc.Inlines({})
  
  local label_span = pandoc.Span(
    {pandoc.Strong({pandoc.Str(label_text .. " " .. display_num)})},
    pandoc.Attr(block_id, {}, {})
  )
  prefix:insert(label_span)
  
  if #title_inlines > 0 then
    prefix:insert(pandoc.Space())
    prefix:insert(pandoc.Str("("))
    prefix:extend(title_inlines)
    prefix:insert(pandoc.Str(")"))
  end
  
  prefix:insert(pandoc.Str("."))
  prefix:insert(pandoc.Space())

  if #el.content > 0 and el.content[1].t == "Para" then
    local new_inlines = pandoc.List({})
    new_inlines:extend(prefix)
    new_inlines:extend(el.content[1].content)
    el.content[1] = pandoc.Para(new_inlines)
  elseif #el.content > 0 and el.content[1].t == "Plain" then
    local new_inlines = pandoc.List({})
    new_inlines:extend(prefix)
    new_inlines:extend(el.content[1].content)
    el.content[1] = pandoc.Plain(new_inlines)
  else
    el.content:insert(1, pandoc.Para(prefix))
  end

  el.classes = pandoc.List({"callout", "callout-" .. kind})
  if kind == "recap" then
    el.classes:insert("callout-note")
  else
    el.classes:insert("callout-warning")
  end
  
  el.identifier = ""
  el.attributes["data-callout-type"] = kind
  el.attributes["data-callout-number"] = display_num

  return el
end

function Cite(el)
  for _, citation in ipairs(el.citations) do
    local id = citation.id
    local info = ref_map[id] or global_refs[id]
    
    if info then
      local link_text = info.label .. "\u{00A0}" .. info.number
      local target = "#" .. id
      
      if info.file and info.file ~= "" and not ref_map[id] then
        target = info.file .. "#" .. id
      end
      
      local link = pandoc.Link(link_text, target)
      link.classes:insert("callout-ref")
      link.attributes["data-callout-label"] = info.label
      link.attributes["data-callout-number"] = info.number
      link.attributes["data-callout-title"] = info.title or ""
      link.attributes["data-callout-preview"] = info.preview or ""
      return link
    end
  end
  return el
end

function Pandoc(doc)
  save_refs()
  return doc
end

return {
  { Meta = Meta },
  { Header = Header, Div = Div },
  { Cite = Cite },
  { Pandoc = Pandoc }
}