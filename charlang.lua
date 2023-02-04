local charlang = {}

---Get number from the beginning of a string until a non number character is encountered
---@param str string
---@param offset number
---@return string
local function get_front_number(str, offset)
    local n = ""
    local pos = offset or 1
    while tonumber(str:sub(pos, pos)) ~= nil do
        n = n .. str:sub(pos, pos)
        pos = pos + 1
    end
    return n
end

---Tokenize instruction
---@param instruction string
---@return table
function charlang.tokenize(instruction)
    local tokens = {}
    local position = 1
    local column_position = 1
    local line_position = 1
    while position <= #instruction do
        local char = instruction:sub(position, position)
        if char == " " or char == "\t" then
            -- Ignore whitespaces and tabs
            position = position + 1
            column_position = column_position + 1
        elseif char == "\n" then
            -- Ignore \n
            position = position + 1
            column_position = 1
            line_position = line_position + 1
        elseif char == "[" and instruction:sub(position + 1, position + 1) == "[" then
            local local_position = 2
            local comment = {}
            while instruction:sub(position + local_position, position + local_position + 1) ~= "]]" do
                if position + local_position > #instruction then
                    error("Unclosed comment at column " .. column_position .. " line " .. line_position .. ".")
                end
                table.insert(comment, instruction:sub(position + local_position, position + local_position))
                local_position = local_position + 1
            end
            local token = {
                ["type"] = "comment",
                ["value"] = table.concat(comment),
                ["position"] = {
                    ["column"] = column_position,
                    ["line"] = line_position,
                },
            }
            table.insert(tokens, token)
            position = position + local_position + 2
        elseif tonumber(char) ~= nil then
            local repetition_str = get_front_number(instruction, position)
            local repetition = tonumber(repetition_str)
            local token = {
                ["type"] = "repetition",
                ["count"] = repetition,
                ["position"] = {
                    ["column"] = column_position,
                    ["line"] = line_position,
                },
            }
            table.insert(tokens, token)
            position = position + #repetition_str
            column_position = column_position + #repetition_str
        elseif char == "(" then
            local token = {
                ["type"] = "open_bracket",
                ["position"] = {
                    ["column"] = column_position,
                    ["line"] = line_position,
                },
            }
            table.insert(tokens, token)
            position = position + 1
            column_position = column_position + 1
        elseif char == ")" then
            local token = {
                ["type"] = "close_bracket",
                ["position"] = {
                    ["column"] = column_position,
                    ["line"] = line_position,
                },
            }
            table.insert(tokens, token)
            position = position + 1
            column_position = column_position + 1
        else
            local token_str = char
            local token = {
                ["type"] = "instruction",
                ["value"] = token_str,
                ["position"] = {
                    ["column"] = column_position,
                    ["line"] = line_position,
                },
            }
            table.insert(tokens, token)
            position = position + 1
            column_position = column_position + 1
        end
    end
    return tokens
end

---Parse tokenized instructions
---@param tokens table
---@return table
function charlang.parse(tokens)
    local result = {}
    local position = 1
    while position <= #tokens do -- Copy
        table.insert(result, tokens[position])
        position = position + 1
    end
    position = 1
    while position <= #result do -- Remove comment
        if result[position]["type"] == "comment" then
            table.remove(result, position)
        else
            position = position + 1
        end
    end
    position = 1
    while position <= #result do -- Embed repetition
        if result[position]["type"] == "repetition" then
            if position + 1 > #result then
                error("Nothing to repeat at column " ..
                    result[position]["position"]["column"] .. " line " .. result[position]["position"]["line"] .. ".")
            end
            if result[position + 1]["type"] ~= "instruction" and result[position + 1]["type"] ~= "open_bracket" then
                error("Not instruction or closure to be repeated at column " ..
                    result[position]["position"]["column"] .. " line " .. result[position]["position"]["line"] .. ".")
            end
            result[position + 1]["repetition"] = result[position]["count"]
            table.remove(result, position)
        end
        position = position + 1
    end
    local closure_stack = {}
    position = 1
    while position <= #result do -- Process closures
        if result[position]["type"] == "open_bracket" then
            table.insert(closure_stack, {
                ["type"] = "closure",
                ["repetition"] = result[position]["repetition"],
                ["list"] = {},
                ["position"] = result[position]["position"],
                ["insertion"] = position,
            })
            table.remove(result, position)
        elseif result[position]["type"] == "close_bracket" then
            if #closure_stack == 0 then
                error("Unbalanced close bracket at column " ..
                    result[position]["position"]["column"] .. " line " .. result[position]["position"]["line"] .. ".")
            end
            local closure = table.remove(closure_stack, #closure_stack)
            table.remove(result, position)
            if #closure_stack ~= 0 then
                table.insert(closure_stack[#closure_stack]["list"], closure)
            else
                table.insert(result, closure["insertion"], closure)
            end
            closure["insertion"] = nil
            -- position = position + 1
        elseif #closure_stack ~= 0 then
            local token = table.remove(result, position)
            table.insert(closure_stack[#closure_stack]["list"], token)
        else
            position = position + 1
        end
    end
    if #closure_stack ~= 0 then
        error("Unbalanced open bracket at column " ..
            closure_stack[#closure_stack]["position"]["column"] ..
            " line " .. closure_stack[#closure_stack]["position"]["line"] .. ".")
    end
    return result
end

---Add function to instruction parse nodes
---@param syntax_node_list table
---@param lookup table
---@return table
function charlang.bind_lookup(syntax_node_list, lookup)
    local position = 1
    while position <= #syntax_node_list do
        if syntax_node_list[position]["type"] == "instruction" then
            local instruction_value = syntax_node_list[position]["value"]
            local lookup_value = lookup[instruction_value]
            if not lookup_value then
                error("Lookup not found for key \"" ..
                    instruction_value ..
                    "\" for instruction at column " ..
                    syntax_node_list[position]["position"]["column"] ..
                    " line " .. syntax_node_list[position]["position"]["line"] .. ".")
            end
            if type(lookup_value) ~= "function" then
                error("Lookup value of key \"" ..
                    instruction_value ..
                    "\" is not a function for instruction at column " ..
                    syntax_node_list[position]["position"]["column"] ..
                    " line " .. syntax_node_list[position]["position"]["line"] .. ".")
            end
            syntax_node_list[position]["call"] = lookup_value
        elseif syntax_node_list[position]["type"] == "closure" then
            charlang.bind_lookup(syntax_node_list[position]["list"], lookup)
        end
        position = position + 1
    end
    return syntax_node_list
end

---Compiles bound syntax node list into one callable function
---@param bound_syntax_node_list table
---@return function
function charlang.compile(bound_syntax_node_list)
    local instructions = {}
    local position = 1
    while position <= #bound_syntax_node_list do
        if bound_syntax_node_list[position]["type"] == "instruction" then
            local instruction_call = bound_syntax_node_list[position]["call"]
            if bound_syntax_node_list[position]["repetition"] ~= nil then
                local repetition = bound_syntax_node_list[position]["repetition"]
                local _instruction_call = instruction_call
                instruction_call = function()
                    for _ = 1, repetition do
                        _instruction_call()
                    end
                end
            end
            table.insert(instructions, instruction_call)
        elseif bound_syntax_node_list[position]["type"] == "closure" then
            local closure_call = charlang.compile(bound_syntax_node_list[position]["list"])
            if bound_syntax_node_list[position]["repetition"] ~= nil then
                local repetition = bound_syntax_node_list[position]["repetition"]
                local _closure_call = closure_call
                closure_call = function()
                    for _ = 1, repetition do
                        _closure_call()
                    end
                end
            end
            table.insert(instructions, closure_call)
        end
        position = position + 1
    end
    return function()
        for instruction_position = 1, #instructions do
            instructions[instruction_position]()
        end
    end
end

function charlang.run(instruction, lookup)
    charlang.compile(charlang.bind_lookup(charlang.parse(charlang.tokenize(instruction)), lookup))()
end

return charlang
