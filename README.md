# StudioMacros
wip ui keyboard shortcuts plugin

https://github.com/user-attachments/assets/b850abe1-c4c5-4035-aed8-b6a23bbfbbf4

## how to install
either download the plugin file from the [latest
release](https://github.com/unrooot/StudioMacros/releases) and copy it to your
studio plugins folder, or build it from source with npm and rojo.

## how to build from source
1. clone the repo and cd into the directory
```
git clone https://github.com/unrooot/studiomacros && cd studiomacros
```

2. install dependencies with npm (node.js required)
```
npm i
```

3. build the plugin with rojo
```
rojo build --plugin StudioMacros.rbxm
```

---

## how to use
in Roblox Studio, go to File -> Advanced -> Customize Shortcuts and bind
"StudioMacros Commands" to a key (e.g. `Shift+Space`), then select an instance
and press the shortcut to open the command palette.

### keyboard shortcuts
* `Up` and `Down` to navigate the command palette (or `Ctrl+J` and `Ctrl+K` on macOS)
* `Enter` to run the selected command
* `Shift+Enter` to run the selected command without closing the command palette
* `Esc` to close the command palette (or clear the search)
* `Ctrl+D` to toggle descriptions on the macros in the list
* `Shift+Escape` to release focus from the command palette
* `Tab` and `Shift+Tab` to cycle through custom result inputs (currently only implemented in the color picker)

### a note on input:
roblox studio plugins currently do not have a good way of handling input and
focus (see [here](https://devforum.roblox.com/t/plugins-need-a-way-to-listen-to-app-input/479597))
so the plugin will not work if the viewport in studio is not focused. this
means if you select an instance in the explorer, and try to use the command
palette, despite the UI opening and the textbox being focused, you won't be
able to type. you can work around this by right clicking the viewport to move
your camera without deselecting the current instance before opening the command
palette.

---

## how to add new macros
you will need to build the plugin to add new macros. create a new file in any
folder inside of `src/StudioMacros/macros` with the following structure:

```lua
return {
	Name = "Macro Name",
	Description = "A description of the macro",

	-- optional values, when provided the macro will use the custom results to
	-- select arguments which will be passed to the macro. see:
	-- ChangeBackgroundColor.luau or ChangeFont.luau for an example
	CustomResults = "Color" | "Font" | "FontStyle",
	TargetProperty = "BackgroundColor3",

	-- optional predicate function that should return true if the macro should
	-- work + be available for the given instance
	Predicate = function(instance)
		return instance:IsA("BasePart")
	end;

	Macro = function(instance)
		instance.Position = Vector3.zero
		instance.Size = Vector3.one

		-- optionally return an instance (or table of instances) that will be
		-- selected after the macro is run
		return instance
	end;
}
```

### creating groups
to create a group of macros, create a new folder inside of the macros folder,
and create a file called `GroupData.luau` with the following structure:

```lua
return {
	Name = "Group Name";
	Icon = "rbxassetid://1234567";
}
```

if you're actively creating and testing new macros, you can run `rojo build`
with the `--watch` flag to automatically rebuild the plugin when you save a
file (this requires "Plugin Debugging Enabled" setting to be enabled in
studio).