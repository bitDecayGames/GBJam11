package progress;

import flixel.FlxG;

typedef Data = {
	version: String,
	gameCompleted: Bool,
	unlocks: {},
	checkpoint: {
		lastLevelID: String,
		lastCheckpointID: String,
		deaths: Int,
		time: Float,
	}
}

class Collected {
	private static inline var LATEST_VERSION:String = "1";
	private static var initialized = false;

	public static function newData():Data {
		return {
			version: LATEST_VERSION,
			gameCompleted: false,
			unlocks: {},
			checkpoint: {
				time: 0,
				deaths: 0,
				lastLevelID: null,
				lastCheckpointID: null
			}
		};
	}

	public static function initialize() {
		if (!initialized) {
			FlxG.save.bind("save", "bitdecaygames/gbjam11/");
			if (FlxG.save.data.game == null || FlxG.save.data.game.version != LATEST_VERSION #if clearsave || true#end) {
				FlxG.save.data.game = Collected.newData();
				FlxG.save.flush();
			}
			initialized = true;
		}
	}

	// public static function unlockThing() {
	// 	FlxG.save.data.game.unlocks.thing = true;
	// 	FlxG.save.flush();
	// }

	public static function gameComplete() {
		clearCheckpoint();
		clearUnlocks();
		FlxG.save.data.game.gameCompleted = true;
		FlxG.save.flush();
	}

	public static function setLastCheckpoint(levelID:String, entityID:String) {
		FlxG.save.data.game.checkpoint.lastLevelID = levelID;
		FlxG.save.data.game.checkpoint.lastCheckpointID = entityID;
		FlxG.save.flush();
	}

	static function clearCheckpoint() {
		FlxG.save.data.game.checkpoint = {
			lastLevelID: null,
			time: 0.0,
			deaths: 0,
		};
		FlxG.save.flush();
	}

	static function clearUnlocks() {
		FlxG.save.data.game.unlocks = {
		};
		FlxG.save.flush();
	}

	public static function getCheckpointLevel() {
		return FlxG.save.data.game.checkpoint.lastLevelID;
	}

	public static function getCheckpointID() {
		return FlxG.save.data.game.checkpoint.lastCheckpointID;
	}

	public static function addDeath() {
		FlxG.save.data.game.checkpoint.deaths++;
		FlxG.save.flush();
	}

	public static function getDeathCount():Int {
		return FlxG.save.data.game.checkpoint.deaths;
	}

	public static function addTime(t:Float) {
		FlxG.save.data.game.checkpoint.time += t;
		FlxG.save.flush;
	}

	public static function getTime():Float {
		return FlxG.save.data.game.checkpoint.time;
	}
}