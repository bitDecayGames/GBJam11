package ui;

import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;

class Fader extends FlxBackdrop {
	public function new() {
		super();
		loadGraphic(AssetPaths.screenFade__png, true, 32, 32);
		var outFrames = [ for (i in 0...28) i];
		var inFrames = outFrames.copy();
		inFrames.reverse();

		animation.add('out', outFrames, false);
		animation.add('in', inFrames, false);
		visible = false;
		scrollFactor.set();
	}

	public function fadeIn(cb:Void->Void) {
		visible = true;
		animation.play('in', true);
		animation.finishCallback = (name) -> {
			// do these in timers to avoid weirdness with
			// the callback itself containing more fadeIn/Out
			new FlxTimer().start(0.5, (t) -> {
				visible = false;
				cb();
			});
		}
	}

	public function fadeOut(cb:Void->Void) {
		visible = true;
		animation.play('out', true);
		animation.finishCallback = (name) -> {
			new FlxTimer().start(0.5, (t) -> {
				visible = false;
				cb();
			});
		}
	}
}