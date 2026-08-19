local M = {}

local state = {
  enabled = false,
  origin_win = nil,
  backdrop_win = nil,
  zen_win = nil,
  quit_pending = false,
  augroup = vim.api.nvim_create_augroup('custom-zen-mode', { clear = true }),
}

local ZEN_WIDTH = 83

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function in_tmux()
  return vim.env.TMUX and vim.env.TMUX ~= '' and vim.fn.executable 'tmux' == 1
end

local function tmux(args)
  if not in_tmux() then return nil end

  local result = vim.system(vim.list_extend({ 'tmux' }, args)):wait()
  if result.code ~= 0 then return nil end

  return vim.trim(result.stdout or '')
end

local function hide_tmux_status()
  tmux { 'set-option', 'status', 'off' }
end

local function restore_tmux_status()
  tmux { 'set-option', 'status', 'on' }
end

local function configure_zen_window(win)
  vim.wo[win].number = true
  vim.wo[win].relativenumber = true
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].list = false
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
end

local function create_backdrop()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = vim.o.columns,
    height = math.max(1, vim.o.lines - vim.o.cmdheight - 1),
    row = 0,
    col = 0,
    style = 'minimal',
    focusable = true,
    zindex = 40,
  })

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].list = false
  vim.wo[win].cursorline = false

  return win
end

local function zen_config()
  local width = math.min(ZEN_WIDTH, vim.o.columns)

  return {
    relative = 'editor',
    width = width,
    height = math.max(1, vim.o.lines - vim.o.cmdheight - 1),
    row = 0,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'none',
    zindex = 50,
  }
end

local function resize()
  if valid_win(state.backdrop_win) then
    vim.api.nvim_win_set_config(state.backdrop_win, {
      relative = 'editor',
      width = vim.o.columns,
      height = math.max(1, vim.o.lines - vim.o.cmdheight - 1),
      row = 0,
      col = 0,
    })
  end

  if valid_win(state.zen_win) then
    vim.api.nvim_win_set_config(state.zen_win, zen_config())
  end
end

local function guard_focus()
  local current_win = vim.api.nvim_get_current_win()

  if state.enabled and current_win ~= state.zen_win and valid_win(state.zen_win) then
    vim.api.nvim_set_current_win(state.zen_win)
  end
end

function M.disable()
  vim.api.nvim_clear_autocmds { group = state.augroup }
  restore_tmux_status()

  if valid_win(state.zen_win) then vim.api.nvim_win_close(state.zen_win, true) end
  if valid_win(state.backdrop_win) then vim.api.nvim_win_close(state.backdrop_win, true) end

  if valid_win(state.origin_win) then
    vim.api.nvim_set_current_win(state.origin_win)
  end

  state.enabled = false
  state.origin_win = nil
  state.backdrop_win = nil
  state.zen_win = nil
end

local function quit_from_zen()
  if not state.enabled or state.quit_pending then return end

  state.quit_pending = true
  M.disable()

  vim.schedule(function()
    state.quit_pending = false
    pcall(vim.cmd.quit)
  end)
end

function M.enable()
  local buf = vim.api.nvim_get_current_buf()

  state.origin_win = vim.api.nvim_get_current_win()
  hide_tmux_status()
  state.backdrop_win = create_backdrop()
  state.zen_win = vim.api.nvim_open_win(buf, true, zen_config())

  configure_zen_window(state.zen_win)

  state.enabled = true

  vim.api.nvim_create_autocmd('VimResized', {
    group = state.augroup,
    callback = resize,
  })

  vim.api.nvim_create_autocmd('WinEnter', {
    group = state.augroup,
    callback = guard_focus,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = state.augroup,
    callback = restore_tmux_status,
  })

  vim.api.nvim_create_autocmd('QuitPre', {
    group = state.augroup,
    callback = quit_from_zen,
  })
end

function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
end

vim.keymap.set('n', '<leader>z', M.toggle, { desc = 'Toggle zen mode' })

return M
