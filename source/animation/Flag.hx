package animation;

enum abstract Flag(Int) from Int to Int {
	var GROUNDED    = 0x1;
	var RUNNING     = 0x1 << 1;
	var MOVE_LEFT  = 0x1 << 2;
	var MOVE_RIGHT = 0x1 << 3;
	var UPPING    = 0x1 << 4;
	var DOWNING    = 0x1 << 5;
}