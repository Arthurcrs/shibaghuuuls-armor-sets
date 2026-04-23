import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import crafttweaker.event.EntityLivingDeathEvent;
import mods.mahzenutils.PlayerUtils;

// ==========================================
// BALANCING
// ==========================================

val mufflePotionId as string = "ebwizardry:muffle";

// Full Set (4/4) - Assassination Strikes
val assassinateBonusDamage as double = 2.0; 
val assassinateCooldownTicks as int = 1200; 
val killResetRadius as double = 6.0; // Any enemy dying within 6 blocks resets the cooldown

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionFull as string = "While sneaking you gain the Muffle effect. Melee attacking an enemy while Muffled consumes the effect to deal " + ((assassinateBonusDamage * 100.0) as int) + "% bonus damage. This assassination strike has a " + (assassinateCooldownTicks / 20) + " second cooldown. If ANY enemy dies within " + killResetRadius + " blocks of you, this cooldown is instantly reset.";

val material as string = "Leather";

val head as string = "minecraft:leather_helmet";
val chest as string = "minecraft:leather_chestplate";
val legs as string = "minecraft:leather_leggings";
val feet as string = "minecraft:leather_boots";

// ==========================================
// UNIVERSAL REGISTER BLOCK
// ==========================================

val armorSetName as string = material + " Armor Set";
val armorBonusNameFull as string = material + " Armor Full Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

// Leather only has a 4-piece bonus, no weapon intersection required
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT (Granting Muffle)
events.onPlayerTick(function(event as PlayerTickEvent) {
    // Check twice a second to keep the script incredibly lightweight
    if (event.phase == "END" && event.player.world.time % 10 == 0) {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNameFull) == true) {
            
            // Check if sneaking using the standalone utility class
            if (PlayerUtils.isSneaking(player)) {
                
                // If the assassination strike is NOT on cooldown
                if (player.onCooldown("leather_assassinate_cd") == false) {
                    
                    // Apply Muffle for 1 second (20 ticks). It will continuously refresh as long as they sneak.
                    player.applyPotionEffect(mufflePotionId, 20, 0);
                }
            }
        }
    }
});

// 2. COMBAT EVENT (Consuming Muffle for Bonus Damage)
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // STRICT FILTER: Only trigger on direct melee attacks
    if (damageSource.damageType != "player") {
        return;
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            if (attacker.hasSetBonus(armorBonusNameFull) == true) {
                
                // Check if the player currently has the Muffle effect active
                val muffleAmp = attacker.getPotionAmplifier(mufflePotionId);
                
                if (muffleAmp >= 0) {
                    
                    // 1. Apply the massive backstab bonus damage
                    event.amount = event.amount * (1.0 + assassinateBonusDamage);
                    
                    // 2. Strip the Muffle effect using native CraftTweaker bracket handlers
                    attacker.removePotionEffect(<potion:ebwizardry:muffle>);
                    
                    // 3. Trigger the Cooldown
                    attacker.startCooldown("leather_assassinate_cd", assassinateCooldownTicks);
                    
                    attacker.debugMessage(material + " Armor: Assassination Strike! +" + ((assassinateBonusDamage * 100.0) as int) + "% Damage!");
                }
            }
        }
    }
});

// 3. DEATH EVENT (Resetting Cooldown on Close-Range Kills)
events.onEntityLivingDeath(function(event as EntityLivingDeathEvent) {
    val deadEntity = event.entityLivingBase;
    
    if (!isNull(deadEntity)) {
        
        // Grab all players within the kill radius using your backend method
        val nearbyPlayers = deadEntity.getNearbyPlayers(killResetRadius);
        
        if (!isNull(nearbyPlayers)) {
            for player in nearbyPlayers {
                if (!isNull(player) && player.isAlive()) {
                    
                    if (player.hasSetBonus(armorBonusNameFull) == true) {
                        
                        // If the player is currently waiting on their assassination cooldown
                        if (player.onCooldown("leather_assassinate_cd")) {
                            
                            // Setting the cooldown to 0 instantly expires it
                            player.startCooldown("leather_assassinate_cd", 0);
                            player.debugMessage(material + " Armor: Enemy killed at close range! Assassination cooldown reset!");
                        }
                    }
                }
            }
        }
    }
});