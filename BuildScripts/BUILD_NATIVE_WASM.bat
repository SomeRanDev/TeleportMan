call cd %~dp0..
call set PATH=Z:\Desktop\GithubProjects\TeleportMan\Emscripten\emsdk;D:\Python\Python311\scripts;%PATH%
call emsdk_env.bat
call cd GodotCppTemplate
call scons platform=web dlink_enabled=yes target=template_release
call cd ..