package entities.sensor;

import echo.Body;
import flixel.tweens.FlxTween;
import states.PlayState;
import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.FlxObject;

using echo.FlxEcho;

class CameraTrigger extends Trigger {
	var camZoneID:String;

	public function new(area:FlxRect, associatedCameraZoneID:String) {
		super(area, updateCameraLock);
		camZoneID = associatedCameraZoneID;
	}

	function updateCameraLock() {
		// TODO: Do some stuff
		var zone = PlayState.ME.level.camLockZones.get(camZoneID);
		if (zone == null) {
			QuickLog.critical('cam trigger zone cannot find zone with ID: $camZoneID');
		}

		// TODO: Make physics bodies to lock player to screen
		var lockBody = new Body({
			x: FlxG.camera.scroll.x,
			y: FlxG.camera.scroll.y,
			shapes: [
				{
					type:RECT,
					width: 16,
					height: FlxG.camera.height,
					offset_x: -8,
					offset_y: FlxG.camera.height/2
				},
			],
			kinematic: true,
		});
		PlayState.ME.addTerrain(lockBody);

		FlxG.camera.follow(null);
		FlxTween.tween(FlxG.camera.scroll, {x: zone.left, y: zone.top}, 1, {
			onUpdate: (t) -> {
				lockBody.x = FlxG.camera.scroll.x;
			},
			onComplete: (t) -> {

			}
		});
	}
}