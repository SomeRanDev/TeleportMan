# Teleport Man

He be porting.

## How to Compile Shit

1) Install [Emscripten](https://emscripten.org/). See [Godot compiling for web](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html). I recommend placing it in a folder named Emscripten in the repo. That's what I do.

2) Install [Scons](https://scons.org/pages/download.html).

3) Generate `extension_api.json` in HaxeCode/godot_bindings for your Godot version.

4) Install my [Godot API Generator haxelib](https://github.com/SomeRanDev/Haxe-GodotBindingsGenerator).

5) Run the `GENERATE_BINDINGS.bat` file in HaxeCode/godot_bindings.

6) Build the native libraries using the `.bat` files in BuildScripts/. You will need to edit the `.bat` files so the PATH is set to your Emscripten and Scons installation. Or just remove the `set PATH=...` lines entirely if they're already on your PATH.
