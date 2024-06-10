#if cxx
import cxx.Ptr;
import cxx.Ref;
import cxx.ConstRef;
#else
import cxx.Ptr;
import cxx.Ref;
import cxx.ConstRef;
#end

import comptime.wrappers.MaybePtr;

import godotex.GD;
import godotex.GodotCallable;
import godotex.GodotRef;
import godotex.GodotTypedArray;
import godotex.GodotVariant;
import godotex.GodotNumbers.UInt8;
import godotex.GodotNumbers.UInt32;

using comptime.godot.GodotHelpers;
using comptime.godot.GodotPtr;
using comptime.godot.GodotPtrMacro;

// using funnyhands.helpers.Easing;
// using funnyhands.helpers.NullHelper;
// using funnyhands.helpers.NumberHelper;
// using funnyhands.helpers.SyntaxHelper;
