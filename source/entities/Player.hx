package entities;

import entities.boss.RoverBoss;
import flixel.FlxObject;
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

class Player extends BaseHumanoid {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/player.json");
	public static var layers = AsepriteMacros.layerNames("assets/aseprite/characters/player.json");
	public static var eventData = AsepriteMacros.frameUserData("assets/aseprite/characters/player.json", "Layer 1");

	// Tune this to make the player feel more/less mobile. This dictates interaction with gravity and any
	// collisions
	private static inline var PLAYER_WEIGHT = 500;

	public var inControl:Bool = true;

	public var mainBody:echo.Shape.Shape;
	public var proneBody:echo.Shape.Shape;

	// if we are playing it in debug, make it harder for us. Be nice to players
	var COYOTE_TIME = #if debug 0.1 #else 0.2 #end;
	var JUMP_WINDOW = .5;
	var MIN_JUMP_WINDOW = 0.1;
	var INITIAL_JUMP_STRENGTH = -11.5 * Constants.BLOCK_SIZE;
	var MAX_JUMP_RELEASE_VELOCITY = -5 * Constants.BLOCK_SIZE;
	var FAST_FALL_SPEED = 20 * Constants.BLOCK_SIZE;
	var DOUBLE_JUMP_MODIFIER = 0.75;

	var bonkedHead = false;
	var jumpHigherTimer = 0.0;

	var playerNum = 0;

	var hasDoubleJump = true;
	var unGroundedTime = 0.0;

	var controlState:PlayerState = FALLING;

	var awaitingDeath = false;
	var deathStillnessTimer = 0.5;

	var focalChangeRight = false;
	var focalChangeTime = 0.0;
	public var focalPoint = new FlxObject();

	// between -1 and 1
	var focalRatio:Float = 0.0;
	var focalOffsetMax = 30;
	var focusChangeSpeed = 3;

	var onLandCB:Void->Void = null;

	var shootLockout = 0.0;
	var SHOOT_TIMER = 0.25;
	var PRESS_SHOOT_BONUS = .1;

	public function new(x:Float, y:Float) {
		super(x, y);

		mainBody = body.shapes[0];
		proneBody = body.shapes[1];
		body.remove_shape(proneBody);

		focalPoint.setPosition(body.x, body.y);
	}

	override function configSprite() {
		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.player__json);
		animation.play(anims.Jump);
		animation.callback = (anim, frame, index) -> {
			// if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			// }

			if (anim == anims.RunUpward || anim == anims.RunDownward || anim == anims.Run) {
				if (frame == 2 || frame == 5) {
					FmodManager.PlaySoundOneShot(FmodSFX.PlayerStep);
				}
			}
		};
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

	override public function update(delta:Float) {
		super.update(delta);

		if (shootLockout > 0) {
			shootLockout -= delta;
		}

		if (onLandCB != null && !previouslyGrounded && grounded) {
			// XXX: This is pretty brute-force... but it works
			animState.add(GROUNDED);
			body.velocity.set(0, 0);
			onLandCB();
			onLandCB = null;
		}

		if (inControl) {
			handleInput(delta);
			updateCurrentAnimation();

			if (body.velocity.x > 0) {
				if (!focalChangeRight) {
					focalChangeRight = true;
					focalChangeTime = 0;
				}
				if (focalRatio < 1) {
					focalChangeTime += delta;
				}
			} else if (body.velocity.x < 0) {
				if (focalChangeRight) {
					focalChangeRight = false;
					focalChangeTime = 0;
				}
				if (focalRatio > -1) {
					focalChangeTime += delta;
				}
			}

			if (focalChangeTime > 0.5) {
				if (body.velocity.x > 0) {
					focalRatio += focusChangeSpeed * delta;
				} else if (body.velocity.x < 0) {
					focalRatio -= focusChangeSpeed * delta;
				}
			}

	
			focalRatio = FlxMath.bound(focalRatio, -1, 1);
			focalPoint.setPosition(body.x + focalRatio * focalOffsetMax, body.y);
		} else if (!awaitingDeath) {
			updateGrounded();
			updateCurrentAnimation();
		} else {
			if (body.velocity.length == 0) {
				deathStillnessTimer -= delta;

				if (deathStillnessTimer <= 0) {
					PlayState.ME.killPlayer();
					active = false;
				}
			}
		}

		DebugDraw.ME.drawWorldCircle(focalPoint.x, focalPoint.y, 1, PLAYER, FlxColor.WHITE);

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

	override function handleShoot() {
		if (SimpleController.pressed(B) && shootLockout <= 0) {
			shootLockout = SHOOT_TIMER;
			super.handleShoot();
		}

		if (SimpleController.just_released(B) && shootLockout > 0) {
			shootLockout -= PRESS_SHOOT_BONUS;
		}
	}

	function handleInput(delta:Float) {
		handleDirectionIntent();

		switch(controlState) {
			case GROUNDED:
				hasDoubleJump = true;
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
					doJump();
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

				if (SimpleController.just_pressed(DOWN) && !(SimpleController.pressed(LEFT) || SimpleController.pressed(RIGHT))) {
					// controlState = FASTFALL;
				}
				updateGrounded(); // is this needed for jumping?
			case FALLING:
				handleMovement();
				handleShoot();
				body.velocity.y = Math.max(body.velocity.y, MAX_JUMP_RELEASE_VELOCITY);

				if (SimpleController.just_pressed(DOWN) && !(SimpleController.pressed(LEFT) || SimpleController.pressed(RIGHT))) {
					// controlState = FASTFALL;
				}

				if (hasDoubleJump && SimpleController.just_pressed(A)) {
					hasDoubleJump = false;
					doJump(false);
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

	function doJump(first:Bool = true) {
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerJump);
		y--;
		body.velocity.y = INITIAL_JUMP_STRENGTH * (first ? 1 : DOUBLE_JUMP_MODIFIER);
		unGroundedTime = COYOTE_TIME;
		grounded = false;
		jumpHigherTimer = JUMP_WINDOW;
		jumping = true;
		bonkedHead = false;
		controlState = JUMPING;
	}

	override function addBulletToGame(bullet:BasicBullet) {
		PlayState.ME.addPlayerBullet(bullet);
	}

	override function updateCurrentAnimation() {
		var nextAnim = animation.curAnim.name;

		if (grounded) {
			animState.add(GROUNDED);
		}

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
					nextAnim = anims.JumpDown;
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

		if (killable && !awaitingDeath) {
			if (other.object is BasicBullet) {
				doDie();
			} else if (other.object is Alien) {
				doDie();
			} else if (other.object is RoverBoss) {
				doDie();
			}
		}
	}

	override function playAnimIfNotAlready(name:String):Bool {
		var changed = super.playAnimIfNotAlready(name);
		if (changed) {
			if (StringTools.contains(name, "Prone")) {
				FmodManager.PlaySoundOneShot(FmodSFX.PlayerDuck);
				body.add_shape(proneBody);
				body.remove_shape(mainBody);
			} else {
				body.add_shape(mainBody);
				body.remove_shape(proneBody);
			}
		}
		return changed;
	}

	function doDie() {
		inControl = false;
		body.velocity.x = 0;
		awaitingDeath = true;
		FmodManager.PlaySoundOneShot(FmodSFX.PlayerDamage);
		FmodManager.PlaySoundOneShot(FmodSFX.VoicePlayerDeath1);
		playAnimIfNotAlready(anims.DeathFront);
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

	public function introduceYourselfWhenReady(cb:() -> Void) {
		onLandCB = cb;
	}
}
