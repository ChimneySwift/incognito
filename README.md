# Incognito

Minetest mod that lets you become completely* invisible - even to server status.

Description
===

The issue with the available invisibility Minetest mods is they don't make you _completely_ invisible. Like sure you can't be seen, but what if it was as if you weren't even there, you can be playing the game, but also avoiding all of the annoying players begging for you to give them mese/gold/diamonds all day long.

This mod does just that, when you join with the `incognito` privilage, you are immediately set to incognito mode and given the option to become incognito this session, if you select "no", you lose your incognito status, the join message shows and it's as if you just joined, if you select "yes", you enter incognito mode until you leave the game or run `/incognito`.

So... what does incognito do exactly?

A few things:

- Makes the player and player nametag invisible (without resetting player skin and nametag color)
- Makes you invincible (Just in case of any death message mod)
- Makes you invisible to server status (Your name will no longer show up in the server status client list (viewable at login or via /status))
- Supresses your ability to send public chat messages (Messages and messages sent with /me will be stopped, can't have you leaking the fact you're incognito ;)
- Makes you silent (No footstep noises!)
- Lets you know you're incognito (via a formspec)
- Shows you a warning HUD if there are players nearby (so you don't go placing blocks or anything and blow your cover)

That said, it's not all sunshine and rainbows, Clients are still sent your nametag and player position, so you'll show up in the minimap and .list_players if you're within nametag range, or if the client is using a 0.5.0-dev or above client.

Installing
===

This isn't going to be like any regular mod instalation, we're going to also have to modify a built-in mod to get it to work properly, don't worry, it's fairly simple ;)

1. Alright first up navigate to your minetest folder, then to the folder called `builtin`, then to `game`, the path should look something like this: `.\minetest-0.4.16-win64\builtin\game`
2. Now open misc.lua in a text editor
3. Navigate to the end of line 45, it should say `core.register_on_joinplayer(function(player)`, if it doesn't, try scroll up and down to find that block of code
4. Press enter and add below that line: `if not minetest.get_modpath("incognito") then`
5. Navigate to the end of line 51 (should say `end`), press enter and type `end`
6. Now find line 55, it should say `core.register_on_leaveplayer(function(player, timed_out)`, and navigate to the end of it, we're going to do a similar thing to that function.
7. You know the drill, press enter and add below that line: `if not minetest.get_modpath("incognito") then`
8. Now navigate to the end of line 64 (should say `end`), press enter and type `end`

Of course now install the mod into the `mods` folder as normal, and you should be ready to rock and roll.

Settings
===

There are a couple of setting which might be of interest of course:

- On line 1 of `init.lua` you'll see a variable called `INCOGNITOCOOLDOWN`, now you can change that to modify how long (in seconds, set to 0 to disable) to cooldown for using /incognito is, since over use would make it really obvious.

- On line 3 of `init.lua` you'll find a variable called `PLAYERRANGE`, set this one to how many nodes as a radius you want to search for other players (if they are in the radius a warning HUD will pop up), the default is `100`, and we wouldn't recomend setting it too high because you'll probably end up with a fair amount of load on your server.

Notes
===

- This mod is still a work-in-progress, expect functionality to change slightly, if you have any improvements, please feel free to creat an GitHub issue, create a Pull Request or comment on the Minetest Forums (forum.minetest.net)
