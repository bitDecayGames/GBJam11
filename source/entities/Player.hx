package entities;

import flixel.FlxG;
import states.PlayState;
import echo.Line;
import flixel.math.FlxMath;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import animation.AnimationState;
import echo.util.AABB;
import echo.data.Data.CollisionData;
import flixel.math.FlxPoint;
import bitdecay.flixel.debug.DebugDraw;
import echo.Body;
import echo.math.Vector2;
import flixel.FlxSprite;
import debug.DebugLayers;

import echo.Shape;
import input.InputCalcuator;
import input.SimpleController;
import loaders.Aseprite;
import loaders.AsepriteMacros;

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

	// if we are playing it in debug, make it harder for us. Be nice to players
	var COYOTE_TIME = #if debug 0.1 #else 0.2 #end;
	var JUMP_WINDOW = .5;
	var MIN_JUMP_WINDOW = 0.1;
	var INITIAL_JUMP_STRENGTH = -11.5 * Constants.BLOCK_SIZE;
	var MAX_JUMP_RELEASE_VELOCITY = -5 * Constants.BLOCK_SIZE;
	var FAST_FALL_SPEED = 20 * Constants.BLOCK_SIZE;

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
	var animState = new AnimationState();

	public function new(x:Float, y:Float) {
		super(x, y);
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.right);
		animation.callback = (anim, frame, index) -> {
			if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			}
		};

		mainBody = body.shapes[0];
		// groundCircle = body.shapes[1];
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
				{
					type:RECT,
					width: 12,
					height: 16,
					offset_y: 8,
				},
				// collision snag helpers
				// {
				// 	type:CIRCLE,
				// 	radius: 4,
				// 	offset_y: 12.1
				// }
			]
		});
	}

	override public function update(delta:Float) {
		super.update(delta);

		handleInput(delta);
	}

	function handleLeftRight() {
		var inputDir = InputCalcuator.getInputCardinal(playerNum);
		if (inputDir != NONE) {
			inputDir.asVector(tmp);
			if (tmp.x != 0) {
				if (!SimpleController.pressed(DOWN)) {
					animState.add(RUNNING);
					body.velocity.x = maxSpeed * (tmp.x < 0 ? -1 : 1);
				} else {
					// can't hold down and run
					body.velocity.x = 0;
				}
			} else {
				body.velocity.x = 0;
			}
		} else {
			body.velocity.x = 0;
		}

		if (body.velocity.x > 0) {
			animState.add(MOVE_RIGHT);
		} else if (body.acceleration.x < 0) {
			animState.add(MOVE_LEFT);
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
		switch(controlState) {
			case GROUNDED:
				// handle running and initial jump
				handleLeftRight();
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
				handleLeftRight();
				// TODO: Holding jump for higher jump
				jumpHigherTimer = Math.max(0, jumpHigherTimer - delta);
				#if debug_player
				FlxG.watch.addQuick('jump timer: ', jumpHigherTimer);
				#end
				if (!SimpleController.pressed(A) || bonkedHead || body.velocity.y > 0) {
					// jumping = false;
					controlState = FALLING;
					body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);
				}

				if (SimpleController.just_pressed(DOWN)) {
					controlState = FASTFALL;
				}
				updateGrounded(); // is this needed for jumping?
			case FALLING:
				handleLeftRight();
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
				body.velocity.y = FAST_FALL_SPEED;
				updateGrounded();
				if (grounded) {
					controlState = GROUNDED;
				}
		}

		FlxG.watch.addQuick("Player State:", controlState.getName());

		// if (jumping) {
		// 	jumpHigherTimer = Math.max(0, jumpHigherTimer - delta);
		// 	#if debug_player
		// 	FlxG.watch.addQuick('jump timer: ', jumpHigherTimer);
		// 	#end
		// 	if (!SimpleController.pressed(A) || bonkedHead) {
		// 		jumping = false;
		// 		body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);
		// 	}
		// }

		var velScaler = 20;
		var color = jumping ? FlxColor.CYAN : FlxColor.MAGENTA;

		#if debug_player
		FlxG.watch.addQuick('Player y velocity: ', body.velocity.y);
		#end
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

		// TODO: Need to prevent running (x-accel) when crouching
		// if (SimpleController.pressed(DOWN)) {
		// 	animState.add(CROUCHED);
		// 	// topShape.solid = false;
		// 	if (grounded) {
		// 		body.drag.x = decel;
		// 	} else {
		// 		body.drag.x = decel;
		// 	}
		// } else {
		// 	// topShape.solid = true;
		// 	body.drag.x = decel;
		// }
		
		if (grounded) {
			animState.add(GROUNDED);
		}
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
