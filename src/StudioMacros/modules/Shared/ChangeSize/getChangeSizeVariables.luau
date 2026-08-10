return function(absoluteSize: Vector2, size: UDim2): { [string]: number }
	return {
		x = absoluteSize.X;
		xo = size.X.Offset;
		xs = size.X.Scale;
		y = absoluteSize.Y;
		yo = size.Y.Offset;
		ys = size.Y.Scale;
	}
end
