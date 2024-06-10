/**
	Generates the `register_types.cpp` and `register_types.h` files.
**/

package comptime;

#if macro

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

import cxxcompiler.Compiler as CxxCompiler;
import reflaxe.ReflectCompiler;

var exposedTypes: Array<Ref<ClassType>> = [];

/**
	Called in hxml (`--macro`)
**/
function init() {
	Context.onAfterTyping(onAfterTyping);
}

/**
	Register types when typing is complete.
**/
function onAfterTyping(moduleTypes: Array<ModuleType>) {
	final r = new RegisterTypesGenerator(Context.definedValue("godot_register_name"));
	r.generate();
}

/**
	Generates the files.
**/
class RegisterTypesGenerator {
	var compiler: CxxCompiler;

	var name: String;
	var initializeFunctionName: String;
	var uninitializeFunctionName: String;

	var includes: Array<String> = [
		'#include <gdextension_interface.h>',
		'#include <godot_cpp/core/class_db.hpp>',
		'#include <godot_cpp/core/defs.hpp>',
		'#include <godot_cpp/godot.hpp>',
		'#include "register_types.h"',
		""
	];

	var functions: Array<String>  = [
	];

	public function new(name: String) {
		compiler = cast ReflectCompiler.Compilers[0];

		this.name = name;
		initializeFunctionName = 'initialize_${name}_types';
		uninitializeFunctionName = 'uninitialize_${name}_types';
	}

	/**
		Generate da files.
	**/
	public function generate() {
		generateHeader();
		generateInitialize();
		generateUninitialize();
		generateInit();

		// Export `register_types.cpp`
		@:privateAccess compiler.setExtraFile("register_types.cpp", '${includes.join("\n")}\n\nusing namespace godot;\n\n${functions.join("\n\n")}\n');
	}

	/**
		Generate `register_types.h`.
	**/
	function generateHeader() {
		// header
		final headerContent = '#pragma once\n\nvoid ${initializeFunctionName}();\nvoid ${uninitializeFunctionName}();\n';
		@:privateAccess compiler.setExtraFile("register_types.h", headerContent);
	}

	/**
		Generate `initialize_XXX_types` function.
	**/
	function generateInitialize() {
		// initialize
		final initializeCpp = ["if(p_level != MODULE_INITIALIZATION_LEVEL_SCENE) { return; }"];
		for(type in exposedTypes) {
			final headerFilename = CxxCompiler.getFileNameFromModuleData(type.get()) + CxxCompiler.HeaderExt;
			final cppTypeString = @:privateAccess compiler.TComp.compileType(TInst(type, []), Context.currentPos(), true);
			includes.push('#include "${headerFilename}"');
			initializeCpp.push('ClassDB::register_class<${cppTypeString}>();');
		}

		functions.push('void ${initializeFunctionName}(ModuleInitializationLevel p_level) {
	${initializeCpp.join("\n\t")}
}');
	}

	/**
		Generate `uninitialize_XXX_types` function.
	**/
	function generateUninitialize() {
		// uninitialize
	functions.push('void ${uninitializeFunctionName}(ModuleInitializationLevel p_level) {
	if(p_level != MODULE_INITIALIZATION_LEVEL_SCENE) { return; }
}');
	}

	/**
		Generate `GDExtensionBool GDE_EXPORT XXX_init` function.
	**/
	function generateInit() {
		functions.push('extern "C" {
	// Initialization
	GDExtensionBool GDE_EXPORT ${name}_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization* r_initialization
	) {
		GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(${initializeFunctionName});
		init_obj.register_terminator(${uninitializeFunctionName});
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
		return init_obj.init();
	}
}');
	}
}

#end
