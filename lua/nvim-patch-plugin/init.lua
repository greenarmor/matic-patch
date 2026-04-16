local M = {}

-- Create a new buffer for the patch
local function create_patch_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_set_name(buf, "patch-input")
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].buftype = "nofile"
  return buf
end

-- Apply the patch from current buffer
local function apply_patch_from_buffer(patch_level)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local patch_content = table.concat(lines, "\n")

  if vim.trim(patch_content) == "" then
    vim.notify("No patch content found", vim.log.levels.ERROR)
    return false
  end

  -- Save to temp file and apply
  local temp_file = vim.fn.tempname()
  local f = io.open(temp_file, "w")
  if not f then
    vim.notify("Failed to create temp file", vim.log.levels.ERROR)
    return false
  end
  f:write(patch_content)
  f:close()

  -- Apply patch
  local level = patch_level or 1
  local cmd = string.format("patch -p%d --dry-run < %s", level, temp_file)
  local dry_run = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    -- Try with p0 if p1 fails
    if level == 1 then
      vim.notify("patch -p1 failed, trying -p0...", vim.log.levels.WARN)
      return apply_patch_from_buffer(0)
    end
    vim.notify("Patch failed:\n" .. dry_run, vim.log.levels.ERROR)
    vim.fn.delete(temp_file)
    return false
  end

  -- Actually apply the patch
  cmd = string.format("patch -p%d < %s", level, temp_file)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Patch application failed:\n" .. result, vim.log.levels.ERROR)
    vim.fn.delete(temp_file)
    return false
  end

  vim.fn.delete(temp_file)
  vim.notify("Patch applied successfully!", vim.log.levels.INFO)
  return true
end

-- Reload affected files
local function reload_affected_files()
  -- Get list of files from current buffer (patch format)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local files_to_reload = {}

  for _, line in ipairs(lines) do
    local file = line:match("^%+%+%+%s+(.+)%s+")
    if file then
      -- Strip a/ or b/ prefix if present
      file = file:gsub("^%a/", "")
      if vim.fn.filereadable(file) == 1 then
        table.insert(files_to_reload, file)
      end
    end
  end

  -- Reload each affected file
  for _, file in ipairs(files_to_reload) do
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_name:match(file .. "$") or buf_name == file then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("edit!")
        end)
      end
    end
  end

  return #files_to_reload > 0
end

-- Show diffsplit for affected files
local function show_diffsplit()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local first_file = nil

  for _, line in ipairs(lines) do
    local file = line:match("^%+%+%+%s+(.+)%s+")
    if file then
      -- Strip a/ or b/ prefix
      first_file = file:gsub("^%a/", "")
      break
    end
  end

  if first_file and vim.fn.filereadable(first_file) == 1 then
    vim.cmd("vert diffsplit " .. first_file)
  end
end

-- Main command function
local function code_command()
  -- Create patch buffer
  create_patch_buffer()

  -- Set up keybinding to apply patch
  vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "", {
    callback = function()
      if apply_patch_from_buffer(1) then
        reload_affected_files()
        vim.cmd("bdelete") -- Close patch buffer
        show_diffsplit()
      end
    end,
    desc = "Apply patch and reload files"
  })

  -- Set up escape to cancel
  vim.api.nvim_buf_set_keymap(0, "n", "<Esc>", ":bdelete<CR>", {
    desc = "Cancel patch"
  })

  -- Show instructions
  local instructions = {
    "",
    "╭─────────────────────────────────────╮",
    "│  PASTE YOUR PATCH BELOW              │",
    "│  Press <CR> to apply                 │",
    "│  Press <Esc> to cancel               │",
    "╰─────────────────────────────────────╯",
    ""
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, instructions)
  vim.cmd("normal! G")
end

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Create the :Code command
  vim.api.nvim_create_user_command("Code", code_command, {
    desc = "Apply a patch from a new buffer",
    nargs = 0
  })
end

return M
