#priority 1000
import crafttweaker.util.IRandom;
import crafttweaker.player.IPlayer;
import crafttweaker.world.IWorld;

global debugOn as bool = true;

$expand IPlayer$debugMessage(message as string) {
    if (debugOn == true) {
        this.sendChat(message);
    }
}