# svelte-gmod
[[Latest](https://github.com/novacbn/svelte-gmod/releases/latest) &bullet; [Releases](https://github.com/novacbn/svelte-gmod/releases)]
The disappearing UI framework, now for Garry's Mod

---

This is the Svelte framework integrated with [Garry's Mod by Facepunch Studios](https://gmod.facepunch.com), if you're looking for Svelte's official repository or more information about the framework, check it here:

* [svelte](https://github.com/sveltejs/svelte)

## Compiler
**NOTE**: As of this moment, the compiler only runs in the ``dev`` branch of Garry's Mod running on Chromium! Normal Garry's Mod will not work!

**NOTE**: While you can design your workflow around using this svelte-gmod to compiler your components, if your need anything more advanced check out the rest of the Svelte ecosystem!

### How to use
Simply ``include`` the ``compiler.lua`` Lua file and call the API. Or alternatively, run file and use the ``svelte_export`` console command.

#### API
* ``void compile(string source, function callback)`` - Submits the script 'source' to the Svelte compiler
---
```lua
--[[
    Compiler API:
        
]]

local compiler = include("compiler.lua")                        -- Include the compiler
compiler.compile([[<h1>{{text}}</h1>]], function (compiled)     -- Compile a Svelte component
    print(compiled)
end)
```

#### Console Command
* ``svelte_export <source file> <export name>`` - Compiles source file to exported name in the ``DATA`` folder
---
```c++
    // Compiles 'data/mycomponent.txt' to 'data/mycomponent.export.txt'
    svelte_export data/mycomponent.txt mycomponent.export
```

### Rendering
**NOTE**: This section will only cover the Lua side of this framework. If you wish learn how to use Svelte, use Svelte's official [Guide](https://svelte.technology/guide)!

#### How to use
Simply ``include`` the ``svelte.lua`` Lua file and call the API detailed below. This guide assumes you're famailar with VGUI Panels.

#### API
* ``Panel create(string component, table components?, Panel parent?, table Panel?)`` - Create a new VGUI Panel, using 'component' as the main panel, and 'components' as imported components. Using the keys for the components as the ids assigned to Svelte.
* ``table extend(table Panel)`` Extends SveltePanel with 'Panel' for encapsulating logic.
---
```lua
    -- Include the Svelte framework
    local svelte = include("svelte.lua")

    -- Load the compiled components
    local component1 = file.Read(...)
    local component2 = file.Read(...)

    -- Create a new VGUI Panel with 'component1' as the main component
    local panel = svelte.create(component1, {
        ComponentTwo = component2               -- Expose 'component2' as 'ComponentTwo' to Svelte
    })

    -- Extend 'SveltePanel' with custom hooks
    local MyPanel = svelte.extend({
        onCreate = function (self)          -- Lifecycle hook when component is created
            print("Component created!")
        end,

        onDestroy = function (self)
            print("Component destroyed!")   -- Lifecycle hook when component is about to be destroyed
        end,

        onThink = function (self)
            print("Component is thinking!") -- Logic hook called every frame
        end
    })

    -- Create a new VGUI Panel using your extension
    local panel = svelte.create(component1, {
        ComponentTwo = component2
    }, nil, MyPanel)
```

#### SveltePanel
* ``void dispatch(string name, table data?, function callback?)`` - Dispatches event 'name' to the main Svelte component
* ``void get(string name, function callback)`` - Retrieves variable 'name' from the main Svelte component
* ``function observe(string name)`` - Starts replication of variable 'name' allowing access via SveltePanel.vars[name]
* ``function on(string name, function callback)`` - Calls function 'callback' whenever event 'name' is fired
* ``void set(table data, function callback?)`` - Sets using keys in table 'data' as variable names, it sets their pair values on the main Svelte component
---
```lua
    -- Create a new panel
    local panel = svelte.create(...)

    -- Retrieve a variable from Svelte
    panel:get("a", function (value)
        print("panel.a", value)
    end)

    -- Tell Svelte to set variable 'a' to "test"
    panel:set({
        a = "test"
    })

    -- Observe all changes for variable 'a'
    local release = panel:observe("a")
    print(panel.vars.a)                 -- Prints "test"
    panel.vars.a = "finished"           -- Changes variable 'a' from "test" to "finished"
    release()                           -- Releases the variable observer

    -- Dispatch an event to Svelte
    panel:dispatch("myevent", {
        x = "hello"
    })

    -- Listen for 'myevent' event from Svelte
    local release = panel:on("myevent", function (data)
        print("myevent.x", data.x)
    end)

    release() -- Releases the event listener
```

### Compiling the framework
If you want to compile from source, simply call ``bin/build`` from a terminal. Although to start the process, you need these requirements:
* [luvit](https://luvit.io/) - ``luvit`` must be searchable in ``PATH``
* [moonscript](http://moonscript.org) - ``moonc`` must be searchable in ``PATH``
* [luamin](https://github.com/mathiasbynens/luamin) - ``luamin`` must be searchable in ``PATH``
* [minify](github.com/coderaiser/minify) - ``minify`` must be searchable in ``PATH``

### License

[MIT](LICENSE)