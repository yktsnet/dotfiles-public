local save = ya.sync(function(this, cwd, branch)
  if cx.active.current.cwd == Url(cwd) then
    this.branch = branch
    ui.render()
  end
end)

return {
  setup = function(this)
    Status:children_add(function()
      local branch = this.branch
      if not branch or branch == "" then
        return ui.Line {}
      end
      return ui.Line {
        ui.Span("  " .. branch .. " "):fg("#d0679d")
      }
    end, 1500, Status.RIGHT)

    local callback = function()
      local cwd = cx and cx.active and cx.active.current and cx.active.current.cwd
      if cwd then
        ya.emit("plugin", {
          this._id,
          ya.quote(tostring(cwd), true),
        })
      end
    end

    ps.sub("cd", callback)
    ps.sub("tab", callback)
  end,

  entry = function(_, job)
    local args = job.args or job
    local cwd = args[1]
    
    local cmd = Command("git")
      :arg({ "branch", "--show-current" })
      :cwd(cwd)
      :stdout(Command.PIPED)
    
    local output = cmd:output()
    local branch = ""
    if output and output.status.success then
      branch = output.stdout:gsub("[\r\n]", "")
    end
    
    save(cwd, branch)
  end
}
