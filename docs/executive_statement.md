Top-Town twin stick shooter. The player is a ball with three mount points. Left right and top. 

The goal is to explore the vector art landscape and find the three power gems. Once you have all three there's a final location to extract to. 

The game has drop-in multiplayer. Players can either join locally or remotely and they are automatically spawned with basic equipment. The spawn is always near the player and only after the player is out of combat. 

The player's weapons go from a slow shooting pellet weapon to a faster, less accurate machine gun, shotgun, grenades etc. 

The player starts with the basic pellet weapon. They can find pickups across the playfield for the other abilities. And they'll be at least one at each of the gems and extraction point. Holding down the same button that fires that mount point will swap it for that mount point.

The art style is 2D vector art. All the elements are layered a mild depth effect. Individual layers are outlined in a solid bright color with a black fill. So that upper layers cover bottom layers.

We need to have debugging modes in order to render all of the animations for all of the characters : the player, the enemies, and all of the obstacles.

The game engine uses Godot because it can Target multiple platforms. The main platform we want to Target is web with keyboard and gamepad support. 

The key controls are: directional movement, directional aiming, and using each of the amount points. There may be an optional control to use all three Mount points simultaneously. On gamepad the directional should be left stick and right stick respectively.

Friendly fire should split the damage between both the Target and the player.

Mount points should have multiple different purposes including offense, defense, and utility. In addition to the weapons, we should have things like Shields, healing, ammo dispenser, or even things like a jump pack to get over walls.

We should just have a global game that all players in the world join. We expect small player numbers. If a server is required, let's look at what it takes to run one easily. Let's make sure we document the process for starting the server in the readme.

To start the game, you should enter your player name. Then you should be immediately dropped into the global game. If no players are playing at the time it starts at the beginning. 

The playfield contains various obstacles like rocks or trees. They're rendered in the same art style. The ground is tiled with hexagons. All ground hexagons are the same color if they're at the same height. One unit of height will block the player's view. It takes eight steps of a height and order to raise one unit of height. A player can step up over two steps.

Anywhere that a wall between two adjacent hexagons is greater than one unit of height. The difference is just shown as a solid line along the edge. 

When we generate the map we should aim for large flat areas some areas at distinctly different unit heights. This will create natural choke points.

The play field should be finite size but take at least 2 or 3 minutes to walk across. The edge of the playfield should be a solid wall that is uncrossable. The spawn, the three gems and the extraction point should all be a minimum distance from each other. They should also all be reachable. 

Maps should be randomly generated for a large enough hexagonal grid to meet the playfield size requirements. All of the rules between adjacent grid squares should apply. 

The playfield will also contain clusters of enemies. The distribution of each enemy will depend on the type. With some types appearing in clusters. While somr are always solo.

The basic glass of enemy varies in its hit points, number of Mount points, and it's AI behaviors. There should be clearly themed tiers of enemies with the easiest being gray themed. Other than those, the enemy color scheme should be unique each round. So when the player encounters enemies of a certain color, they are unsure about their abilities.

The user interface should use complementary colors of light and dark to render a vector style user interface. We need to cover the primary players stats like hit points, what each of their Mount points contains and the status, like reloading progress of each. Each. When there are other players in the game, we should also reflect them on the different corners of the screen. As players join and leave. Each should reflect the color scheme of the given player that the player picked.