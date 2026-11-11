local function run()
  vim.cmd "syntax enable"
  local manifest=vim.json.decode(table.concat(vim.fn.readfile(assert(vim.env.MASSIVIM_MANIFEST)),"\n"))
  local results={}
  for _,entry in ipairs(manifest) do
    local result=vim.deepcopy(entry)
    local ok,err=pcall(function()
      local lines=vim.fn.readfile(entry.repo.."/"..entry.path,"",200)
      local buf=vim.api.nvim_create_buf(false,true)
      vim.api.nvim_buf_set_lines(buf,0,-1,false,lines)
      vim.api.nvim_buf_call(buf,function()
        vim.bo.syntax=entry.filetype
        result.loaded=vim.b.current_syntax~=nil
        result.highlighted=false
        for row=1,math.min(#lines,40) do
          for col=1,math.min(#lines[row],100) do
            if vim.fn.synID(row,col,1)~=0 then result.highlighted=true;break end
          end
          if result.highlighted then break end
        end
      end)
      vim.api.nvim_buf_delete(buf,{force=true})
    end)
    result.status=ok and result.loaded and result.highlighted and "syntax_fallback_verified" or (ok and "plain_or_no_syntax_match" or "syntax_runtime_error")
    if not ok then result.error=tostring(err) end
    results[#results+1]=result
  end
  vim.fn.writefile({vim.json.encode(results)},assert(vim.env.MASSIVIM_OUTPUT))
end
local ok,err=xpcall(run,debug.traceback)
if not ok then print(err);vim.cmd "cquit 1" end
