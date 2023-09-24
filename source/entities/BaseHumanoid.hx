package entities;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import debug.DebugLayers;
import bitdecay.flixel.debug.DebugDraw;
import echo.Line;
import states.PlayState;
import entities.projectile.BasicBullet;
import flixel.util.FlxSpriteUtil;
import echo.util.AABB;
import animation.AnimationState;
import flixel.math.FlxPoint;
import echo.math.Vector2;

class BaseHumanoid extends EchoSprite {
	// true cap on absolute speed (nice for limiting max fall speed, etc)
	var MAX_VELOCITY = 15 * Constants.BLOCK_SIZE;
	var WALL_COLLIDE_SFX_THRESHOLD = 100;
	var BULLET_SPEED = 15 * Constants.BLOCK_SIZE;

	var previousVelocity:Vector2 = new Vector2(0, 0);

	var groundedCastLeft:Bool = false;
	var groundedCastMiddle:Bool = false;
	var groundedCastRight:Bool = false;

	var speed:Float = 30;

	var accel:Float = 100000000;
	var airAccel:Float = 100000000;
	var decel:Float = 100000000;
	var maxSpeed:Float = Constants.BLOCK_SIZE * 8;

	// set to true to run a one-time grounded check
	var checkGrounded = false;
	public var previouslyGrounded = false;
	public var grounded = false;

	var jumping = false;

	var tmp:FlxPoint = FlxPoint.get();
	var tmpAABB:AABB = AABB.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	var intentState = new AnimationState();
	var animState = new AnimationState();

	var shootTimer = new FlxTimer();

	public var killable = true;

	public var forceGrounded = false;

	public function new(x:Float, y:Float) {
		super(x, y);

		// This aligns the body's bottom edge with whatever coordinate y was passed in for our creation
		body.y = body.y - (body.shapes[0].bottom - body.shapes[0].top)/2 - body.shapes[0].get_local_position().y;
	}

	public function invulnerable(duration:Float) {
		killable = false;
		FlxSpriteUtil.flicker(this, duration, (f) -> {
			killable = true;
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		intentState.reset();
		animState.reset();
	}

	function handleMovement() {
		if (intentState.has(MOVE_LEFT)) {
			animState.add(RUNNING);
			animState.add(MOVE_LEFT);
			body.velocity.x = -maxSpeed;
		} else if (intentState.has(MOVE_RIGHT)) {
			animState.add(RUNNING);
			animState.add(MOVE_RIGHT);
			body.velocity.x = maxSpeed;
		} else {
			body.velocity.x = 0;
		}
	}

	function handleShoot() {
		if (Math.abs(body.x - camera.getCenterPoint().x) < FlxG.width * 2) {
			FmodManager.PlaySoundOneShot(FmodSFX.WeaponGunShoot);
		}
		var trajectory = FlxPoint.weak(BULLET_SPEED, 0);
		var vertOffset = 7;
		var horizontalOffset = 0;
		var offset = FlxPoint.weak(12);
		var angleAdjust = flipX ? 180 : 0;
		if (intentState.has(MOVE_RIGHT)) {
			if (intentState.has(UPPING)) {
				angleAdjust = -45;
			} else if (intentState.has(DOWNING)) {
				angleAdjust = 45;
			}
		} else if (intentState.has(MOVE_LEFT)) {
			angleAdjust = 180;
			if (intentState.has(UPPING)) {
				angleAdjust = -135;
			} else if (intentState.has(DOWNING)) {
				angleAdjust = 135;
			}
		} else {
			if (intentState.has(UPPING)) {
				vertOffset = 6;
				angleAdjust = -90;
			} else if (intentState.has(DOWNING)) {
				if (grounded) {
					offset.x = 18;
					vertOffset = 13;
				} else {
					angleAdjust = 90;
					horizontalOffset = 4 * (flipX ? -1 : 1);
					vertOffset = 14;
				}
			}
		}

		if (StringTools.startsWith(animation.curAnim.name, "Jump")) {
			vertOffset -= 6;
		}

		trajectory.rotateByDegrees(angleAdjust);
		offset.rotateByDegrees(angleAdjust);
		var bullet = BasicBullet.pool.recycle(BasicBullet);
		bullet.spawn(body.x + offset.x + horizontalOffset, body.y + offset.y + vertOffset, trajectory);
		addBulletToGame(bullet);
		if (animation.curAnim != null && !StringTools.endsWith(animation.curAnim.name, "Shoot")) {
			muzzleFlashAnim(0.05);
		}
	}

	function addBulletToGame(bullet:BasicBullet) {
		PlayState.ME.addEnemyBullet(bullet);
	}

	function updateGrounded() {
		previouslyGrounded = grounded;
		groundedCastLeft = false;
		groundedCastMiddle = false;
		groundedCastRight = false;
		
		body.bounds(tmpAABB);

		var rayChecksPassed = 0;
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		var groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersects = groundedCast.linecast_all(PlayState.ME.allGroundingBodies);
		DebugDraw.ME.drawWorldLine(echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersects.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersects.length >= 1) {
			rayChecksPassed++;
			groundedCastLeft = true;
		}
		for (i in intersects) {
			i.put();
		}
		
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		echoTmp.x += tmpAABB.width/2;
		groundedCast = Line.get_from_vector(echoTmp, 90, 12);
		var intersectsMiddle = groundedCast.linecast_all(PlayState.ME.allGroundingBodies);
		DebugDraw.ME.drawWorldLine(echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsMiddle.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersectsMiddle.length >= 1) {
			rayChecksPassed++;
			groundedCastMiddle = true;
		}
		for (i in intersectsMiddle) {
			i.put();
		}

		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		echoTmp.x += tmpAABB.width;
		groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersectsRight = groundedCast.linecast_all(PlayState.ME.allGroundingBodies);
		DebugDraw.ME.drawWorldLine(echoTmp.x, echoTmp.y, groundedCast.end.x, groundedCast.end.y, DebugLayers.RAYCAST, intersectsRight.length >= 1 ? FlxColor.MAGENTA : FlxColor.LIME);
		groundedCast.put();
		if (intersectsRight.length >= 1) {
			rayChecksPassed++;
			groundedCastRight = true;
		}
		for (i in intersectsRight) {
			i.put();
		}

		// this cast is originating within the player, so it will always give back at least one
		if (rayChecksPassed >= 1) {
			if (checkGrounded) {
				checkGrounded = false;
				if(grounded == false) {
					FmodManager.PlaySoundOneShot(FmodSFX.PlayerLand);
				}
				grounded = true;
			}
		} else if (!groundedCastLeft && !groundedCastMiddle && !groundedCastRight) {
			checkGrounded = false;
			grounded = false;
		}

		if (forceGrounded) {
			grounded = true;
		}
	}

	function updateCurrentAnimation() {
		var nextAnim = animation.curAnim.name;

		if (intentState.has(MOVE_RIGHT)) {
			flipX = false;
		} else if (intentState.has(MOVE_LEFT)) {
			flipX = true;
		}

		// if (animState.has(GROUNDED)) {
		// 	if (animState.has(RUNNING)) {
		// 		if (intentState.has(UPPING)) {
		// 			nextAnim = anims.RunUpward;
		// 		} else if (intentState.has(DOWNING)) {
		// 			nextAnim = anims.RunDownward;
		// 		} else {
		// 			nextAnim = anims.Run;

		// 		}
		// 	} else { 
		// 		if (intentState.has(UPPING)) {
		// 			nextAnim = anims.IdleUp;
		// 		} else if (intentState.has(DOWNING)) {
		// 			nextAnim = anims.Prone;
		// 		} else {
		// 			nextAnim = anims.Idle;
		// 		}
		// 	}
		// } else {
		// 	if (animState.has(RUNNING)) {
		// 		if (intentState.has(UPPING)) {
		// 			nextAnim = anims.JumpUpward;
		// 		} else if (intentState.has(DOWNING)) {
		// 			nextAnim = anims.JumpDownward;
		// 		} else {
		// 			nextAnim = anims.Jump;
		// 		}
		// 	} else { 
		// 		if (intentState.has(UPPING)) {
		// 			nextAnim = anims.JumpUp;
		// 		} else if (intentState.has(DOWNING)) {
		// 			// no animation here as this is how you initiate fast-fall
		// 			nextAnim = anims.Jump;
		// 		} else {
		// 			nextAnim = anims.Jump;
		// 		}
		// 	}
		// 	if (body.velocity.y > 0 && !StringTools.endsWith(nextAnim, "Fall") && !StringTools.endsWith(nextAnim, "FallShoot")) {
		// 		nextAnim = nextAnim + "Fall";
		// 	}
		// }

		playAnimIfNotAlready(nextAnim);
	}

	function playAnimIfNotAlready(name:String):Bool {
		if (animation.curAnim == null || (animation.curAnim.name != name && animation.curAnim.name != name + "Shoot")) {
			animation.play(name, true);
			return true;
		}
		return false;
	}

	@:access(flixel.animation.FlxAnimation)
	function muzzleFlashAnim(duration:Float) {
		var restoreName = animation.curAnim.name;

		inheretAnimation(animation.curAnim.name + "Shoot");
		shootTimer.start(0.05, (t) -> {
			if (animation.curAnim != null && StringTools.endsWith(animation.curAnim.name, "Shoot")) {
				inheretAnimation(restoreName);
			}
		});
	}

	@:access(flixel.animation.FlxAnimation)
	function inheretAnimation(name:String) {
		if (animation.getByName(name) == null) {
			return;
		}

		var frame = animation.curAnim.curFrame;
		var frameTime = animation.curAnim._frameTimer;
		animation.curAnim = animation.getByName(name);
		animation.curAnim.curFrame = frame;
		animation.curAnim._frameTimer = frameTime;
	}
}