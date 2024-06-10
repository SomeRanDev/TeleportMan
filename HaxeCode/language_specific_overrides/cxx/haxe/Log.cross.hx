package haxe;

class Log {
	public static function formatOutput(v: String, infos: PosInfos): String {
		var str = v;
		if (infos == null)
			return str;
		var pstr = infos.fileName + ":" + infos.lineNumber;
		if (infos.customParams != null)
			for (v in infos.customParams)
				str += ", " + Std.string(v);
		return pstr + ": " + str;
	}

	public static dynamic function trace(v: godotex.GodotVariant, ?infos:PosInfos):Void {
		var str = formatOutput(v.toString(), infos);
		godot.Godot.print(str);
	}
}
