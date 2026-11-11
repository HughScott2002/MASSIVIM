local function run()
  vim.cmd "Lazy! load nvim-lspconfig"
  local manifest = vim.json.decode(table.concat(vim.fn.readfile(assert(vim.env.MASSIVIM_MANIFEST)), "\n"))
  local results = {}
  for _, entry in ipairs(manifest) do
    local result = vim.deepcopy(entry)
    vim.cmd("cd " .. vim.fn.fnameescape(entry.repo))
    local ok, err = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(entry.repo .. "/" .. entry.path))
    if not ok then
      result.status = "open_error"
      result.error = tostring(err)
    else
      local buf = vim.api.nvim_get_current_buf()
      result.filetype = vim.bo[buf].filetype
      local function expected_attached()
        for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
          if not entry.expected or vim.tbl_contains(entry.expected, client.name) then
            return true
          end
        end
        return false
      end
      local attached = vim.wait(tonumber(vim.env.MASSIVIM_ATTACH_TIMEOUT) or 6000, expected_attached, 100)
      if attached then
        vim.wait(1500, function()
          return false
        end, 100)
      end
      result.clients = {}
      for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
        local c = { name = client.name, root = client.config.root_dir, initialized = client.initialized }
        for _, feature in ipairs { "hover", "definition", "completion" } do
          local method = "textDocument/" .. feature
          if client:supports_method(method, buf) then
            local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
            if feature == "completion" then
              params.context = { triggerKind = 1 }
            end
            local response, failure = client:request_sync(method, params, 1200, buf)
            c[feature] = response and not response.err and (response.result ~= nil and "response" or "empty")
              or (failure or "error")
          else
            c[feature] = "unsupported"
          end
        end
        result.clients[#result.clients + 1] = c
      end
      result.status = attached and "attached" or "unverified_no_attachment"
      for _, client in ipairs(vim.lsp.get_clients()) do
        client:stop()
      end
      vim.wait(1000, function()
        return #vim.lsp.get_clients() == 0
      end, 50)
      for _, client in ipairs(vim.lsp.get_clients()) do
        client:stop(true)
      end
      vim.cmd "bwipeout!"
    end
    results[#results + 1] = result
    if #results % 10 == 0 then
      io.stderr:write("Attachment checks " .. #results .. "\n")
    end
    vim.fn.writefile({ vim.json.encode(results) }, assert(vim.env.MASSIVIM_OUTPUT))
  end
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd "cquit 1"
end
