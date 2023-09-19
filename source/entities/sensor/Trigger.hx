package entities.sensor;

import flixel.math.FlxRect;
import flixel.FlxObject;

using echo.FlxEcho;

class Trigger extends FlxObject {
	public var eID:String;
	var once:Bool;

	public function new(id:String, zone:FlxRect, once:Bool = true) {
		super(zone.x, zone.y, zone.width, zone.height);
		eID = id;
		this.once = once;
		this.add_body({
			x: zone.x,
			y: zone.y,
			kinematic: true,
			shape: {
				type: RECT,
				width: zone.width,
				height: zone.height,
				offset_x: zone.width/2,
				offset_y: zone.height/2,
				solid: false,
			},
		});
		zone.putWeak();
	}

	public function activate() {
		if (once) {
			kill();
			// this.remove_object(true);
		}
	}

	public function resetTrigger() {

	}
}