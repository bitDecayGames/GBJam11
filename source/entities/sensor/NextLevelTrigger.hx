package entities.sensor;

import echo.Body;
import states.PlayState;
import flixel.math.FlxRect;

using echo.FlxEcho;

class NextLevelTrigger extends Trigger {
	var nextLevelID:String;

	public function new(id:String, area:FlxRect, nextLevelID:String) {
		super(id, area, false);
		this.nextLevelID = nextLevelID;
	}

	override function activate() {
		super.activate();
		PlayState.ME.transitionToLevel(nextLevelID);
	}
}