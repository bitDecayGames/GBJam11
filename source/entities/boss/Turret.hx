package entities.boss;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.FlxG;
import echo.math.Vector2;
import states.PlayState;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import entities.projectile.BasicBullet;
import echo.data.Data.CollisionData;
import loaders.AsepriteMacros;
import loaders.Aseprite;
import echo.Body;

using echo.FlxEcho;

class Turret extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/RotatingTurret.json");

	var damageTimer:FlxTimer = new FlxTimer();
	var damageBlinkDuration = 0.2;

	var maxAngle = 180 + 45;
	var minAngle = 180 - 45;
	
	public function new(x:Float, y:Float) {
		super(x, y);
	}

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.RotatingTurret__json);
		// animation.play(anims);
		x += width/2;
		y += height/2;

		animation.add('pivot', [0, 1, 2, 3, 4]);
	}


	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:CIRCLE,
					radius: 7,
				},
			],
			kinematic: true,
		});
	}

	var pVec = new Vector2(0, 0);
	var bVec = new Vector2(0, 0);

	var baseFrame = 0;
	var frameMod = 0;

	var bulletTimer = 1.0;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (body.active) {
			body.get_position(bVec);
			PlayState.ME.player.body.get_position(pVec);
			
			bVec = pVec - bVec;
			
			var angleDeg = FlxAngle.asDegrees(bVec.radians);
			if (angleDeg > 0) {
				angleDeg = FlxMath.bound(angleDeg, 135, 180);
				if (angleDeg < 135 + 11.25) {
					baseFrame = 4;
				} else if (angleDeg < 180 - 11.25) {
					baseFrame = 3;
				} else {
					baseFrame = 2;
				}
			} else {
				angleDeg = FlxMath.bound(angleDeg, -180, -135);
				if (angleDeg > -135 - 11.25) {
					baseFrame = 0;
				} else if (angleDeg > -180 + 11.25) {
					baseFrame = 1;
				} else {
					baseFrame = 2;
				}
			}
			FlxG.watch.addQuick('angle${ID}: ', angleDeg);

			bulletTimer -= elapsed;
			if (bulletTimer <= 0) {
				bulletTimer += 1.0;

				var BULLET_SPEED = 30;
				var trajectory = FlxPoint.get(-BULLET_SPEED, 0);
				var offset = FlxPoint.get(-10, 0);
				var adjust = switch(baseFrame) {
					case 0:
						45;
					case 1:
						22.5;
					case 3:
						-22.5;
					case 4:
						-45;
					default:
						0;
				}

				trajectory.rotateByDegrees(adjust);
				offset.rotateByDegrees(adjust);
				var bullet = BasicBullet.pool.recycle(BasicBullet);
				bullet.spawn(body.x + offset.x, body.y + offset.y, trajectory);
				PlayState.ME.addEnemyBullet(bullet);
			}
		}

		animation.frameIndex = baseFrame + frameMod;
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is BasicBullet) {
			health--;

			if (health <= 0) {
				body.active = false;
				frameMod = 10;
			} else {
				frameMod = 5;
				damageTimer.start(damageBlinkDuration, (t) -> {
					if (health > 0) {
						frameMod = 0;
					}
				});
			}
		}
	}
}