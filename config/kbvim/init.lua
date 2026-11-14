-- kbvim: a small Neovim just for the vault. Launch with `kv`.
-- Lives in ~/.config/kbvim (NVIM_APPNAME=kbvim), so it never touches another nvim config.
-- First launch needs internet: it downloads the plugins below.

local vault = os.getenv("KB_VAULT") or vim.fn.expand("~/vault")

-- ── Options: tuned for prose, not code ───────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local o = vim.opt
o.background = "light"
o.termguicolors = true
o.number = false
o.relativenumber = false
o.signcolumn = "no"
o.wrap = true
o.linebreak = true
o.breakindent = true
o.conceallevel = 2
o.scrolloff = 8
o.spell = true
o.spelllang = { "en" }
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.clipboard = "unnamedplus"
o.mouse = "a"
o.laststatus = 3
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2

-- Move by screen line on wrapped text
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Autosave: notes should never be lost
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost", "BufLeave" }, {
  callback = function() vim.cmd("silent! wall") end,
})

-- Neovim ships markdown tree-sitter parsers; turn highlighting on
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() pcall(vim.treesitter.start) end,
})

-- ── Plugins (lazy.nvim) ──────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Soft, paper-like colours. <leader>ub flips light/dark.
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({ variant = "auto", dark_variant = "moon" })
      vim.cmd.colorscheme("rose-pine")
    end,
  },

  { "ibhagwan/fzf-lua", cmd = "FzfLua", opts = {} },

  -- Completion, used for [[wiki links]] and #tags
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      fuzzy = { implementation = "prefer_rust" },
      sources = { default = { "path", "buffer" } },
    },
  },

  -- Obsidian-style links, daily notes, templates, backlinks — same vault as the Obsidian app
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = false,
    dependencies = { "ibhagwan/fzf-lua", "saghen/blink.cmp" },
    opts = {
      legacy_commands = false,
      workspaces = { { name = "vault", path = vault } },
      notes_subdir = "Notes",
      new_notes_location = "notes_subdir",
      note_id_func = function(title) return title or tostring(os.time()) end,
      daily_notes = { folder = "Daily", date_format = "%Y-%m-%d", template = "daily.md" },
      templates = { folder = "Templates", date_format = "%Y-%m-%d", time_format = "%H:%M" },
      attachments = { img_folder = "Attachments" },
      completion = { blink = true, nvim_cmp = false, min_chars = 2 },
      picker = { name = "fzf-lua" },
      ui = { enable = false }, -- render-markdown.nvim does the rendering
    },
  },

  -- Renders headings, checkboxes, tables, callouts in the buffer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    opts = { file_types = { "markdown" } },
  },

  -- Centered, distraction-free writing
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = { window = { width = 84, options = { number = false } } },
  },
}, {
  install = { colorscheme = { "rose-pine" } },
  change_detection = { notify = false },
})

-- ── Keys (Space is leader) ───────────────────────────────────────
local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc }) end
map("<leader>d", "<cmd>Obsidian today<cr>", "Today's note")
map("<leader>y", "<cmd>Obsidian yesterday<cr>", "Yesterday's note")
map("<leader>n", "<cmd>Obsidian new<cr>", "New note")
map("<leader>f", "<cmd>Obsidian quick_switch<cr>", "Find note")
map("<leader>s", "<cmd>Obsidian search<cr>", "Search vault")
map("<leader>b", "<cmd>Obsidian backlinks<cr>", "Backlinks")
map("<leader>l", "<cmd>Obsidian links<cr>", "Links in this note")
map("<leader>t", "<cmd>Obsidian tags<cr>", "Browse tags")
map("<leader>T", "<cmd>Obsidian template<cr>", "Insert template")
map("<leader>x", "<cmd>Obsidian toggle_checkbox<cr>", "Toggle checkbox")
map("<leader>o", "<cmd>Obsidian open<cr>", "Open in Obsidian app")
map("<leader>i", function() vim.cmd.edit(vault .. "/Inbox.md") end, "Inbox")
map("<leader>h", function() vim.cmd.edit(vault .. "/Home.md") end, "Home")
map("<leader>z", "<cmd>ZenMode<cr>", "Zen mode")
map("<leader>ub", function()
  o.background = o.background:get() == "light" and "dark" or "light"
end, "Toggle light/dark")

-- `kv` with no file opens today's note
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 0 then
      vim.schedule(function() pcall(vim.cmd, "Obsidian today") end)
    end
  end,
})
