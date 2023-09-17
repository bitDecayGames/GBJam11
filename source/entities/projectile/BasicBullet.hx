package entities.projectile;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.math.FlxPoint;
import bitdecay.flixel.spacial.Cardinal;
import echo.Body;
import flixel.util.FlxPool;

using echo.FlxEcho;

class BasicBullet extends EchoSprite {

	public static var pool(get, default):FlxTypedGroup<BasicBullet> = null;
	
	static function get_pool() {
		if (pool == null) {
			pool = new FlxTypedGroup<BasicBullet>();
		}

		return pool;
	}

	private function new() {
		super(0, 0);
	}

	@:access(echo.FlxEcho)
	public function spawn(x:Float, y:Float, velocity:FlxPoint) {
		if (body == null) {
			trace('making new body for sprite');
			body = makeBody();
		}

		body.set_position(x, y);
		body.velocity.set(velocity.x, velocity.y);
		body.active = true;

		body.object = this;

		body.update_body_object();

		velocity.putWeak();
	}

	override public function configSprite() {
		makeGraphic(6, 6, Constants.LIGHT);
	}

	override public function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			drag_x: 0,
			shapes: [
				{
					type:RECT,
					width: 6,
					height: 6,
				},
			],
			kinematic: true,
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (x + width < FlxG.camera.viewLeft || x > FlxG.camera.viewRight || y + height < 0 || y > FlxG.camera.viewBottom) {
			trace('bullet off-screen. cleaning');
			kill();
			body.active = false;
		}
	}

	override function destroy() {
		super.destroy();
		this.remove_object(true);
		body = null;
	}
}