package entities;

import entities.Player.PlayerState;
import bitdecay.flixel.debug.DebugDraw;
import debug.DebugLayers;
import flixel.util.FlxColor;
import states.PlayState;
import echo.Line;
import echo.util.AABB;
import flixel.math.FlxPoint;
import echo.math.Vector2;
import echo.data.Data.CollisionData;
import entities.sensor.AlienSpawner;
import entities.sensor.Trigger;
import echo.Body;
import loaders.AsepriteMacros;
import loaders.Aseprite;
import animation.AnimationState;

using echo.FlxEcho;

class Alien extends EchoSprite {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/alien.json");

	var source:AlienSpawner = null;

	var groundedCastLeft:Bool = false;
	var groundedCastMiddle:Bool = false;
	var groundedCastRight:Bool = false;
	var tmp:FlxPoint = FlxPoint.get();
	var tmpAABB:AABB = AABB.get();
	var echoTmp:Vector2 = new Vector2(0, 0);

	var controlState:PlayerState = FALLING;
	var intentState = new AnimationState();
	var animState = new AnimationState();

	// set to true to run a one-time grounded check
	var checkGrounded = true;
	public var grounded = false;
	
	public function new(x:Float, y:Float, source:AlienSpawner) {
		super(x, y);

		flipX = true;

		this.source = source;

		// This aligns the body's bottom edge with whatever coordinate y was passed in for our creation
		// body.y = body.y - (mainBody.bottom - mainBody.top)/2 - mainBody.get_local_position().y;
	}

	override function configSprite() {
		super.configSprite();

		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.alien__json);
		animation.play(anims.Jump);
		animation.callback = (anim, frame, index) -> {
			// if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			// }
		};
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:RECT,
					width: 12,
					height: 20,
					offset_y: 3,
					offset_x: -2
				}
			]
		});
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		updateGrounded();
		updateCurrentAnimation();
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

	function updateCurrentAnimation() {
		var nextAnim = animation.curAnim.name;
		if (intentState.has(MOVE_RIGHT)) {
			flipX = false;
		} else if (intentState.has(MOVE_LEFT)) {
			flipX = true;
		}

		if (grounded) {
			if (intentState.has(MOVE_RIGHT)) {
				nextAnim = anims.Run;
			} else if (intentState.has(MOVE_LEFT)) {
				nextAnim = anims.Run;
			} else {
				nextAnim = anims.Idle;
			}
		} else {
			nextAnim = anims.Jump;
		}

		// if (intentState.has(MOVE_RIGHT)) {
		// 	flipX = false;
		// } else if (intentState.has(MOVE_LEFT)) {
		// 	flipX = true;
		// }

		// if (animState.has(GROUNDED)) {
		// 	if (animState.has(RUNNING)) {
		// 		nextAnim = anims.Run;
		// 	} else { 
		// 		// nextAnim = anims.Idle;
		// 	}
		// } else {
		// 	if (animState.has(RUNNING)) {
		// 			nextAnim = anims.Jump;
		// 	} else { 
		// 		nextAnim = anims.Jump;
		// 	}
		// 	// if (body.velocity.y > 0 && !StringTools.endsWith(nextAnim, "Fall") && !StringTools.endsWith(nextAnim, "FallShoot")) {
		// 	// 	nextAnim = nextAnim + "Fall";
		// 	// }
		// }

		playAnimIfNotAlready(nextAnim);
	}

	function playAnimIfNotAlready(name:String) {
		if (animation.curAnim == null || (animation.curAnim.name != name && animation.curAnim.name != name + "Shoot")) {
			animation.play(name, true);
		}
	}

	override function kill() {
		super.kill();

		if (source != null) {
			source.queueReset();
		}
	}
}