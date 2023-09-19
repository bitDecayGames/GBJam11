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
	var lockBody:Body;

	public function new(id:String, area:FlxRect, associatedCameraZoneID:String) {
		super(id, area);
		camZoneID = associatedCameraZoneID;
	}

	override function activate() {
		super.activate();
		updateCameraLock();
	}

	function updateCameraLock() {
		// TODO: Do some stuff
		var zone = PlayState.ME.level.camLockZones.get(camZoneID);
		if (zone == null) {
			QuickLog.critical('cam trigger zone cannot find zone with ID: $camZoneID');
		}

		// TODO: Make physics bodies to lock player to screen
		if (lockBody == null) {
			lockBody = new Body({
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
		} else {
			lockBody.set_position(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
		}

		FlxG.camera.follow(null);
		FlxTween.tween(FlxG.camera.scroll, {x: zone.left, y: zone.top}, 1, {
			onUpdate: (t) -> {
				lockBody.x = FlxG.camera.scroll.x;
			},
			onComplete: (t) -> {
				FlxG.camera.setScrollBounds(zone.left, zone.right, zone.top, zone.bottom);
			}
		});
	}

	override function resetTrigger() {
		super.resetTrigger();
		resetCamera();
	}

	function resetCamera() {
		if (lockBody != null) {
			lockBody.active = false;
		}

		PlayState.ME.resetCamera();
	}
}