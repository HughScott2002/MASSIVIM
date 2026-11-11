-- SDK-aware feature checks use disposable projects and never save real sources.
local function run()
  vim.cmd "Lazy! load nvim-lspconfig"
  local root = vim.fn.tempname()
  vim.fn.mkdir(root, "p")
  local cases = {
    {
      name = "dart",
      server = "dartls",
      file = "lib/main.dart",
      marker = "pubspec.yaml",
      project = "name: semantic_fixture\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'\n",
      symbol = "doubleIt",
      lines = { "int doubleIt(int value) => value * 2;", "void main() { final value = doubleIt(2); }" },
      row = 2,
    },
    {
      name = "swift",
      server = "sourcekit",
      file = "Sources/Fixture/main.swift",
      marker = "Package.swift",
      project = '// swift-tools-version:6.0\nimport PackageDescription\nlet package = Package(name: "Fixture", targets: [.executableTarget(name: "Fixture")])\n',
      symbol = "doubleIt",
      lines = { "func doubleIt(_ value: Int) -> Int { value * 2 }", "let answer = doubleIt(2)" },
      row = 2,
    },
    {
      name = "ruby",
      server = "ruby_lsp",
      file = "fixture.rb",
      marker = "Gemfile",
      project = "# No external gems for this fixture\n",
      symbol = "upcase",
      lines = { 'text = "hello"', "answer = text.upcase" },
      row = 2,
    },
    {
      name = "powershell",
      server = "powershell_es",
      file = "fixture.ps1",
      marker = "PSScriptAnalyzerSettings.psd1",
      project = "@{}\n",
      symbol = "Get-Greeting",
      lines = { "function Get-Greeting { 'hello' }", "Get-Greeting" },
      row = 2,
    },
    {
      name = "wgsl",
      server = "wgsl_analyzer",
      file = "fixture.wgsl",
      marker = ".git/description",
      project = "temporary semantic fixture\n",
      symbol = "doubleIt",
      lines = {
        "fn doubleIt(value: i32) -> i32 { return value * 2; }",
        "@compute @workgroup_size(1) fn main() { let answer = doubleIt(2); }",
      },
      row = 2,
    },
    {
      name = "astro",
      server = "astro",
      file = "src/index.astro",
      marker = "package.json",
      project = '{"name":"semantic-fixture","type":"module","dependencies":{"astro":"*"}}\n',
      symbol = "doubleIt",
      lines = {
        "---",
        "function doubleIt(value: number): number { return value * 2; }",
        "const answer = doubleIt(2);",
        "---",
        "<p>{answer}</p>",
      },
      row = 3,
    },
  }
  local reports = {}
  for _, case in ipairs(cases) do
    local dir = root .. "/" .. case.name
    vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. case.marker), "p")
    vim.fn.writefile(vim.split(case.project, "\n", { plain = true }), dir .. "/" .. case.marker)
    vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. case.file), "p")
    vim.fn.writefile(case.lines, dir .. "/" .. case.file)
    local report = { language = case.name, server = case.server }
    if case.name == "astro" then
      if not vim.env.MASSIVIM_ASTRO_NODE_MODULES then
        report.status = "unverified_no_project_dependencies"
      else
        assert(vim.uv.fs_symlink(vim.env.MASSIVIM_ASTRO_NODE_MODULES, dir .. "/node_modules", { dir = true }))
      end
    end
    if not report.status then
      if case.name == "dart" then
        local prepared = vim.system({ "dart", "pub", "get", "--offline" }, { cwd = dir, text = true }):wait(30000)
        report.package_config = prepared.code == 0
      end
      vim.cmd("cd " .. vim.fn.fnameescape(dir))
      vim.cmd("edit " .. vim.fn.fnameescape(dir .. "/" .. case.file))
      local buf = vim.api.nvim_get_current_buf()
      assert(
        vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), case.lines),
        "Fixture text changed before attachment"
      )
      local client
      vim.wait(20000, function()
        for _, c in ipairs(vim.lsp.get_clients { bufnr = buf }) do
          if c.name == case.server then
            client = c
            return c.initialized
          end
        end
        return false
      end, 100)
      if not client then
        report.status = "unverified_no_attachment"
      else
        vim.wait(3000, function()
          return false
        end, 100)
        local column = assert(case.lines[case.row]:find(case.symbol, 1, true)) - 1
        for _, feature in ipairs { "hover", "definition", "completion" } do
          local success = false
          for _ = 1, 6 do
            vim.api.nvim_win_set_cursor(0, { case.row, column + (feature == "completion" and 3 or 1) })
            local params = {
              textDocument = { uri = vim.uri_from_bufnr(buf) },
              position = { line = case.row - 1, character = column + (feature == "completion" and 3 or 1) },
            }
            if feature == "completion" then
              params.context = { triggerKind = 1 }
            end
            local response = client:request_sync("textDocument/" .. feature, params, 2000, buf)
            local result = response and not response.err and response.result
            if type(result) == "table" then
              if feature == "completion" then
                success = #(result.items or result) > 0
              elseif feature == "hover" then
                success = type(result.contents) == "string" and #result.contents > 0
                  or type(result.contents) == "table" and not vim.tbl_isempty(result.contents)
              else
                success = not vim.tbl_isempty(result)
              end
            end
            report[feature .. "_response"] = vim.inspect(response):sub(1, 1800)
            if success then
              break
            end
            vim.wait(500, function()
              return false
            end, 100)
          end
          report[feature] = success
        end
        report.status = report.hover and report.definition and report.completion and "pass"
          or "partial_semantic_features"
        client:stop()
      end
      vim.cmd "bwipeout!"
      vim.wait(500, function()
        return false
      end, 100)
      for _, c in ipairs(vim.lsp.get_clients()) do
        c:stop(true)
      end
    end
    reports[#reports + 1] = report
    vim.fn.writefile({ vim.json.encode(reports) }, assert(vim.env.MASSIVIM_OUTPUT))
    print(case.name .. ": " .. report.status)
  end
  vim.fn.delete(root, "rf")
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  print(err)
  vim.cmd "cquit 1"
end
