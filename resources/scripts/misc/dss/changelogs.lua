DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.8.0", [[
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.7.1", [[
- General:
-- Fixed Spiked rocks damage 
negator giving errors
-- Updated ImGui.lua

- Tainted Edith:
-- Movement:
--- Removed T. Edith's 
redirect reset
--- Removed Redirection slide
--- Removed Parry slide
--- Removed single tap stop slide
--- Removed Hopdash cooldown
--- Removed Rock 
destroy charge limit
--- Reduced Arrow speed 
when redirecting the hopdash
--- Reduced T. Edith's 
minimum invulnerability 
damage charge (30% > 20%)
--- Increased Hopdash 
land damage
--- Tweaked Hopdash 
land damage formula

-- Parry:
--- Increased Perfect 
Parry Radius (22 > 28)
--- Increased Imprecise 
Parry i-frames (20 > 25)
--- Removed failed parry 
hopdash charge reduction
--- Increased imprecise 
parry hopdash bonus (5% > 15%)
--- Increased perfect parry 
hopdash bonus (20% > 30%)
--- Now Imprecise parries 
applies jump recoil to enemies
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.7.0a", [[
- Fixed Parry flash data not being 
properly initialized (looks like this 
also fixed a memory leak lol)
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.7.0", [[
- General:
-- Removed Suplex from pools when 
playing with any Edith 
(will be re-added)
-- Now both Ediths will get 
flight when going to a 
crawlspace room

- Tainted Edith:
-- Added a custom portrait 
sprite when playing Grudge challenge
-- Updated Character Selection sprite
-- Now her costume is 
managed by a null item
-- Now her damage multipler 
is managed by a null item
-- Movement Rework:
--- Now Tainted Edith HopDash 
will behave different depending
on how many frames you keep the button
---- 1-4 frames: Tainted Edith 
will stop her movement and reset 
the hopdash charge, 
Edith will flash in blue
---- 5-19 frames: Tainted Edith 
will stop and spawn her arrow, 
allowing her to redirect the 
movement without losing charge, 
Edith will flash in light grey
---- 20+ frames: The redirect 
will be cancelled and Tainted 
Edith charge will be restarted, 
Edith will flash in black
--- Tweaked Hopdash speed formula 
to be parabolic (less charge gives 
more, 50% charge gives 75% of speed
, and 80% charge gives 96% of speed)
--- Now Tainted Edith can go 
trough rooms without stopping 
her movement
--- Now Tainted Edith can destroy 
rocks at 50% or more HopDash charge
--- Stopping a hopdash with the 
parry button will instantly 
perform a parry land
--- Increased HopDash 
speed base (8 > 8.5)
--- Reduced GrudgeDash 
speed base (10 > 9)
--- Removed GrudgeDash 
speed multiplier
--- Fixed GrudgeDash 
collision behaving weird
-- Parry:
--- Increased Perfect Parry 
Radius (18 > 22)
--- Increased Perfect parry 
i-frames (25 > 30)
--- Increased Imprecise parry 
i-frames (15 > 20)
--- Increased parry cooldown:
---- Perfect parry: 10 > 12
---- Birthcake perfect parry: 8 > 10
--- Parry cooldown will be reduced 
with HopDash static charge 
(up to 8 frames at 100%)
--- Now HopDash charge increases 
i-Frames (1 frame every 20%, 
max 10 frames with Birthright)
--- Added a 6 frames 
input buffer for the parry
--- Added a perfect parry 
flash (configurable in ImGui menu)
--- Added Hawk Tuah 
perfect parry sound effect
--- Now Bombs can be parried 
(parried bombs increases 
their damage by x1.25)

- Edith:
-- Added a custom portrait 
sprite when playing 
Vestige challenge
-- Now her costume is 
managed by a null item
-- Now her damage multipler 
is managed by a null item
-- Updated Character Selection sprite
-- Added Edith's Hood stomp synergy
-- Added Pepper's stomp synergy 
birthright improvement
-- Now Edith's ImGui Options 
wont appear when she's locked
-- Reduced Edith's water 
current drag strenght
-- Increased Edith's target 
movement speed (Resizer 4 > 4.5)

- Items:
-- Now Divine Retribution grants 
a full soul heart when 
having Car Battery
-- Tweaked Sal:
--- Reduced frames between 
salt creep spawn (15 > 10)
--- Now salt creep deals 
damage (0.5 per tick)
--- Reduced salt creep 
duration (3 secs > 2 secs)
-- Tweaked Molten Core:
--- Increased burn 
radius (60 > 80)
--- Increased damage 
addition (1 > 1.25)
--- Increased killing's 
fire jet size (scaled by 2)
-- Tweaked Edith's Hood:
--- Changed cooldown Update 
Callback (POST_PLAYER_UPDATE > 
POST_PEFFECT_UPDATE, this 
should make the cooldown 
be reduced slower)
Reduced stomp cooldown (90 > 60)
Now its Damage multiplier 
is added through XML
--- Increased stomp Damage 
(increased player's damage 
mult, 0.75 > 1.5)
--- Now its Damage multiplier 
is added through XML
--- Increased stomp 
radius (30 > 40)
--- Increased stomp 
Knockback (5, 15)
--- Increased stomp 
i-frames (20 > 30)
--- Reduced Edith's Hood cooldown 
on clear rooms (10 frames)
-- Tweaked Gilded Stone:
--- Now it grants 1 luck
--- Reduced Penny chance 
reward (75% > 70%)
--- Increased Dime chance
reward (5% > 10%)
-- Reworked Sulfuric Fire:
--- Now using it nearby enemies 
will grant a fading damage up 
(2 for 4 seconds, depends on 
the quantity of hit enemies)
--- Now it pushes enemies on use
--- Killing an enemy while having 
the damage up will spawn 
brimstone ball on its position
--- Added a damage mult when 
using it with Judas while 
having birthright (x1.5)
--- Added a damage mult when 
using it while having 
Car Battery (x1.25)
--- Added a screen shake on use
-- Reworked Chunk of Basalt:
--- Now Isaac will flicker 
when the dash is ready
--- Now colliding with an enemy 
while dashing will create a ring 
of shockwaves around the hit position, 
dealing player's damage x2
--- Now Colliding with a grid entity 
will create a ring of shockwaves 
around the hit position, 
dealing player's damage x2
--- Enemies near to the collided 
enemy will get 75% of the 
collision damage
--- Increased dash damage divider (4 > 5)
-- Reworked Spices Mix:
--- Updated Sprite
--- Now spices can be switched 
by pressing the Drop key
--- Now the spice info flavor text 
is displayed when changing 
spices or pressing the Map button
--- Now a spice jar is rendered 
Above the item's sprite
--- Moved all spices 
(status effects in general) 
to their own scripts
--- Reworked the following 
spice effects:
---- Oregano:
----- Now enemies spawns 
oregano creep that slows enemies
----- Now enemies takes 
damage over time
---- Pepper:
----- Now Pepper creep is spawned
on killing a peppered enemy
----- Now Sneezes pushes 
and damages enemies
----- Now Sneezes have a sound effect
----- Added an sneeze sound effect
---- Cinnamon:
----- Every 20 frames the enemy will 
cough, pushing enemies and leaving 
a cinnamon dust cloud for 5 seconds
----- Enemies inside this cloud 
will get 3 damage every 15 frames

- Trinkets
-- Reworked Burnt Salt:
--- Now every third shot tear 
will be a burnt salt tear
--- Hitting an enemy with a burnt 
salt tear will apply Cinder status effect
--- Killing an enemy with Cinder status 
effect will spawn a circle 
of cinder creep around it
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.6.3", [[
- Reduced Edith's jump 
base cooldown frames (18 > 15)

- Tweaked Edith's stomp 
cooldown manager function
-- Now cooldown should be 
reduced less on high movement 
speed (for reference, 2.0 speed 
sets cooldown to 8 frames)

- Added Ludovico stomp synergy

- Fixed Terra's stomp synergy's 
shockwaves destroying every enemy

- Tweaked Terra's stomp synergy
-- Increased shockwaves' damage
-- Increased distance between 
shockwave rings

- Increased Cindered enemy 
received damage from 
parry mult (x1.2 > x1.25)
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.6.2", [[
- Fixed Edith being able 
to destroy doors

- Fixed T. Edith's arrow not 
having its grudge design 
in Grudge challenge

- Potentially fixed an error 
when imprecise parrying a troll bomb

- Added an extra check to 
slot land manger function

- Added Effigy EID description

- Added Chunk of basalt EID description

- Added Mexico's target design
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.6.1", [[
- Fixed Geode not triggering 
its killing enemy effect

- Fixed Soul of Edith 
not working at all

- Replaced Divine 
Wrath's sprite

- Now salted enemies 
drop salt gibs on death

- Now Mod's data holder's 
clear data function 
should run earlier

- Improved Chocolate Milk 
stomp/parry synergy's scripts
- Improved Salt Rocks' 
gamefeel use

- Increased jack of clubs' 
explosing chance (40% > 60%)

- Re-added Gnawed Leaf 
to pools when playing with Edith

- Added Edith's Gnawed 
leaf interaction
-- Stomp's damage will 
get a x1.5 damage mult
-- Edith's Damage will be 
much slower than usual
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.6.0", [[
- Fixed T.Edith's arrow's 
grudge design changing 
its rotation

- Fixed T. Edith's grudge's 
dash not dealing damage 
consistently

- Fixed Edith's stomp neptunus 
synergy not working at all

- Fixed Tainted Edith not 
interacting correctly 
with white fireplaces

- Potentially fixed Edith's 
arrow moving the camera in Beast fight

- Potentially fixed T. Edith's 
grudge collision with enemies 
being weird

- Added more checks to 
T.Edith's Stop hops function

- Added Edith's special land 
radius for Slots and Pickups

- Added T. Edith's special land 
radius for Slots and Pickups

- Added Lost contact stomp synergy

- Added Bird's Eye/Ghost Pepper's 
parry/stomp synergy

- Added Little Horn's 
parry/stomp synergy

- Improved Edith's flight 
interaction

- Improved costumes system

- Improved Edith's stomp 
grid destruction

- Increased Edith's defensive 
stomp frames window (15 > 18)

- Salted enemy's death effect 
nullification will only happen 
when killing with a stomp

- Salted enemy's death effect 
nullification will only happen 
with non-boss enemies

- Now Edith will be less pushed 
by water currents

- Now Edith will only swap 
active slots when jumping

- Now Edith can drop trinkets 
when pressing the drop button 
in jump cooldown

- Now Tainted Edith can destroy 
fireplaces in Grudge challenge

- Now T. Edith's grudge dash 
screenshake can be disabled with 
screenshake option form ImGui Menu

- Now T.Edith parry will 
apply jump recoil to enemies

- Now Edith/T.Edith can 
destroy movable TNT

- Spices Mix changes:
-- Now Spices Mix has 
a cooldown (5 seconds)
-- Added a flavor text 
for everytime the Spices 
Mix is used
--- This flavor text has 
the name of the spice 
and its effect in enemies

- Tainted Edith mini-rework:
-- Now Cinder enemies will 
receive x1.2 times more 
damage from parries
-- Removed Cinder creep 
applying cinder status effect
-- T. Edith won't spawn 
cinder creep on Hop land
-- T. Edith hop land now 
applies cinder status effect 
(max 4 seconds, depends on 
HopDash move charge)
-- Imprecise Parry cinder status 
effects duration has a 
max duration of 12 seconds
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.5.1a", [[
- Fixed Edith being unable 
to open doors with keys
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.5.1", [[
- Fixed non-enemy entities 
setting on fire from T. Edith's 
hop lands with birthright

- Fixed T.Edith not stoping 
her hops when colliding with a block
- Fixed T.Edith not breaking 
rocks when having flight

- Fixed T.Edith's chargebars 
not rendering correctly 
in mirror dimension

- Fixed T.Edith constantly overriding 
her color while moving 
her arrow to a closed door

- Now Tainted Edith's hop 
cooldown won't restart 
on entering a new room

- Now Landing from a dash change 
direction will trigger 
a hop land interaction

- Now Tained Edith can 
destroy TNT with her hopdash

- Included T.Edith's 
jupiter Synergy's script

- Added T.Edith's 
multishot parry synergy
-- Works exactly the same 
as Edith's multishot stomp synergy
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.5.0", [[
- Tainted Edith rework:
-- Increased Perfect 
Parry radius (12 > 18)
-- Increased Imprecise 
Parry radius (35 > 45)
-- Increased Parry 
Jump speed (now it lands faster)
-- Added an specific parry 
radius for tear parry, 
making tear parry easier
-- Reduced Tainted Edith's 
hopdash and grudgedash 
speed base 
(hopdash: 10 > 8, grudgedash: 12 > 9)
-- Now Edith can break 
rocks at a hop/grudgedash charge
of 85% or more
-- Now there's a 8 frames 
cooldown for tainted edith's 
hop (and grudge dash)
-- Changed how hop 
cinder creep is spawned
--- Now its spawn chance 
depends on hop charge 
(50% chance at 100% charge)
--- Now the creep quantity 
depends on hop charge (8 at 100%)
--- Now the distance spawn 
depends on hop charge 
(30 units at 100%)

- Fixed all kind entities 
getting burn effect when 
Tainted Edith with birthright 
lands near them

- Potentially fixed 
Edith and Tainted Edith 
being unable to interact 
with spikes in devil rooms

- Fixed Tainted Edith 
getting pickup duplicates

- Reimplemented Stomped 
enemies jump recoil
-- This should fix that 
weird issue where enemies 
suddenly loses their AI
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.4.0", [[
- Fixed Edith being unable 
to go Mother's fight

- Fixed Edith's target teleporting 
Edith to specific points when 
going trough them in best fight

- Fixed Tainted Edith unlocks 
in general (im really sorry for that)

- Fixed Costumes not working at all

- Fixed an issue with Helpers.BoostTear()

- Fixed a softlock in 
rotgut's second phase

- Fixed Grudge Tainted Edith not 
being able to dash when colliding 
with a wall

- Added Jupiter's stomp synergy

- Added Jupiter's perfect parry synergy

- Removed Montezuma's Revenge 
from pools when playing with Edith

- Removed an already unused
test from Data Holder script

- Now massive enemies can be pushed

- Now blood clots will follow 
Edith when she jumps
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.3.0", [[
- Fixed Edith and Tainted 
Edith losing their costumes
when using D4 or D100

- Fixed Edith getting damage 
from blood donation machines, 
devil beggars and confessionals 
when they're destroyed

- Fixed Edith being unable to go 
to womb, corpse, blue womb, and such

- Fixed Edith not moving to her target
when loading the mod with 
luamod console command

- Fixed an issue were ImGui 
options weren't properly updated

- Fixed Tainted Edith not 
unlocking her Greedier unlock

- Improved Edith's grid 
teleporter interaction

- Removed a trailing char in items.xml

- Removed Gnawed Leaf and 
Night Light from item pools 
when playing with Edith

- Properly added Spices Mix unlock

- Now Edith can't use 
Kamikaze while jumping

- Now players who doesn't have 
Salt Heart won't get 
salted status effect

- Now Tainted Edith can 
hopdsah if the charge 
is below 10%

- Now custom action key 
from ImGui's menu works

-- Now it allows to set a 
custom action button rather than Z

- Now Edith's Salt Shaker 
can be a pocket active 
(option added to Imgui Menu)

- Now Tainted Edith's trail options works

- Reworked Multishot stomp synergy
-- Now Edith will jump once, 
but stomp will deal damage 
multiple times
-- Increased Stomp's damage 
reduction from multishot
-- Enemy's damaged sound effect's 
volume will be higher the 
more times is dealt damage
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.2.0", [[
- Fixed Salt rocks not 
triggering salted 
effect to enemies


- Fixed Edith not being
able to go to void 
trough Mega Satan's portal

- Fixed bomb stomp consuming
bombs when having 
dr fetus or epic fetus

- Fixed Salt creep being able
to use a nil value to asign 
salted effect duration

- Fixed Edith being unable 
to play on Confessionals

- Fixed Tainted Edith's body 
dissapearing when having flight

- Fixed Edith's Hood 
not triggering its Landing effect

- Fixed Edith being unable 
to trigger enemy waves in 
challenge rooms when 
stomping stone chests

- Added The Future support

- Added EID support

- Added ingame changelogs

- Increased Edith's 
defensive stomp window 
frames (9 > 15)

- Now Defensive stomp frame 
window can be 
configured in ImGui Menu

- Now Pepper creep wont 
spawn far away from 
peppered entity

- Now Tainted Edith can 
consistently interact with 
blood donation machines, 
devil beggars and confessionals

- Removed a unused item entry

- Removed leftover prints
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.1.0", [[
- Reimplemented mod's 
data structure (big change 
that justified going to 1.1.0)

- (Hopefully) Fixed a rare 
and hard to reproduce error 
where Tainted Edith was 
unable to spawn her arrow

- Now Tainted Edith's 
hop-parry params are properly
reset when starting a new run

- Now Edith's jump-stomp params 
are properly reset when 
starting a new run

- Fixed Edith triggering beggars 
and donation machines everytime

- Fixed Edith not getting damage 
when stomping devil beggars 
and blood donation machines

- Fixed a potential error regarding
Tainted Edith trying to hop at nil charge

- Now target door manager will
let you go trough open doors
in uncleared rooms

- Fixed Edith being unable 
to go to black markets

- Fixed Edith going to 
error room in Rotgut's maggot phase
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.0.2", [[
- Removed a leftover 
console print when 
stomping slots and beggars

- Fixed Edith's Marked interactions

- Fixed Edith's 
lump of coal interaction 
not working at all

- Now T.Edith's arrow 
will always have 
grudge design when
playing Grudge challenge

- Now all stomp and parry 
synergies' functions are 
anonymous functions

- Fixed Edith shooting 
godhead stomp tears

- Second attempt to fix 
Target doors issue 
(hopefully it works now)]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.0.1", [[
- Fixed Tainted Edith's 
projectile parry not working at all

- Potentially fixed an error that 
doesn't trigger 
effect room transition 
(needs more testing)

- Now Edith won't take 
damage when pitfalling

- Now Tainted Edith has a chance 
to spawn Cinder creep 
when hop-landing 
(only at 100% hop charge)

- Now Edith can 
correctly interact 
with beggars and slots
]]
)

DeadSeaScrollsMenu.AddChangelog("Edith: Rebuilt", "v1.0.0 [Release]", [[
- Initial release
]])