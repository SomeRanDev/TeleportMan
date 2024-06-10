call cd %~dp0..
call set PATH=D:\Python\Python311\scripts;%PATH%
call cd GodotCppTemplate
call scons target=template_debug debug_symbols=yes
call cd ..
