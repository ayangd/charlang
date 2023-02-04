# charlang

A simple character interpreter that calls function inside a table, for LUA.

## What does it do?

Simplify a ton of function calls with compact string, especially turtle movement in ComputerCraft or robot movement in OpenComputers.

## How to get the library?

In ComputerCraft, run:
```sh
wget run https://raw.githubusercontent.com/ayangd/charlang/main/setup.lua
```

It will put the library and lookup folder in the current directory you're in.

## How to use it?

The `charlang.lua` file has some functions exported, as shown by the table below:

| Function Name | Description                                         |
|---------------|-----------------------------------------------------|
| tokenize      | Convert string to table list of tokens              |
| parse         | Convert long token to nested table                  |
| bind_lookup   | Adds function call to the nested table              |
| compile       | Converts the nested table to a single function call |
| run           | All above functions combined                        |

Example:

```lua
local charlang = require("charlang")

local lookup = {
    a = function() print("a") end,
    b = function() print("b") end,
}

local instruction = [=[
    [[ This is a comment, will be ignored by the interpreter    ]]
    [[ new line (\n), spaces and tabs (\t) will also be ignored ]]
    aabb       [[ Prints "a" 2 times and "b" 2 times            ]]
    2a2b       [[ Same as above                                 ]]
    2(ab)      [[ Prints "a", "b", "a", "b"                     ]]
    3(2ab)     [[ Prints "a", "a", "b", repeated 3 times        ]]
    4(3a2(ab)) [[ Nested closures are also supported.           ]]
]=]

charlang.run(instruction, lookup)
-- same as
-- charlang.compile(
--     charlang.bind_lookup(
--         charlang.parse(
--             charlang.tokenize(instruction)
--         ),
--         lookup
--     )
-- )()
```

This library provides lookups for certain application, like turtles. In the `lookups` folder, you will find:
1. [`turtle_lookup.lua`](lookups/turtle_lookup.md)
