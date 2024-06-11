package game;

function clamp(self: Float, min: Float, max: Float): Float {
	return if(self < min) min;
	else if(self > max) max;
	else self;
}
