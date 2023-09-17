package entities.projectile;

import echo.data.Data.CollisionData;
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
		loadGraphic(AssetPaths.bullet__png);
	}

	override public function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			drag_x: 0,
			shapes: [
				{
					type:CIRCLE,
					radius: 3,
				},
			],
			kinematic: true,
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (x + width < FlxG.camera.viewLeft || x > FlxG.camera.viewRight || y + height < 0 || y > FlxG.camera.viewBottom) {
			kill();
			body.active = false;
			body.velocity.set(0,0);
		}
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		kill();
	}

	override function destroy() {
		super.destroy();
		this.remove_object(true);
		body = null;
	}
}