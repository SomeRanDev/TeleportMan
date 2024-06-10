call cd %~dp0..
call set PATH=D:\Python\Python311\scripts;%PATH%
call cd GodotCppTemplate
call scons target=template_release
call cd ..