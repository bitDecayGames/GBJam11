package entities;

import loaders.AsepriteMacros;
import loaders.Aseprite;
import flixel.FlxSprite;

class Shuttle extends FlxSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/Shuttle.json");

	public var openCB:Void->Void = null;
	public var closeCB:Void->Void = null;

	public function new() {
		super();
		Aseprite.loadAllAnimations(this, AssetPaths.Shuttle__json);
		animation.play(anims.Approach);
		animation.finishCallback = finished;
	}

	public function doLanding() {
		animation.play(anims.Landing);
	}

	public function takeOff() {
		animation.play(anims.Takeoff);
	}

	public function openDoor(cb:Void->Void) {
		animation.play(anims.DoorOpen);
		openCB = cb;
	}

	public function closeDoor(cb:Void->Void) {
		animation.play(anims.DoorClose);
		closeCB = cb;
	}

	function finished(name:String) {
		if (name == anims.Landing) {
			animation.play(anims.ClosedHover);
		} else if (name == anims.DoorOpen) {
			animation.play(anims.OpenHover);
			if (openCB != null) openCB();
		} else if (name == anims.DoorClose) {
			animation.play(anims.ClosedHover);
			if (closeCB != null) closeCB();
		}
	}
}