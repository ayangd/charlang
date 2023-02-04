if _G.component then -- OpenComputers
    -- Running in OpenComputers
elseif _G.peripheral then -- ComputerCraft
    local function save_file(url, file_name)
        local response = http.get(url)
        local content = response.readAll()
        response.close()

        local file = fs.open(file_name, "w")
        file.write(content)
        file.close()
    end

    save_file(
        "https://raw.githubusercontent.com/ayangd/charlang/main/charlang.lua",
        "charlang.lua"
    )

    if _G.turtle then
        fs.makeDir("lookups")
        save_file(
            "https://raw.githubusercontent.com/ayangd/charlang/main/lookups/turtle_lookup.lua",
            "lookups/turtle_lookup.lua"
        )
        print("Installed for ComputerCraft Turtle.")
    else
        print("Installed for ComputerCraft Computer.")
    end
else
    -- Running in unknown environment
end
