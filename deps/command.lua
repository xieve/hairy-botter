local function separate(str, prefix, separator)
  local commandTable = {
    args = {}
  }

  if string.find(str, '^'..prefix) then
    str = string.gsub(str, '^'..prefix, '')
    commandTable.main, str = str:match('^(%S+)%s?(.*)') -- separate main from args
    if str then
      commandTable.args = str:split(separator)
      commandTable.args.string = str
    end
    return commandTable
  end
end

return {separate = separate}
