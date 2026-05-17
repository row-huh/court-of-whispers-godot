extends Control

@onready var day_label: Label = %DayLabel
@onready var turns_label: Label = %TurnsLabel
@onready var proof_bar: ProgressBar = %ProofBar
@onready var suspicion_bar: ProgressBar = %SuspicionBar
@onready var commander_trust: ProgressBar = %CommanderTrust
@onready var citizen_trust: ProgressBar = %CitizenTrust
@onready var priest_trust: ProgressBar = %PriestTrust
@onready var priest_fear: ProgressBar = %PriestFear
@onready var quest_label: Label = %QuestLabel


func _ready() -> void:
	GameManager.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	day_label.text = "Day %d / 5" % GameManager.day
	turns_label.text = "Turns: %d" % GameManager.turns_left
	proof_bar.value = GameManager.proof
	suspicion_bar.value = GameManager.suspicion
	commander_trust.value = GameManager.agents["commander"]["trust"]
	citizen_trust.value = GameManager.agents["citizen"]["trust"]
	priest_trust.value = GameManager.agents["priest"]["trust"]
	priest_fear.value = GameManager.agents["priest"]["fear"]

	var quests: Array[String] = []
	if not GameManager.citizen_offered_blackmail:
		quests.append("• Earn Mira's leverage (trust 50+)")
	elif GameManager.priest_spilled_dirt.is_empty():
		quests.append("• Pry secrets from Father Edran")
	elif not GameManager.citizen_endorsed_commander:
		quests.append("• Return dirt to Mira for endorsement")
	else:
		quests.append("• Convince Sir Alaric (trust 80+, endorsement, dirt)")
	quest_label.text = "\n".join(quests)
