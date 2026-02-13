**testScene.tscn:**

Scène Test (Node2D) # script --> res//scripts/Manager/testManager.gd

|\_\_ Player (CharacterBody2D) # script --> res//scripts/player.gd

|\_\_ dummy (Area2D) # script --> res//scripts/dummy.gd

|\_\_ CanvasLayer # script --> res//scripts/spellBarManager.gd



**player.tscn:**

Player (CharacterBody2D) # script --> res//scripts/player.gd

|\_\_ SpellIndicator (Sprite2D)

|\_\_ PlayerSprite (Sprite2D)

|\_\_ CollisionShape2D

|\_\_ DirectionLine (Line2D)

|\_\_ SpellSpawnPoint (Marker2D)





**spellBar.tscn:**

CanvasLayer # script --> res://scripts/Manager/spellBarManager.gd

|\_\_ RootUI (Node2D)

&nbsp;  |\_\_ MarginContainer

&nbsp;     |\_\_ SpellBar (GridContainer) # script --> res://scripts/spellBar.gd





**spellSlot.tscn:**

SpellSlot # script --> res//scripts/spellSlot.gd

|\_\_ Icon (TextureRect)

|\_\_ KeyLabel (Label)

|\_\_ CooldownOverlay (TextureProgressBar)

|\_\_ CooldownText (Label)



**fireball.tscn:**

Fireball (Area2D) # script --> res//scripts/fireball.gd

|\_\_ Sprite2D

|\_\_ CollisionShape2D

