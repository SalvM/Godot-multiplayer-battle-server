# Godot Multiplayer Battle Server

A simple test project with multiplayer features

## Client
You can find the client repository [here](https://github.com/SalvM/Godot-multiplayer-battle-client)

# Server

### Server.gd
The main file. It starts the server and communicates with the clients.

### Fight.gd
It contains the constants and functions about the fighting system

### StateProcessing.gd
Used to send the world_state to all the clients.
The state is sent 20 times per second.
This value should be the most common in multiplayer games

### AntiCheat.gd
It contains some functions to check if the player is cheating.
One way to do that is to check the time passed between an action and another.
