package entities.boss;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import entities.particle.Explosion;
import entities.projectile.BasicBullet;
import echo.data.Data.CollisionData;
import echo.Shape;
import loaders.AsepriteMacros;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import echo.Body;
import loaders.Aseprite;

using echo.FlxEcho;

class RoverBoss extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/Rover.json");
	public static var coreAnims = AsepriteMacros.tagNames("assets/aseprite/Core.json");

	public var turret:Turret;
	var turretOffset = FlxPoint.get(0, -3);
	
	public var core:FlxSprite;

	var leftShield:Shape;
	var rightShield:Shape;

	var waitTime = 3.0;
	var phases = [
		"wait",
		"shoot",
		"dash",
		"nothing",
	];

	var curPhase = 0;

	var damageTimer:FlxTimer = new FlxTimer();

	public function new(x:Float, y:Float) {
		// 64x28
		super(x, y-14);
		health = 10;
		
		// body.active = false;

		turret = new Turret(this.x + turretOffset.x, this.y + turretOffset.y);
		turret.externallyControlled();

		core = new FlxSprite();
		Aseprite.loadAllAnimations(core, AssetPaths.Core__json);
		core.animation.play(coreAnims.Throb);
	} 

	override function configSprite() {
		Aseprite.loadAllAnimations(this, AssetPaths.Rover__json);
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:RECT,
					width: 10,
					height: 15,
					offset_y: 3
				},
				{
					type:RECT,
					width: 10,
					height:20,
					offset_x: -20
				},
				{
					type:RECT,
					width: 10,
					height:20,
					offset_x: 20
				}
			],
			kinematic: true,
		});

		leftShield = body.shapes[1];
		rightShield = body.shapes[2];
	}

	var waiting = true;

	override function update(elapsed:Float) {
		super.update(elapsed);

		curPhase = curPhase % phases.length;

		FlxG.watch.addQuick('roverPhase:', phases[curPhase]);
		FlxG.watch.addQuick('roverHP:', health);

		if (health <= 0) {
			return;
		}

		switch(curPhase) {
			case 0: //wait
				animation.stop();	
				waitTime -= elapsed;
				if (waitTime <= 0) {
					waitTime = 3.0;
					curPhase++;
				}
			case 1: //shoot
				if (turret.health > 0) {
					curPhase = 3; // XXX: do nothing until our timers finish
					turret.shootBullet(60);
					new FlxTimer().start(.25, (t) -> {
						turret.shootBullet(60);

						if (t.loopsLeft == 0) {
							// TODO SFX: anticipation frames, screeching of moon tires?
							animation.play(anims.Drive, false, x > camera.getCenterPoint().x ? false : true);
							new FlxTimer().start(.5, (t) -> {
								curPhase = 2;
							});
						}
					}, 2);
				} else {
					// TODO SFX: anticipation frames, screeching of moon tires?
					animation.play(anims.Drive, false, x > camera.getCenterPoint().x ? false : true);
					new FlxTimer().start(.5, (t) -> {
						curPhase++;
					});
				}
			case 2: //dash
				curPhase = 3;
				dashAcrossScreen();
			default:
		}

		core.visible = turret.health <= 0;

		turret.body.set_position(body.x + turretOffset.x, body.y + turretOffset.y);
		core.setPositionMidpoint(body.x + turretOffset.x, body.y + turretOffset.y);
	}

	function dashAcrossScreen() {
		if (x > camera.getCenterPoint().x) {
			// TODO: Need some sort of anticipation frames
			FlxTween.tween(body, {x: camera.viewLeft - 40}, {
				onComplete: (t) -> {
					if (turret.health <= 0) {
						turret.visible = false;
						core.visible = true;
					}
					animation.play(anims.Drive, false, x > camera.getCenterPoint().x ? false : true);
					FlxTween.tween(body, {x: camera.viewLeft + 25}, {
						onComplete: (t2) -> {
							curPhase = 0;
							waiting = true;
						}
					});
				}
			});
		} else {
			// TODO: Need some sort of anticipation frames
			FlxTween.tween(body, {x: camera.viewRight + 40}, {
				onComplete: (t) -> {
					if (turret.health <= 0) {
						turret.visible = false;
						core.visible = true;
					}
					animation.play(anims.Drive, false, x > camera.getCenterPoint().x ? false : true);
					FlxTween.tween(body, {x: camera.viewRight - 25}, {
						onComplete: (t2) -> {
							curPhase = 0;
							waiting = true;
						}
					});
				}
			});
		}
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is BasicBullet) {
			if (Math.abs(other.object.get_body().x - body.x) > 20) {
				// TODO SFX: Dink as bullet hit shield instead of boss
				return;
			}

			health--;
			camera.shake(0.01, 0.1);
			FmodManager.PlaySoundOneShot(FmodSFX.EnemyBossDamage);

			if (health <= 0) {
				core.animation.play(coreAnims.Damage);
				body.active = false;
				Explosion.death(10, FlxRect.weak(x, y, width, height), () -> {
					animation.play(anims.Broken);
				});
			} else {
				core.animation.play(coreAnims.Damage);
				damageTimer.start(.1, (t) -> {
					if (health > 0) {
						core.animation.play(coreAnims.Throb);
					}
				});
			}
		}
	}
}