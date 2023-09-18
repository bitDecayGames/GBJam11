package entities.particle;

import states.PlayState;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import loaders.Aseprite;
import flixel.FlxSprite;

class Explosion extends FlxSprite {

	public static var pool(get, default):FlxTypedGroup<Explosion> = null;
	
	static function get_pool() {
		if (pool == null) {
			pool = new FlxTypedGroup<Explosion>();
		}

		return pool;
	}

	public static function death(count:Int, area:FlxRect, duration:Float = 1.5, cb:Void->Void = null) {
		var spacing = duration / count;
		doPoof(area);
		if (count > 1) {
			new FlxTimer().start(spacing, (t) -> {
				doPoof(area);

				if (t.loopsLeft == 0) {
					area.putWeak();
					if (cb != null) cb();
				}
			}, count - 1);
		} else {
			area.putWeak();
			if (cb != null) cb();
		}
	}

	private static function doPoof(area:FlxRect) {
		var x = FlxG.random.int(cast area.left, cast area.right);
		var y = FlxG.random.int(cast area.top, cast area.bottom);

		var poof = pool.recycle(Explosion);
		poof.spawn(x, y);
		PlayState.ME.addBasicParticle(poof);
	}
	
	private function new() {
		super(0, 0);

		
		Aseprite.loadAllAnimations(this, AssetPaths.Explosion__json);
		offset.set(width/2, height/2);
		animation.add('all', [ 0, 1, 2, 3], 10, false);
		animation.finishCallback = (name) -> {
			kill();
		};
		visible = false;
	}

	public function spawn(x:Float, y:Float) {
		// TODO SFX: single explosion (may happen many times over)
		setPosition(x, y);
		visible = true;
		animation.play('all');
	}
}