local turtle = require("turtle")

local turtle_lookup = {}

function turtle_lookup.create_simple_lookup()
    local lookup = {}

    local state = "normal"
    local state_number = 0
    local function_lookup = {
        u = {
            normal = turtle.up,
            dig = turtle.digUp,
            attack = turtle.attackUp,
            place = turtle.placeUp,
            drop = turtle.dropUp,
            suck = turtle.suckUp,
        },
        d = {
            normal = turtle.down,
            dig = turtle.digDown,
            attack = turtle.attackDown,
            place = turtle.placeDown,
            drop = turtle.dropDown,
            suck = turtle.suckDown,
        },
        f = {
            normal = turtle.forward,
            dig = turtle.dig,
            attack = turtle.attack,
            place = turtle.place,
            drop = turtle.drop,
            suck = turtle.suck,
        },
        b = {
            normal = turtle.back,
        },
        l = {
            normal = turtle.turnLeft,
        },
        r = {
            normal = turtle.turnRight,
        },
    }

    -- Translate function_lookup to lookup
    for instruction, state_lookup in pairs(function_lookup) do
        local instruction_function = function()
            local func = state_lookup[state]
            if func == nil then
                error("Instruction " .. instruction .. " has no state " .. state .. ".")
            end
            func()
            state = "normal"
        end
        lookup[instruction] = instruction_function
    end

    lookup["D"] = function()
        state = "dig"
    end

    lookup["A"] = function()
        state = "attack"
    end

    lookup["P"] = function()
        state = "place"
    end

    lookup["R"] = function()
        state = "drop"
    end

    lookup["S"] = function()
        state = "suck"
    end

    lookup["x"] = function()
        state_number = 0
    end

    lookup["i"] = function()
        state_number = state_number + 1
    end

    lookup["s"] = function()
        turtle.select(state_number)
    end

    return lookup
end

function turtle_lookup.create_lookup()
    local lookup = {}

    local state = "normal"
    local move_state = "normal"
    local holding_number = 0

    local stack = {}
    local function push(i) table.insert(stack, i) end

    local function pop() return table.remove(stack, #stack) end

    local move_lookup = {
        normal = {
            f = turtle.forward,
            b = turtle.back,
            u = turtle.up,
            d = turtle.down,
            l = turtle.turnLeft,
            r = turtle.turnRight,
        },
        dig = {
            f = turtle.dig,
            u = turtle.digUp,
            d = turtle.digDown,
        },
        attack = {
            f = turtle.attack,
            u = turtle.attackUp,
            d = turtle.attackDown,
        },
        place = {
            f = turtle.place,
            u = turtle.placeUp,
            d = turtle.placeDown,
        },
        drop = {
            f = turtle.drop,
            u = turtle.dropUp,
            d = turtle.dropDown,
        },
        drop_amount = {
            f = function() turtle.drop(pop()) end,
            u = function() turtle.dropUp(pop()) end,
            d = function() turtle.dropDown(pop()) end,
        },
        suck = {
            f = turtle.suck,
            u = turtle.suckUp,
            d = turtle.suckDown,
        },
        suck_amount = {
            f = function() turtle.suck(pop()) end,
            u = function() turtle.suckUp(pop()) end,
            d = function() turtle.suckDown(pop()) end,
        },
    }

    local state_lookup = {
        normal = {
            ["."] = function() end,
            m = function() state = "move" end,
            a = function() state = "arithmetic" end,
            i = function() state = "inventory" end,
        },
        move = {
            ["."] = function()
                state = "normal"
                move_state = "normal"
            end,
            -- Expanded with `for` block below
            D = function() move_state = "dig" end,
            A = function() move_state = "attack" end,
            P = function() move_state = "place" end,
            R = function() move_state = "drop" end,
            S = function() move_state = "suck" end,
            V = function() move_state = "drop_amount" end,
            U = function() move_state = "suck_amount" end,
        },
        arithmetic = {
            ["."] = function()
                state = "normal"
            end,
            r = function() holding_number = 0 end,
            i = function() holding_number = holding_number + 1 end,
            ["_"] = function() holding_number = holding_number * 10 end,
            p = function() push(holding_number) end,
            d = function() pop() end,
            e = function() print(stack[#stack]) end, -- peek
            c = function() print(#stack) end, -- stack count
        },
        inventory = {
            ["."] = function()
                state = "normal"
            end,
            s = function() turtle.select(pop()) end,
            c = function() turtle.craft() end,
            C = function() turtle.craft(pop()) end,
            f = function() turtle.refuel() end,
            F = function() turtle.refuel(pop()) end,
            t = function() turtle.transferTo(pop()) end,
            T = function() turtle.transferTo(pop(), pop()) end,
        },
    }

    -- Bake move_lookup to state_lookup
    for _, instruction in pairs({ "f", "b", "u", "d", "l", "r" }) do
        state_lookup.move[instruction] = function()
            if move_lookup[move_state] == nil then
                error("Illegal move state " .. move_state .. ".")
            end
            if move_lookup[move_state][instruction] == nil then
                error("Move state " .. move_state .. " doesn't have " .. instruction .. " instruction.")
            end
            move_lookup[move_state][instruction]()
            move_state = "normal"
        end
    end

    -- Translate state_lookup to lookup
    for _, _state_lookup in pairs(state_lookup) do
        for _instruction, _ in pairs(_state_lookup) do
            lookup[_instruction] = 0
        end
    end
    for _instruction, _ in pairs(lookup) do
        lookup[_instruction] = function()
            if state_lookup[state] == nil then
                error("Illegal state " .. state .. ".")
            end
            if state_lookup[state][_instruction] == nil then
                error("State " .. state .. " doesn't have " .. _instruction .. " instruction.")
            end
            state_lookup[state][_instruction]()
        end
    end

    return lookup
end

return turtle_lookup
