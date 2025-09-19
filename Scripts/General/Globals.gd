extends Node

var screenSize : Vector2 = Vector2(480, 360)

var selected_character : String = "Mario"

var currentLap : int = 1
var totalLaps : int = 3
var raceFinished : bool = false
var hasPassedCheckpoint : bool = false
var raceStartTime : int = 0
var minimumLapTime : int = 2000
var lastLapTime : int = 0
var useSimpleDetection : bool = true

var raceStarted : bool = false
var raceCountdown : bool = false

var playerBeforeFinishLine : bool = false
var finishLineY : float = 520.0

var startPosition : Vector3 = Vector3(123, 0, 580)

var finishLinePosition : Vector2 = Vector2(123, 513) 
var checkpointPosition : Vector2 = Vector2(500, 350) 

enum RoadType {
	VOID = 0,
	ROAD = 1,
	GRAVEL = 2,
	OFF_ROAD = 3,
	WALL = 4,
	SINK = 5,
	HAZARD = 6
}

func reset_race():
	currentLap = 1
	raceFinished = false
	raceStarted = false
	raceCountdown = false
	lastLapTime = 0
	playerBeforeFinishLine = false
	lastLapTime = Time.get_ticks_msec()
