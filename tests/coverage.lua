-- Input is a JSON array of {repo,path,scope}; output contains no source contents.
local function run()
  vim.cmd "Lazy! load nvim-treesitter"
  local manifest = vim.json.decode(table.concat(vim.fn.readfile(assert(vim.env.MASSIVIM_MANIFEST)), "\n"))
  local results = {}
  local output = assert(vim.env.MASSIVIM_OUTPUT)
  if vim.env.MASSIVIM_RESUME and vim.fn.filereadable(output) == 1 then
    results = vim.json.decode(table.concat(vim.fn.readfile(output), "\n"))
    for i, result in ipairs(results) do
      assert(
        manifest[i] and manifest[i].repo == result.repo and manifest[i].path == result.path,
        "Checkpoint does not match manifest"
      )
    end
  end
  for index = #results + 1, #manifest do
    local entry = manifest[index]
    local result = { repo = entry.repo, path = entry.path, scope = entry.scope }
    local path = entry.repo .. "/" .. entry.path
    local fd = io.open(path, "rb")
    if not fd then
      result.status = "missing"
    else
      local text = fd:read "*a"
      fd:close()
      if text:find("\0", 1, true) or #text > (tonumber(vim.env.MASSIVIM_MAX_BYTES) or math.huge) then
        result.status = text:find("\0", 1, true) and "binary" or "size_limit"
      else
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(text, "\n", { plain = true }))
        local ft = vim.filetype.match { filename = path, buf = buf }
        result.filetype = ft or ""
        local lang = ft and vim.treesitter.language.get_lang(ft)
        result.language = lang or ""
        if ft == "jsonl" then
          result.status = "line_validation"
          result.invalid_records = 0
          for line in text:gmatch "[^\n]+" do
            if line:match "%S" and not pcall(vim.json.decode, line) then
              result.invalid_records = result.invalid_records + 1
            end
          end
        elseif
          ft == "metal"
          or ft == "opencl"
          or not lang
          or not (function()
            local ok, loaded = pcall(vim.treesitter.language.add, lang)
            return ok and loaded
          end)()
        then
          result.status = "parser_unavailable"
          result.syntax = ft and #vim.api.nvim_get_runtime_file("syntax/" .. ft .. ".vim", false) > 0 or false
        else
          local ok, err = xpcall(function()
            local parser = vim.treesitter.get_string_parser(text, lang)
            parser:parse(true)
            result.top_error = false
            result.injection_errors = 0
            parser:for_each_tree(function(tree, language_tree)
              if language_tree == parser then
                result.top_error = result.top_error or tree:root():has_error()
              elseif tree:root():has_error() then
                result.injection_errors = result.injection_errors + 1
              end
            end)
            local highlights = vim.treesitter.query.get(lang, "highlights")
            result.highlights = highlights ~= nil
            if highlights then
              local tree = parser:trees()[1]
              if tree then
                for _ in highlights:iter_captures(tree:root(), text, 0, -1) do
                end
              end
            end
            result.indent_query = vim.treesitter.query.get(lang, "indents") ~= nil
            parser:destroy()
            result.status = "parsed"
          end, debug.traceback)
          if not ok then
            result.status = "runtime_error"
            result.error = err
          end
        end
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    results[#results + 1] = result
    if #results % 500 == 0 then
      vim.fn.writefile({ vim.json.encode(results) }, output)
      io.stderr:write("Scanned " .. #results .. " files\n")
    end
  end
  vim.fn.writefile({ vim.json.encode(results) }, assert(vim.env.MASSIVIM_OUTPUT))
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd "cquit 1"
end
