-- DAP Test Utilities - Common debugging functionality
-- Provides debug adapter testing, session lifecycle management, and breakpoint utilities

local framework = dofile("tests/lib/framework.lua")
local M = {}

---Check if DAP is available and configured
---@param adapter_name string Name of DAP adapter to check
---@param restore_cwd function Function to restore working directory on error
---@return table DAP module
function M.ensure_dap_available(adapter_name, restore_cwd)
  local ok_dap, dap = pcall(require, "dap")
  if not ok_dap then
    if restore_cwd then restore_cwd() end
    framework.die("require('dap') failed — nvim-dap not available.")
  end

  if not dap.adapters[adapter_name] then
    if restore_cwd then restore_cwd() end
    framework.die("DAP adapter '" .. adapter_name .. "' not configured.")
  end

  return dap
end

---Setup DAP event listeners for test session
---@param test_id string Unique identifier for test session
---@return table Event state tracking object
function M.setup_debug_listeners(test_id)
  local dap = require("dap")
  local seen = { initialized = false, stopped = false, terminated = false }
  local reason
  local session_id = nil

  -- Clear any existing listeners for this test_id
  dap.listeners.after.event_initialized[test_id] = nil
  dap.listeners.after.event_stopped[test_id] = nil
  dap.listeners.after.event_terminated[test_id] = nil
  dap.listeners.after.event_exited[test_id] = nil

  dap.listeners.after.event_initialized[test_id] = function(session)
    session_id = session and session.id
    seen.initialized = true
  end

  dap.listeners.after.event_stopped[test_id] = function(session, body)
    -- Only count stops for our specific session
    if session and session.id == session_id then
      seen.stopped = true
      reason = body and body.reason or reason
    end
  end

  dap.listeners.after.event_terminated[test_id] = function(session)
    if session and session.id == session_id then
      seen.terminated = true
    end
  end

  dap.listeners.after.event_exited[test_id] = dap.listeners.after.event_terminated[test_id]

  return {
    seen = seen,
    get_reason = function() return reason end,
    get_session_id = function() return session_id end,
    reset = function()
      seen = { initialized = false, stopped = false, terminated = false }
      reason = nil
      session_id = nil
    end
  }
end

---Test debug session with configuration
---@param config table Debug configuration
---@param breakpoint_info table Breakpoint information {file_path, line_number}
---@param timeout number Timeout in milliseconds
---@param state table Event state tracking object
---@param restore_cwd function Function to restore working directory on error
---@return boolean Success status
function M.test_debug_session(config, breakpoint_info, timeout, state, restore_cwd)
  local dap = require("dap")

  -- Reset state
  dap.clear_breakpoints()
  state.reset()

  -- Open file and set breakpoint
  vim.cmd("edit! " .. vim.fn.fnameescape(breakpoint_info.file_path))
  vim.api.nvim_win_set_cursor(0, { breakpoint_info.line_number, 0 })
  dap.set_breakpoint()

  -- Start debugging
  dap.run(config)

  -- Wait for session to start
  local ok_session = vim.wait(timeout, function() return dap.session() ~= nil end, 100)
  if not ok_session then
    if restore_cwd then restore_cwd() end
    framework.die("DAP session did not start for " .. (config.name or "debug config"))
  end

  -- Wait for initialization
  vim.wait(2000, function() return state.seen.initialized end, 100)

  -- Continue and wait for breakpoint
  pcall(dap.continue)
  local start_time = vim.uv.hrtime()
  local breakpoint_hit = vim.wait(timeout, function() return state.seen.stopped end, 200)
  local actual_wait_time = (vim.uv.hrtime() - start_time) / 1000000 -- Convert to milliseconds
  
  if not breakpoint_hit then
    pcall(dap.terminate)
    if restore_cwd then restore_cwd() end
    framework.die("Debugger did not stop (breakpoint not hit) for " .. (config.name or "debug config") .. 
                 " - waited " .. math.floor(actual_wait_time) .. "ms (timeout: " .. timeout .. "ms)")
  else
    print("⏱️  Breakpoint hit after " .. math.floor(actual_wait_time) .. "ms (timeout: " .. timeout .. "ms)")
  end

  local reason = state.get_reason()
  if reason and reason ~= "breakpoint" and reason ~= "step" then
    pcall(dap.terminate)
    if restore_cwd then restore_cwd() end
    framework.die("Debugger stopped for unexpected reason: " .. tostring(reason))
  end

  -- Terminate the session
  pcall(dap.terminate)
  vim.wait(2000, function() return state.seen.terminated end, 100)

  return true
end

---Test detection functionality
---@param test_files table List of test files with paths and descriptions
---@return table Test results
function M.test_detection(test_files)
  local results = {}

  -- Test DebugDwim functionality with different files
  for _, file_info in ipairs(test_files) do
    -- Test file type detection
    if file_info.is_test and dwim.is_test_file then
      if dwim.is_test_file(file_info.path) then
        framework.print_success("DebugDwim correctly identifies test file")
        results[file_info.name .. "_detection"] = true
      else
        framework.print_warning("DebugDwim failed to identify test file")
        results[file_info.name .. "_detection"] = false
      end
    end

    -- Test function detection if applicable
    if file_info.test_cursor_line and dwim.is_test_method then
      vim.api.nvim_win_set_cursor(0, { file_info.test_cursor_line, 0 })
      local in_test, test_name = dwim.is_test_method(file_info.path, file_info.test_cursor_line)
      if in_test then
        framework.print_success("DebugDwim detected test function: " .. (test_name or "unknown"))
        results[file_info.name .. "_function_detection"] = true
      else
        framework.print_success("DebugDwim function detection completed (may be normal)")
        results[file_info.name .. "_function_detection"] = false
      end
    end
  end
  return results
end

---Test DebugDwim command functionality
---@param test_files table List of test files with paths and descriptions
---@return table Test results
function M.test_debug_dwim(test_files)
  local results = {}
  local dap = require("dap")

  -- Clear all breakpoints at the start
  dap.clear_breakpoints()

  -- Test DebugDwim command exists
  local commands = vim.api.nvim_get_commands({})
  if commands.DebugDwim then
    framework.print_success("DebugDwim command is available")
    results.command_available = true
  else
    framework.print_warning("DebugDwim command not found")
    results.command_available = false
    return results
  end

  -- Test DebugDwim functionality with different files
  for _, file_info in ipairs(test_files) do
    framework.print_section("DebugDwim with " .. file_info.description)
    
    -- Ensure clean buffer state before each test
    vim.cmd("enew")  -- Create new empty buffer
    vim.cmd("edit! " .. vim.fn.fnameescape(file_info.path))  -- Force reload file
    vim.cmd("redraw!")  -- Force redraw to ensure buffer is ready
    
    -- Verify buffer is properly loaded
    local line_count = vim.api.nvim_buf_line_count(0)
    print("📄 Buffer loaded with " .. line_count .. " lines, targeting line " .. file_info.breakpoint_line)
    
    if file_info.breakpoint_line > line_count then
      print("🔍 Breakpoint line " .. file_info.breakpoint_line .. " exceeds buffer length " .. line_count)
      print("📄 Current buffer content:")
      local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      for i, line in ipairs(buffer_lines) do
        print(string.format("%3d: %s", i, line))
      end
      framework.die("Target breakpoint line " .. file_info.breakpoint_line .. " exceeds buffer length " .. line_count .. " for " .. file_info.description)
    end

    -- Clear breakpoints before each test
    dap.clear_breakpoints()

    local ok, err = pcall(function()
      local dap = require("dap")
      
      -- Clean up any existing session first
      if dap.session() then
        local old_session = dap.session()
        print("🧹 Cleaning up existing session (ID: " .. (old_session.id or "unknown") .. ") before starting new test")
        local hydra = require('config.dap.hydra')
        pcall(hydra.dap_close_all)  -- This closes DAP session, UI, and all related buffers
        vim.wait(1000, function() return dap.session() == nil end, 100)
        if dap.session() then
          print("⚠️  Warning: Previous session still active after cleanup attempt")
        end
      end
      
      -- Setup debug listeners for this test
      local state = M.setup_debug_listeners("dwim-test-" .. file_info.name)

      -- Set breakpoint and start debugging
      vim.api.nvim_win_set_cursor(0, { file_info.breakpoint_line, 0 })
      dap.set_breakpoint()
      
      -- Debug: Print intended breakpoint location
      print("🎯 Setting breakpoint at: " .. file_info.path .. ":" .. file_info.breakpoint_line)
      
      -- Wait for breakpoint to be registered
      local breakpoint_registered = vim.wait(5000, function()
        local breakpoints = dap.list_breakpoints()
        for _, bp_list in pairs(breakpoints or {}) do
          for _, bp in ipairs(bp_list or {}) do
            if bp.line == file_info.breakpoint_line then
              return true
            end
          end
        end
        return false
      end, 100)
      
      -- Debug: Print all available breakpoints
      local breakpoints = dap.list_breakpoints()
      local bp_info = {}
      for file_path, bp_list in pairs(breakpoints or {}) do
        for _, bp in ipairs(bp_list or {}) do
          table.insert(bp_info, file_path .. ":" .. bp.line)
        end
      end
      print("🔍 All breakpoints: " .. (next(bp_info) and table.concat(bp_info, ", ") or "none"))
      
      if not breakpoint_registered then
        print("⚠️  Warning: Breakpoint may not be registered at line " .. file_info.breakpoint_line)
      else
        print("✅ Breakpoint confirmed at line " .. file_info.breakpoint_line)
      end
      
      print("🚀 Starting debug session for " .. file_info.description .. " at line " .. file_info.breakpoint_line)
      local session_start_time = vim.uv.hrtime()
      vim.cmd("DebugDwim")

      -- Wait for session to start
      local dap_timeout = tonumber(vim.env.DAP_WAIT_MS) or 60000
      local session_wait_start = vim.uv.hrtime()
      local ok_session = vim.wait(dap_timeout, function() return dap.session() ~= nil end, 100)
      local session_wait_time = (vim.uv.hrtime() - session_wait_start) / 1000000
      
      if not ok_session then
        print("❌ DAP session failed to start after " .. math.floor(session_wait_time) .. "ms (timeout: " .. dap_timeout .. "ms)")
        framework.die("DAP session did not start for " .. file_info.description)
      end
      
      local session = dap.session()
      local session_id = session and session.id or "unknown"
      print("✅ DAP session started (ID: " .. session_id .. ") after " .. math.floor(session_wait_time) .. "ms")

      -- Wait for initialization
      vim.wait(2000, function() return state.seen.initialized end, 100)

      -- Continue and wait for breakpoint
      pcall(dap.continue)
      
      -- Check if breakpoint was already hit before we start waiting
      local already_stopped = state.seen.stopped
      if already_stopped then
        print("🚀 Breakpoint already hit before wait started for " .. file_info.description)
      end
      
      local start_time = vim.uv.hrtime()
      local breakpoint_hit = vim.wait(dap_timeout, function() return state.seen.stopped end, 200)
      local actual_wait_time = (vim.uv.hrtime() - start_time) / 1000000 -- Convert to milliseconds
      
      -- Report detailed breakpoint status
      if breakpoint_hit then
        if already_stopped then
          print("⏱️  Breakpoint was already hit (0ms wait) for " .. file_info.description)
        else
          print("⏱️  Breakpoint hit after " .. math.floor(actual_wait_time) .. "ms for " .. file_info.description)
        end
      else
        print("⏰ Breakpoint NOT hit after " .. math.floor(actual_wait_time) .. "ms (timeout: " .. dap_timeout .. "ms)")
      end

      -- Check if session is still active - if it terminated, breakpoint wasn't hit
      local current_session = dap.session()
      if not current_session then
        print("💀 Debug session terminated unexpectedly (session ID was: " .. session_id .. ")")
        framework.die("Debug session terminated without hitting breakpoint for " .. file_info.description)
      end

      if not breakpoint_hit then
        -- Show current breakpoints and session state for debugging
        local breakpoints = dap.list_breakpoints()
        print("🔍 Debug info - Active breakpoints: " .. vim.inspect(breakpoints))
        print("🔍 Debug info - Session state: " .. (current_session and "active" or "none"))
        print("🔍 Debug info - Expected file: " .. file_info.path .. " line " .. file_info.breakpoint_line)
        
        pcall(dap.terminate)
        pcall(dap.disconnect)
        framework.die("Debugger did not stop (breakpoint not hit) for " .. file_info.description .. 
                     " - waited " .. math.floor(actual_wait_time) .. "ms (timeout: " .. dap_timeout .. "ms)")
      end

      local reason = state.get_reason()

      -- Check current position when stopped
      current_session = dap.session()
      if current_session then
        -- Give a moment for frame info to be populated if not immediately available
        if not current_session.current_frame then
          vim.wait(500, function() return current_session.current_frame ~= nil end, 50)
        end
      end

      if current_session and current_session.current_frame then
        local frame = current_session.current_frame
        -- Skip strict line validation if requested by the caller
        local skip_line_validation = file_info.skip_line_validation

        if not skip_line_validation and frame.line ~= file_info.breakpoint_line then
          pcall(dap.terminate)
          framework.die("Debugger stopped at line " .. tostring(frame.line) ..
                       " but expected line " .. file_info.breakpoint_line .. " for " .. file_info.description)
        elseif skip_line_validation then
          framework.print_success("Breakpoint hit at line " .. tostring(frame.line) ..
                                 " (expected " .. file_info.breakpoint_line .. ", skipping line validation)")
        end
      else
        pcall(dap.terminate)
        framework.die("Debugger stopped but no frame information available - breakpoint likely not hit for " .. file_info.description)
      end

      if not reason or (reason ~= "breakpoint" and reason ~= "step") then
        pcall(dap.terminate)
        framework.die("Debugger stopped for unexpected reason: " .. tostring(reason) .. " for " .. file_info.description)
      end

      -- Proper session cleanup
      print("🛑 Terminating debug session (ID: " .. session_id .. ") for " .. file_info.description)
      local cleanup_start = vim.uv.hrtime()
      
      local hydra = require('config.dap.hydra')
      pcall(hydra.dap_close_all)  -- This closes DAP session, UI, and all related buffers
      local terminated = vim.wait(2000, function() return dap.session() == nil end, 100)
      
      if not terminated then
        print("⚠️  Session did not terminate gracefully after dap_close_all")
        pcall(dap.terminate)
        pcall(dap.disconnect)
        vim.wait(1000, function() return dap.session() == nil end, 100)
      end
      
      local cleanup_time = (vim.uv.hrtime() - cleanup_start) / 1000000
      print("✅ Session cleanup completed in " .. math.floor(cleanup_time) .. "ms")
      
      -- Verify session is fully cleaned up
      if dap.session() then
        print("⚠️  Warning: Session still active after cleanup (ID: " .. (dap.session().id or "unknown") .. ")")
      else
        print("✅ Session fully terminated")
      end

      framework.print_success("DebugDwim debugging successful (breakpoint hit) for " .. file_info.description)
      results[file_info.name .. "_debug_success"] = true
    end)

    if not ok then
      -- Ensure cleanup even on failure
      if dap.session() then
        local failed_session = dap.session()
        print("🧹 Cleaning up failed session (ID: " .. (failed_session.id or "unknown") .. ")")
        local hydra = require('config.dap.hydra')
        pcall(hydra.dap_close_all)  -- This closes DAP session, UI, and all related buffers
        vim.wait(1000, function() return dap.session() == nil end, 100)
      end
      framework.die("DebugDwim test failed for " .. file_info.description .. ": " .. tostring(err))
    else
      results[file_info.name .. "_success"] = true
    end
  end

  return results
end

---Test DAP configurations are loaded
---@param language string Language name
---@return table Configuration info
function M.test_dap_configurations(language)
  local dap = require("dap")
  local configs = dap.configurations[language] or {}

  if #configs > 0 then
    framework.print_success(language .. " DAP configurations loaded (" .. #configs .. " configs)")
    for i, config in ipairs(configs) do
      print("   " .. i .. ". " .. (config.name or "unnamed"))
    end
  else
    framework.print_warning("No " .. language .. " DAP configurations found")
  end

  return {
    count = #configs,
    configs = configs
  }
end

return M
