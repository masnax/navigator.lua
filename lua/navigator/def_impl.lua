local util = require('navigator.util')
local mk_handler = util.mk_handler
local lsphelper = require('navigator.lspwrapper')
local gui = require('navigator.gui')
local M = {}
local location = require('guihua.location')
local partial = util.partial
local locations_to_items = lsphelper.locations_to_items
local log = util.log
-- dataformat should be same as reference
local function location_handler(err, locations, ctx, cfg, msg)
  if err ~= nil then
    vim.notify('ERROR: ' .. tostring(err) .. ' ' .. msg, vim.lsp.log_levels.WARN)
    return
  end
  return locations_to_items(locations, ctx)
end

local function definition_handler(bang, err, result, ctx, cfg)
  local results = location_handler(err, result, ctx, cfg, 'Definition not found')
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'ft')
  gui.new_list_view({ items = results, ft = ft, api = 'Definition' })
end

local function def_impl_handler(bang, err, results, ctxs, cfg)
  all_results = {}
  ctxs[1].bufnr = 0
  local ft = vim.api.nvim_buf_get_option(ctxs[1].bufnr, 'ft')

  results_defs = location_handler(err, results[1], ctxs[1], cfg, 'Implementation not found')
  for i, result in pairs(results_defs) do
    all_results[i] = result
  end
 
  if #results[2] > 0 then
    ctxs[2].bufnr = 0
    results_impls = location_handler(err, results[2], ctxs[2], cfg, 'Implementation not found')
    for i, result in pairs(results_impls) do
      all_results[i + #results_defs] = result
    end

    gui.new_list_view({ items = all_results, ft = ft, api = ' -- Def('..#results[1]..')/Impl('..#results[2]..')' })
  else
    gui.new_list_view({ items = all_results, ft = ft, api = 'Definition' })
  end
end

function M.def_impl_sync(bang, opts)
  local params = vim.lsp.util.make_position_params()
  log('def/impl params', params)

  if not lsphelper.check_capabilities('implementation') then
    lsphelper.call_sync({'textDocument/definition'}, params, opts, partial(definition_handler, bang))
  else
    lsphelper.call_sync_multi({'textDocument/definition', 'textDocument/implementation'}, params, opts, partial(def_impl_handler, bang))
  end

end

return M
