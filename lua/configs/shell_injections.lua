-- Resolve GitHub Actions shell precedence from YAML nodes. Unknown matrix
-- defaults and expressions remain YAML-highlighted, with no guessed shell.
local function text(node, source)
  return vim.treesitter.get_node_text(node, source)
end
local function mapping(node)
  if not node then
    return nil
  end
  if node:type() == "block_mapping" then
    return node
  end
  for child in node:iter_children() do
    if child:named() then
      local found = mapping(child)
      if found then
        return found
      end
    end
  end
end
local function value(node, key, source)
  node = mapping(node)
  if not node then
    return nil
  end
  for pair in node:iter_children() do
    if pair:type() == "block_mapping_pair" then
      local k, v = pair:field("key")[1], pair:field("value")[1]
      if k and text(k, source) == key then
        return v
      end
    end
  end
end
local function shell_for(node, source)
  if text(node, source):find("${{", 1, true) then
    return nil
  end
  local ancestor = node:parent()
  while ancestor do
    if ancestor:type() == "block_mapping" then
      local shell = value(ancestor, "shell", source)
      local defaults = value(ancestor, "defaults", source)
      shell = shell or value(value(defaults, "run", source), "shell", source)
      if shell then
        local name = text(shell, source):gsub("^['\"]", ""):match "^[%w_-]+"
        if name == "bash" or name == "sh" or name == "zsh" then
          return "bash"
        end
        if name == "pwsh" or name == "powershell" then
          return "powershell"
        end
        if name == "python" then
          return "python"
        end
        return nil
      end
      local platform = value(ancestor, "runs-on", source)
      -- Explicit job defaults outrank workflow defaults, but implicit OS shell
      -- selection must wait until workflow defaults have been considered.
      if platform then
        local root = ancestor
        while root:parent() do
          root = root:parent()
        end
        local global = value(value(value(root, "defaults", source), "run", source), "shell", source)
        if global then
          local name = text(global, source):gsub("^['\"]", ""):match "^[%w_-]+"
          return ({ bash = "bash", sh = "bash", pwsh = "powershell", powershell = "powershell", python = "python" })[name]
        end
        local os = text(platform, source)
        if os:match "^windows" then
          return "powershell"
        end
        if os:match "^ubuntu" or os:match "^macos" then
          return "bash"
        end
        return nil
      end
    end
    ancestor = ancestor:parent()
  end
end
vim.treesitter.query.add_directive("massivim-shell!", function(match, _, source, predicate, metadata)
  local nodes = match[predicate[2]]
  local node = type(nodes) == "table" and nodes[1] or nodes
  if node then
    metadata["injection.language"] = shell_for(node, source)
  end
end, { force = true, all = true })
return { shell_for = shell_for }
