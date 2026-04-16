-- Example configuration for nvim-patch-plugin

-- With lazy.nvim
return {
  "nvim-patch-plugin/nvim-patch-plugin",
  config = function()
    require("nvim-patch-plugin").setup({
      -- Optional configuration
      -- default_patch_level = 1,  -- Default patch level to try first
      -- auto_diffsplit = true,     -- Automatically open diffsplit
    })
  end
}
