# transparency that lessens as they move
# add transition to "stats" at the end
# CONNECT final stats to actual stats
extends Node2D

var spriteBaseArray 
var spriteShuffledArray = []
var startingSprite
var currentSprite
var currentSpriteI: int = 0
var nextUp
var nextUpI: int = 1
var pastSprite
var state = "menu" # menu, game, cut(fade)?
var walkingCount = 0
var walked = false
var walking = false
var personState = "walking" #walking, standing, leaving
var startScale = Vector2(25, 25)
var targetScale = Vector2(30, 30)
var longWalk: int = 300
var shortWalk: int = 180
var walkArray
var walkLength
var walkBuff: int = 20
var rejected: bool = true
var leavingCount: int = 150
var leaving = false
var min_value: int = 0
var someoneLeaving = false
var hiddenScale
var max_value = 550
var leaveReset = 250
var standing
var peopleCount
var fps: int = 35
var menuCounter: int = 0
var menuKids
var ui_kids
var transitionIncreasing: bool = true
var transitionFinished: bool = false
var transitionHalved: bool = false
var transitionStarted: bool = false
var transitionBuffer: int = 60
var pulseIncreasing: bool = true
var currentPulse = "red"
var capacity: int = 0
var maxCapacity: int = 15
var shiftLength: int = 10000 # INCREASE AS MORE PEOPLE ARE ADDED
var endingCounter: int = 0
var endingKids
var goodCapacity: bool = false
var score: int = 0 # 0 = b, -1 = b-, 1 = b+...
var letterScore = "B"
var pop: int = 2
var playedSound = false
var transitionCounter: int = 0
var transitionKids
var paused = true
var transitionUnhidden = false
var crowdNoise = false
var noiseLevel: float = 0.0
var effectsKidsPos
var effectsKidsNeg
var effectStarted = false
var effectIncreasing = true
var effectGoing = false
var popChanged = false
var oddsSelected = false
var effectOdds

var bg_music: AudioStreamPlayer = AudioStreamPlayer.new()
var bg_talking: AudioStreamPlayer = AudioStreamPlayer.new()
var sound_effect : AudioStreamPlayer = AudioStreamPlayer.new()

# scale from 20 to 30
# starting place sprites at 555, 315
# will need to change z index

func _ready() -> void:
	bg_music.stream = load("res://environment/586173__devern__distant-dance-club.mp3")
	bg_music.autoplay = true
	add_child(bg_music)
	add_child(bg_talking)
	add_child(sound_effect)
	
	effectsKidsPos = $effects/positive.get_children()
	effectsKidsNeg = $effects/negative.get_children()
	transitionKids = $trans.get_children()
	menuKids = $menu.get_children()
	endingKids = $ending.get_children()
	
	$transition.modulate.a = 0
	$menu/menuBar.value
	$ui/rejectionBar.value = 600
	$menu/title2.visible = false
	walkLength = shortWalk
	walkArray = ["long","long","long","short"]
	spriteBaseArray = $people.get_children()
	for item in endingKids:
		item.visible = false
	for thing in transitionKids:
		thing.visible = false
	for effect in effectsKidsPos:
		effect.modulate.a = 0
	for effect in effectsKidsNeg:
		effect.modulate.a = 0
	#menu viz ##################################################
	$sunrise.visible = false
	$background.visible = false
	for person in spriteBaseArray:
		person.visible = false
	ui_kids = $ui.get_children()
	for kid in ui_kids:
		kid.visible = false
	# ######################################################

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == "menu":
		if spriteBaseArray.size() == spriteShuffledArray.size():
			currentSprite = spriteShuffledArray[currentSpriteI]
			currentSprite.get_node("Sprite2D").scale = startScale
			#currentSprite.get_node("Sprite2D").visible = true
			nextUp = spriteShuffledArray[nextUpI]
			# nextUp.get_node("Sprite2D").scale = startScale

			for i in range(spriteShuffledArray.size()):
				spriteShuffledArray[i].z_index = spriteShuffledArray.size() - i - 1
			# THEN MOVE ON
			
			menuManager()
		else:
			#RUN SHUFFLE AGAIN UNTIL READY TO START
			shuffle()
	elif state == "game":
		if not crowdNoise:
			var sound = load ("res://environment/crowd.wav")
			bg_talking.stream = sound
			bg_talking.volume_db = noiseLevel
			bg_talking.play()
			crowdNoise = true
		if noiseLevel >= 10:
			pass
		else:
			noiseLevel += 0.1
			bg_talking.volume_db = noiseLevel
		if pop == 2:
			$ui/pop.text = "popularity: ++"
			$ending/popReview.text = "average popularity"
		elif pop == 3:
			$ui/pop.text = "popularity: +++"
			$ending/popReview.text = "good popularity"
		elif pop >= 4:
			$ui/pop.text = "popularity: ++++"
			$ending/popReview.text = "high popularity"
		elif pop == 1:
			$ui/pop.text = "popularity: +"
			$ending/popReview.text = "low popularity"
		elif pop <= 0:
			$ui/pop.text = "popularity: -"
			$ending/popReview.text = "terrible popularity"
		if shiftLength <= 0:
			if personState == "standing": # only end if standing, meaning last person finished walking (smoother)
				state = "ending"
		$ui/capacity.text = "capacity: "+str(capacity)+"/"+str(maxCapacity)
		# FIGURE OUT CLEAN UP
		#for person in spriteShuffledArray:
			#if person.position.x >= 1300 or person.position.x <= -500:
				#$people.get_node(person).queue_free()
		if personState == "walking":
			hiddenScale = nextUp.get_node("Sprite2D").scale
			nextUp.get_node("Sprite2D").scale = hiddenScale.lerp(startScale, 0.01)
		gameManager()
		envManager()
		shiftLength -= 1
	elif state == "transition":
		transitionManager()
	elif state == "ending":
		if capacity > maxCapacity:
			$ending/capReview.text = "- over capacity"
		elif maxCapacity - capacity <= 5:
			$ending/capReview.text = "+ healthy capacity"
			goodCapacity = true
		else:
			$ending/capReview.text = "- near empty club"
		if score == 0:
			letterScore = "B"
		elif score == -1:
			letterScore = "B-"
		elif score == -2:
			letterScore = "C+"
		elif score == 1:
			letterScore = "B+"
		elif score == 2:
			letterScore = "A"
		$ending/rating.text = letterScore
		endingManager()


func shuffle():
	var size = spriteBaseArray.size()
	var rng = RandomNumberGenerator.new()
	var i = rng.randi_range(0, size-1) # might need to subtract 1?
	if spriteBaseArray[i] in spriteShuffledArray:
		pass
	else:
		spriteShuffledArray.append(spriteBaseArray[i])
		
func gameManager():
	# size up based on animation length
	if personState == "walking":
		if walkingCount <= walkLength:
			if walking == false:
				currentSprite.get_node("AnimationPlayer").play("walk")
				nextUp.get_node("AnimationPlayer").play("walk")
				walking = true
			else: # if walking == true
				var t = float(walkingCount) / float(walkLength)
				currentSprite.get_node("Sprite2D").scale = startScale.lerp(targetScale, t)
				walkingCount += 2
		else: # if secondCount not over:
			personState = "standing"
	elif personState == "standing":
		if $ui/rejectionBar.value <= min_value:
			var rng = RandomNumberGenerator.new()
			var chance = rng.randi_range(1,3) # 25% chance of messing w pop?
			if chance == 1:
				pop -= 1
			currentSprite.reaction("right")
			pastSprite = currentSprite
			currentSpriteI += 1
			nextUpI += 1
			currentSprite = spriteShuffledArray[currentSpriteI]
			nextUp = spriteShuffledArray[nextUpI]
			#RESET
			walkingCount = 0
			standing = false
			walking = false
			$ui/rejectionBar.value = max_value
			effectGoing = true
			personState = "leaving" # JUST ONE WAY OF TRIGGERING LEAVING
		else: # still decision time
			$ui/rejectionBar.value -= 2
			if Input.is_action_pressed("press"):
				var rng = RandomNumberGenerator.new()
				var chance = rng.randi_range(1,3) # 25% chance of messing w pop?
				if chance == 1:
					pop += 1
				currentSprite.reaction("left")
				capacity += 1
				pastSprite = currentSprite
				currentSpriteI += 1
				nextUpI += 1
				currentSprite = spriteShuffledArray[currentSpriteI]
				nextUp = spriteShuffledArray[nextUpI]
				rejected = false
				#RESET
				walkingCount = 0
				standing = false
				walking = false
				$ui/rejectionBar.value = max_value
				effectGoing = true
				personState = "leaving"

			#recheck walk length for next
			var random_index = randi() % walkArray.size()
			var random_item = walkArray[random_index]
			if random_item == "long":
				walkLength = longWalk
			else:
				walkLength = shortWalk
			currentSprite.get_node("AnimationPlayer").play("stand")
			nextUp.get_node("AnimationPlayer").play("stand")
			#before trigger leaving, make nextUp visible
	elif personState == "leaving": # RESET ALL VArIABLES AT SOME POINT
		if leavingCount <= 0:
			personState = "walking"
			leavingCount = 150
		else:
			leavingCount -= 1
		someoneLeaving = true
	leave()
		
func leave():
	if someoneLeaving:
		if leaveReset <= 0:
			leaving = false
			someoneLeaving = false
			leaveReset = 250
			rejected = true
		else:
			leaveReset -= 1
			if rejected:
				if leaving == false:
					pastSprite.get_node("AnimationPlayer").play("right")
					leaving = true
				pastSprite.position.x += 4
			else:
				if leaving == false:
					pastSprite.get_node("AnimationPlayer").play("left")
					leaving = true
				pastSprite.position.x -= 4
	else:
		pass

func menuManager():
		
	 # reveal hidden elements during SWITCH to game
	if menuCounter % fps == 0:
		print("in if state")
		if $menu/title1.visible == true:
			$menu/title1.visible = false
			$menu/title2.visible = true
		else:
			$menu/title2.visible = false
			$menu/title1.visible = true
	menuCounter += 1
	if Input.is_action_pressed("press"):
		#if menuCounter % pressBuffer == 0:
		$menu/menuBar.value += 2
		
	if $menu/menuBar.value == max_value:
		state = "transition"
		
func envManager():
	$sunrise.position.y -= 0.09 #adjust once all people are added
	if currentPulse == "red":
		$ui/pulse1.modulate.a = 0
		if pulseIncreasing:
			if $ui/pulse2.modulate.a >= 1:
				pulseIncreasing = false
			else:
				$ui/pulse2.modulate.a += 0.05
		else:
			if $ui/pulse2.modulate.a <= 0:
				currentPulse = "pink"
				pulseIncreasing = true
			else:
				$ui/pulse2.modulate.a -= 0.05
	if currentPulse == "pink":
		$ui/pulse2.modulate.a = 0
		if pulseIncreasing:
			if $ui/pulse1.modulate.a >= 1:
				pulseIncreasing = false
			else:
				$ui/pulse1.modulate.a += 0.05
		else:
			if $ui/pulse1.modulate.a <= 0:
				currentPulse = "red"
				pulseIncreasing = true
			else:
				$ui/pulse1.modulate.a -= 0.05
	
func transitionManager():
	if transitionFinished:
		state = "game"
	if transitionHalved:
		if not transitionUnhidden:
			for thing in transitionKids:
				thing.visible = true
				thing.modulate.a = 0
			transitionUnhidden = true
		if transitionCounter >= 60 and transitionCounter < 700:
			$trans/instruction0.modulate.a += 0.007
		if transitionCounter >= 180 and transitionCounter < 700:
			$trans/instruction1.modulate.a += 0.007
		if transitionCounter >= 300 and transitionCounter < 700:
			$trans/instruction2.modulate.a += 0.007
		if transitionCounter >= 420 and transitionCounter < 700:
			$trans/instruction3.modulate.a += 0.007
		if transitionCounter >= 540 and transitionCounter < 700:
			$trans/instruction4.modulate.a += 0.007
		if transitionCounter >= 700:
			for kid in transitionKids:
				kid.modulate.a -= 0.007
			if $trans/instruction0.modulate.a <= 0:
				paused = false
				for kid in menuKids:
					kid.visible = false
				$sunrise.visible = true
				$background.visible = true
				for person in spriteBaseArray:
					person.visible = true
				for kid in ui_kids:
					kid.visible = true	
				$ui/pulse2.modulate.a = 0
				$ui/pulse1.modulate.a = 0
		transitionCounter += 1
	if $transition.modulate.a <= 0:
		if transitionStarted == false:
			$transition.modulate.a += 0.01
			transitionStarted = true
		else:
			if transitionBuffer <= 0:
				transitionFinished = true	
			else:
				transitionBuffer -= 1
				envManager() #start sunrise and flashing early
	elif $transition.modulate.a >= 1:
		transitionIncreasing = false
		transitionHalved = true
	if transitionIncreasing:
		$transition.modulate.a += 0.01
	elif not paused:
		$transition.modulate.a -= 0.01
		for kid in transitionKids:
			kid.modulate.a -= 0.01
		
func endingManager():
	
	for kid in ui_kids:
		kid.visible = false
	$ending/club.visible = true
	if endingCounter == 60:
		$ending/closed.visible = true
	elif endingCounter >= 240:
		currentSprite.position.x += 4
		currentSprite.get_node("AnimationPlayer").play("right")
		nextUp.position.x += 5
		nextUp.get_node("AnimationPlayer").play("right")
		for person in spriteBaseArray:
			# also move thru array to vary walking speeds
			person.spriteLeave()
			person.get_node("AnimationPlayer").play("right")
			person.get_node("Sprite2D").scale = startScale
		currentSprite.get_node("Sprite2D").scale = targetScale
	if endingCounter == 360:
		$ending/performance.visible = true
		$ending/rating.visible = true
	elif endingCounter == 540:
		$ending/popReview.visible = true
		if pop >= 3:
			score += 1
		elif pop <= 1:
			score -= 1
	elif endingCounter == 720:
		if goodCapacity:
			score += 1
		else:
			score -= 1
		$ending/capReview.visible = true #CONNECT THESE TO ACTUAL RESULTS and make it change grade
	if endingCounter > 720:
		$ending/capReview.modulate.a -= .007 # make higher/lower?	
	if endingCounter > 540:
		$ending/popReview.modulate.a -= .007 # make higher/lower?
	if endingCounter > 900:
		if Input.is_action_pressed("press"):
			get_tree().change_scene_to_file("res://main.tscn")
		$ending/replayText.visible = true
	endingCounter += 1

#func popCalc1():
	#if effectGoing:
		#if not oddsSelected:
			#var rng = RandomNumberGenerator.new()
			#effectOdds = rng.randi_range(1,1) # 25% chance of messing w pop?
			#print(effectOdds)
			#oddsSelected = true
		#if not rejected:
			#print(rejected)
			#if effectOdds == 1:
				#print("in i==1")
				#if $effects/positive.get_node("pos").modulate.a <= 0:
					#if effectStarted == true:
						#effectStarted = false
						#effectGoing = false 
						#popChanged = false
						#oddsSelected = false
					#else: # not started
						#effectStarted = true
						#for effect in effectsKidsPos:
							#effect.modulate.a += .1
				#if effectIncreasing:
					#if $effects/positive.get_node("pos").modulate.a >= 1:
						#effectIncreasing = false
					#else:
						#for effect in effectsKidsPos:
							#effect.modulate.a += .1
				#else: #decreasing
					#if $effects/positive.get_node("pos").modulate.a <= 0:
						#pass
					#else:
						#for effect in effectsKidsPos:
							#effect.modulate.a -= .05
				#if popChanged == false:
					#pop += 1
					#popChanged = true
		#else: #if rejected
			#if effectOdds == 1:
				#if $effects/negative.get_node("neg").modulate.a <= 0:
					#if effectStarted == true:
						#effectStarted = false
						#effectGoing = false 
						#popChanged = false
						#oddsSelected = false
					#else: # not started
						#effectStarted = true
						#for effect in effectsKidsNeg:
							#effect.modulate.a += .1
				#if effectIncreasing:
					#if $effects/negative.get_node("neg").modulate.a >= 1:
						#effectIncreasing = false
					#else:
						#for effect in effectsKidsNeg:
							#effect.modulate.a += .1
				#else: #decreasing
					#if $effects/negative.get_node("neg").modulate.a <= 0:
						#pass
					#else:
						#for effect in effectsKidsNeg:
							#effect.modulate.a -= .05
				#if popChanged == false:
					#pop -= 1
					#popChanged = true
#func popCalc():
	#if effectGoing:
		## Select random effect odds if not done already
		#if not oddsSelected:
			#var rng = RandomNumberGenerator.new()
			#effectOdds = rng.randi_range(1, 1) # 25% chance
			#print(effectOdds)
			#oddsSelected = true
#
		## Determine whether to apply positive or negative effects
		#var effect_node = $effects/negative.get_node("neg") if rejected else $effects/positive.get_node("pos")
		#var effectsKids = effectsKidsNeg if rejected else effectsKidsPos
		#var popChange = -1 if rejected else 1
#
		## Process effect if the chance (effectOdds) is triggered
		#if effectOdds == 1:
			## Start or reset effect
			#if effect_node.modulate.a <= 0:
				#if effectStarted:
					## End the effect
					#effectStarted = false
					#effectGoing = false
					#oddsSelected = false
				#else:
					## Start the effect
					#effectStarted = true
					#for effect in effectsKids:
						#effect.modulate.a += 0.1
					#pop += popChange  # Apply population change only once
					#popChanged = true
#
			## Control effect modulation
			#if effectIncreasing:
				#if effect_node.modulate.a >= 1:
					#effectIncreasing = false
				#else:
					#for effect in effectsKids:
						#effect.modulate.a += 0.1
			#else: # Decreasing effect
				#if effect_node.modulate.a > 0:
					#for effect in effectsKids:
						#effect.modulate.a -= 0.05
