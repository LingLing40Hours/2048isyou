# 2048IsYou

## Demo

See [this video](https://youtu.be/ZlPlCk1zcuc) for a quick demo.
The next few sections outline my vision for the completed game. Not everything listed below has been fully implemented.

## Overview 

This game is a combination of 2048 and Baba Is You (and to a lesser degree, Minecraft and Agar.io). The player navigates a tile through a randomly generated grid world consisting of other tiles,
walls, hostiles (hostile tiles trying to trap and merge with the player), chests, and portals which teleport it in and out of puzzle rooms where points can be earned.

## Table of Contents

- [Objects](#objects)
- [Push/Merge Rules](#push/merge-rules)
- [Instructions](#instructions)
- [Code Features](#code-features)
- [Installation](#installation)

# Pathfinding
For Godot-related reasons, the pathfinding algorithms used in 2048IsYou are located [here](https://github.com/LingLing40Hours/GDExtension/tree/master/Pathfinding_Tilemap).

## Objects

A tile is a rounded square with a value belonging to {-2^12, -2^11, ..., -2^0, 0, 2^0, ..., 2^11, 2^12}.
Ordinary tiles are non-player and non-hostile tiles. They can be pushed by both player and hostiles.
Player (dark gray tile) is controlled by you.
- Staying at a low absolute value allows you to travel faster since low absolute values occupy the majority of the world, but at the same time makes you more succeptible to hostiles.
Hostiles (blue/purple tiles) move in the same way as the player, and work together to trap and consume (merge with) it. They lose hostility and transform into ordinary tiles when their value becomes 0. As a result, hostiles cannot change sign.
- Construct tile barriers to protect against hostiles.
- Construct and lure hostiles into traps to "neutralize" them.
Walls (black squares) obstruct everything.
Membranes (dark gray, red, blue squares) obstruct objects that are not the same color as the membrane.
Portals (light green squares) teleport the player in and out of puzzle rooms.
- Completing a puzzle earns points in accordance with the difficulty of the puzzle.
- Each puzzle may have 0 or more savepoints.
Savepoints (yellow squares) save your progress in a puzzle, allowing you to exit back to the main world. All main world progress is saved automatically.
Chests can be pushed and merge with ordinary tiles.
- Positive chests, labeled +, award +(tile value) points upon merging.
- Negative chests, labeled -, award -(tile value) points upon merging.

## Push/Merge Rules

Two tiles can merge if their absolute values are equal and less than 2^12, or at least one tile has value 0. The value of the resulting tile is the sum of their values.
Tile push limit is the maximum number of tiles that the player can simultaneously push. Its default value is 1, and can be increased by spending points.
When the player moves (slides/splits) toward a line of $d$ adjacent tiles and merges at multiple locations are possible, the merge that involves pushing the fewest number of tiles $f$ takes precedence, given that $f < (tile push limit)$.
Only when no such merge exists is the push of $min(d, tile push limit)$ attempted.
If pushing is also not possible, then the move fails.

0s at the end of the line are an exception to the nearest-merge rule, for which being pushed takes precedence over merging (without violating the tile push limit).

## Instructions

Press arrow keys or WASD to move.
Press Ctrl/Cmd + X to toggle movement mode (slide/snap).
- In snap mode, each press slides player by 1 grid step. Holding down the key causes grid steps to repeat and accelerate up to a maximum rate.
- In slide mode, slide distance is not quantized. Player can push, but cannot shift, split, or merge. Adjacent direction keys can be held down to travel diagonally.
Press Ctrl/Cmd + movement to split (player halves its value, creates an ordinary tile duplicate, then slides 1 grid step in split direction).
- Only possible when in snap mode and absolute value is greater than 1.
Press Shift + movement to shift (travel across any straight, unobstructed path in the same amount of time as that of 1 grid step).
- Only possible in snap mode.
Press Ctrl/Cmd + E to return to home screen.
Press Ctrl/Cmd + R to discard savepoints and restart current puzzle.
Press Ctrl/Cmd + T to revert to last savepoint in current puzzle.
Press Ctrl/Cmd + Z to undo last move (slide/split/shift in snap mode, push of ordinary tile in slide mode).
Press Ctrl/Cmd + P to spend points to view current puzzle's official solution.
- Press any key to stop playing the solution.


## Code Features

- Finite state machine to control tile behavior
- Object pooling for fast world generation
- Threading to separate pathfinding, world generation, and main game loop (in progress)
- Simple version control (press Ctrl/Cmd+Z to undo last move)
- Pathfinding
  - BFS
  - AStar
  - IDAStar
  - Jump Point Search (in progress)
  - Zobrist Hashing

## Installation

See latest release.
