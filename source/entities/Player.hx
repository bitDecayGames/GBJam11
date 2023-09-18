package entities;

import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import flixel.FlxG;
import states.PlayState;
import flixel.math.FlxMath;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;

import echo.Line;
import echo.util.AABB;
import echo.data.Data.CollisionData;
import echo.Body;
import echo.math.Vector2;
import echo.Shape;
import bitdecay.flixel.debug.DebugDraw;

import animation.AnimationState;
import debug.DebugLayers;
import input.InputCalcuator;
import input.SimpleController;
import loaders.Aseprite;
import loaders.AsepriteMacros;
import entities.projectile.BasicBullet;

using echo.FlxEcho;

enum PlayerState {
	GROUNDED;
	JUMPING;
	FALLING;
	FASTFALL;
}

class Player extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/player.json");
	public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/player.json", "Layer 1");

	// Tune this to make the player feel more/less mobile. This dictates interaction with gravity and any
	// collisions
	private static inline var PLAYER_WEIGHT = 500;

	// true cap on absolute speed (nice for limiting max fall speed, etc)
	var MAX_VELOCITY = 15 * Constants.BLOCK_SIZE;
	var WALL_COLLIDE_SFX_THRESHOLD = 100;

	var previousVelocity:Vector2 = new Vector2(0, 0);

	public var inControl:Bool = true;

	var groundedCastLeft:Bool = false;
	var groundedCastMiddle:Bool = false;
	var groundedCastRight:Bool = false;

	public var mainBody:echo.Shape.Shape;
	public var proneBody:echo.Shape.Shape;

	// if we are playing it in debug, make it harder for us. Be nice to players
	var COYOTE_TIME = #if debug 0.1 #else 0.2 #end;
	var JUMP_WINDOW = .5;
	var MIN_JUMP_WINDOW = 0.1;
	var INITIAL_JUMP_STRENGTH = -11.5 * Constants.BLOCK_SIZE;
	var MAX_JUMP_RELEASE_VELOCITY = -5 * Constants.BLOCK_SIZE;
	var FAST_FALL_SPEED = 20 * Constants.BLOCK_SIZE;
	var BULLET_SPEED = 15 * Constants.BLOCK_SIZE;

	var bonkedHead = false;
	var jumping = false;
	var jumpHigherTimer = 0.0;

	var speed:Float = 30;
	var playerNum = 0;

	var accel:Float = 100000000;
	var airAccel:Float = 100000000;
	var decel:Float = 100000000;
	var maxSpeed:Float = Constants.BLOCK_SIZE * 4;

	// set to true to run a one-time grounded check
	var checkGrounded = true;
	public var grounded = false;
	var unGroundedTime = 0.0;

	var tmp:FlxPoint = FlxPoint.get();
	var tmpAABB:AABB = AABB.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	var controlState:PlayerState = FALLING;
	var intentState = new AnimationState();
	var animState = new AnimationState();

	var awaitingDeath = false;
	var deathStillnessTimer = 0.5;

	var killable = true;

	public function new(x:Float, y:Float) {
		super(x, y);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.Jump);
		animation.callback = (anim, frame, index) -> {
			// if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			// }
		};

		mainBody = body.shapes[0];
		proneBody = body.shapes[1];
		body.remove_shape(proneBody);
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			max_velocity_x: maxSpeed,
			max_velocity_length: MAX_VELOCITY,
			drag_x: 0,
			mass: PLAYER_WEIGHT,
			shapes: [
				// Standard moving hitbox
				{
					type:RECT,
					width: 12,
					height: 20,
					offset_y: 8,
				},
				// Prone hitbox
				{
					type:RECT,
					width: 12,
					height: 7,
					offset_y: 15.5,
				}
			]
		});
	}

	public function invulnerable(duration:Float) {
		killable = false;
		FlxSpriteUtil.flicker(this, duration, (f) -> {
			killable = true;
		});
	}

	override public function update(delta:Float) {
		super.update(delta);

		intentState.reset();
		animState.reset();

		if (inControl) {
			handleInput(delta);
			updateCurrentAnimation();
		} else if (awaitingDeath) {
			if (body.velocity.length == 0) {
				deathStillnessTimer -= delta;

				if (deathStillnessTimer <= 0) {
					PlayState.ME.killPlayer();
					active = false;
				}
			}
		}

		FlxG.watch.addQuick('player Vel:', body.velocity);
	}

	function handleDirectionIntent() {
		var inputDir = InputCalcuator.getInputCardinal(playerNum);
		inputDir.asVector(tmp);
		if (tmp.y < 0) {
			intentState.add(UPPING);
		} else if (tmp.y > 0) {
			intentState.add(DOWNING);
		}

		if (tmp.x > 0) {
			intentState.add(MOVE_RIGHT);
		} else if (tmp.x < 0) {
			intentState.add(MOVE_LEFT);
		}
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

	var shootTimer = new FlxTimer();

	function handleShoot() {
		if (SimpleController.just_pressed(B)) {
			var trajectory = FlxPoint.weak(BULLET_SPEED, 0);
			var vertOffset = 7;
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
					angleAdjust = -90;
				} else if (intentState.has(DOWNING)) {
					offset.x = 18;
					vertOffset = 13;
				}
			}

			if (StringTools.startsWith(animation.curAnim.name, "Jump")) {
				vertOffset -= 6;
			}

			trajectory.rotateByDegrees(angleAdjust);
			offset.rotateByDegrees(angleAdjust);
			var bullet = BasicBullet.pool.recycle(BasicBullet);
			bullet.spawn(body.x + offset.x, body.y + offset.y + vertOffset, trajectory);
			PlayState.ME.addPlayerBullet(bullet);
			if (animation.curAnim != null && !StringTools.endsWith(animation.curAnim.name, "Shoot")) {
				muzzleFlashAnim(0.05);
			}
		}
	}

	function updateGrounded() {
		groundedCastLeft = false;
		groundedCastMiddle = false;
		groundedCastRight = false;
		
		body.bounds(tmpAABB);

		var rayChecksPassed = 0;
		echoTmp.set(tmpAABB.min_x, tmpAABB.max_y - 2);
		var groundedCast = Line.get_from_vector(echoTmp, 90, 5);
		var intersects = groundedCast.linecast_all(PlayState.ME.terrainBodies);
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
		var intersectsMiddle = groundedCast.linecast_all(PlayState.ME.terrainBodies);
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
		var intersectsRight = groundedCast.linecast_all(PlayState.ME.terrainBodies);
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
					// FmodManager.PlaySoundOneShot(FmodSFX.PlayerLand1);
				}
				grounded = true;
			}
		} else if (!groundedCastLeft && !groundedCastMiddle && !groundedCastRight) {
			checkGrounded = false;
			grounded = false;
		}
	}

	function handleInput(delta:Float) {
		handleDirectionIntent();

		switch(controlState) {
			case GROUNDED:
				handleMovement();
				handleShoot();
				updateGrounded();
				if (!grounded) {
					unGroundedTime = Math.min(unGroundedTime + delta, COYOTE_TIME);
		
					if (unGroundedTime < COYOTE_TIME) {
						DebugDraw.ME.drawWorldLine(
							body.x - 5,
							body.y - 25,
							body.x + 5 - (unGroundedTime / COYOTE_TIME * 10),
							body.y - 25, PLAYER, FlxColor.LIME);
					}
				} else {
					unGroundedTime = 0.0;
				}

				if ((grounded || (unGroundedTime < COYOTE_TIME)) && SimpleController.just_pressed(A)) {
					// FmodManager.PlaySoundOneShot(FmodSFX.PlayerJump4);
					y--;
					body.velocity.y = INITIAL_JUMP_STRENGTH;
					unGroundedTime = COYOTE_TIME;
					grounded = false;
					jumpHigherTimer = JUMP_WINDOW;
					jumping = true;
					bonkedHead = false;
					controlState = JUMPING;
				}

				if (unGroundedTime > COYOTE_TIME) {
					grounded = false;
					controlState = FALLING;
				}
			case JUMPING:
				// handle air control
				handleMovement();
				handleShoot();
				// TODO: Holding jump for higher jump
				jumpHigherTimer = Math.max(0, jumpHigherTimer - delta);
				#if debug_player
				FlxG.watch.addQuick('jump timer: ', jumpHigherTimer);
				#end
				if (!SimpleController.pressed(A) || bonkedHead || body.velocity.y > 0 || jumpHigherTimer <= 0) {
					controlState = FALLING;
					body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);
				}

				if (SimpleController.just_pressed(DOWN)) {
					controlState = FASTFALL;
				}
				updateGrounded(); // is this needed for jumping?
			case FALLING:
				handleMovement();
				handleShoot();
				body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);

				if (SimpleController.just_pressed(DOWN)) {
					controlState = FASTFALL;
				}

				updateGrounded();
				if (grounded) {
					controlState = GROUNDED;
				}
			case FASTFALL:
				// options while fast falling? Just shooting?
				handleShoot();
				body.velocity.y = FAST_FALL_SPEED;
				updateGrounded();
				if (grounded) {
					controlState = GROUNDED;
				}
		}

		FlxG.watch.addQuick("Player State:", controlState.getName());

		
		#if debug_player
		var velScaler = 20;
		var color = jumping ? FlxColor.CYAN : FlxColor.MAGENTA;
		FlxG.watch.addQuick('Player y velocity: ', body.velocity.y);

		DebugDraw.ME.drawWorldLine(
			body.x - 15,
			body.y,
			body.x - 15,
			body.y + (body.velocity.y / 20),
			PLAYER,
			color);
		DebugDraw.ME.drawWorldLine(
			body.x - 20,
			body.y + INITIAL_JUMP_STRENGTH / velScaler,
			body.x - 10,
			body.y + INITIAL_JUMP_STRENGTH / velScaler,
			PLAYER,
			FlxColor.ORANGE);
		DebugDraw.ME.drawWorldLine(
			body.x - 20,
			body.y + MAX_JUMP_RELEASE_VELOCITY / velScaler,
			body.x - 10,
			body.y + MAX_JUMP_RELEASE_VELOCITY / velScaler,
			PLAYER,
			FlxColor.RED);
		DebugDraw.ME.drawWorldLine(
			body.x - 23,
			body.y,
			body.x - 7,
			body.y,
			PLAYER,
			FlxColor.GRAY);
		DebugDraw.ME.drawWorldRect(
			body.x - 23,
			body.y - MAX_VELOCITY / velScaler,
			13,
			MAX_VELOCITY / velScaler * 2,
			PLAYER,
			FlxColor.GRAY);
		#end
		
		if (grounded) {
			animState.add(GROUNDED);
		}
	}

	function updateCurrentAnimation() {
		var nextAnim = animation.curAnim.name;

		if (intentState.has(MOVE_RIGHT)) {
			flipX = false;
		} else if (intentState.has(MOVE_LEFT)) {
			flipX = true;
		}

		if (animState.has(GROUNDED)) {
			if (animState.has(RUNNING)) {
				if (intentState.has(UPPING)) {
					nextAnim = anims.RunUpward;
				} else if (intentState.has(DOWNING)) {
					nextAnim = anims.RunDownward;
				} else {
					nextAnim = anims.Run;

				}
			} else { 
				if (intentState.has(UPPING)) {
					nextAnim = anims.IdleUp;
				} else if (intentState.has(DOWNING)) {
					nextAnim = anims.Prone;
				} else {
					nextAnim = anims.Idle;
				}
			}
		} else {
			if (animState.has(RUNNING)) {
				if (intentState.has(UPPING)) {
					nextAnim = anims.JumpUpward;
				} else if (intentState.has(DOWNING)) {
					nextAnim = anims.JumpDownward;
				} else {
					nextAnim = anims.Jump;
				}
			} else { 
				if (intentState.has(UPPING)) {
					nextAnim = anims.JumpUp;
				} else if (intentState.has(DOWNING)) {
					// no animation here as this is how you initiate fast-fall
					nextAnim = anims.Jump;
				} else {
					nextAnim = anims.Jump;
				}
			}
			if (body.velocity.y > 0 && !StringTools.endsWith(nextAnim, "Fall") && !StringTools.endsWith(nextAnim, "FallShoot")) {
				nextAnim = nextAnim + "Fall";
			}
		}

		playAnimIfNotAlready(nextAnim);
	}

	function playAnimIfNotAlready(name:String) {
		if (animation.curAnim == null || (animation.curAnim.name != name && animation.curAnim.name != name + "Shoot")) {
			FlxG.watch.addQuick('playAnim:', name);
			animation.play(name, true);

			if (StringTools.contains(name, "Prone")) {
				body.add_shape(proneBody);
				body.remove_shape(mainBody);
			} else {
				body.add_shape(mainBody);
				body.remove_shape(proneBody);
			}
		}
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
		FlxG.watch.addQuick('playAnim:', name);

		var frame = animation.curAnim.curFrame;
		var frameTime = animation.curAnim._frameTimer;
		animation.curAnim = animation.getByName(name);
		animation.curAnim.curFrame = frame;
		animation.curAnim._frameTimer = frameTime;
	}

	@:access(echo.Shape)
	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (data[0].sa.parent.object == this) {
			if (!data[0].sb.solid) {
				// ignore this collision if the _OTHER_ shape is not solid
				return;
			}
		} else if (data[0].sb.parent.object == this) {
			if (!data[0].sa.solid) {
				return;
			}
		}


		if (data[0].normal.y > 0) {
			checkGrounded = true;
		} else if (data[0].normal.y < 0) {
			if (!bonkedHead && body.velocity.y <= 0) {
				// FmodManager.PlaySoundOneShot(FmodSFX.PlayerBonk);
			}
			bonkedHead = true;
		}

		if (data[0].normal.x != 0 && previousVelocity.length > WALL_COLLIDE_SFX_THRESHOLD) {
			if (grounded) {
				// TODO(SFX): grounded wall smack
			} else {
				// FmodManager.PlaySoundOneShot(FmodSFX.PlayerBonkWall2);
			}
		}

		if (killable && other.object is BasicBullet) {
			inControl = false;
			body.velocity.x = 0;
			awaitingDeath = true;
			playAnimIfNotAlready(anims.DeathFront);
		}
	}

	@:access(echo.Shape)
	override function handleStay(other:Body, data:Array<CollisionData>) {
		super.handleStay(other, data);

		var otherShape:Shape = null;

		if (data[0].sa.parent.object == this) {
			otherShape = data[0].sb;
		} else {
			otherShape = data[0].sa;
		}

		if (data[0].normal.y < 0) {
			if (!bonkedHead && body.velocity.y <= 0) {
				// FmodManager.PlaySoundOneShot(FmodSFX.PlayerBonk);
			}
			bonkedHead = true;
		}
	}
}
