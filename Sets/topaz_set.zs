import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4) - Redirection & Mitigation
val redirectRadius as double = 5.0; 
val redirectedDamagePercentage as double = 0.50; 
val blockingMitigationPercentage as double = 0.30; 

// Full Set (4/4) - Stack Shield
val stackId as string = "topaz_shield";
val damageToStackConversion as double = 0.50; 
val stackDamageAbsorption as double = 1.0; 
val shieldMitigationPercentage as double = 0.60;

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "While actively blocking with a shield " + ((redirectedDamagePercentage * 100.0) as int) + "% of damage taken by players within " + redirectRadius + " blocks is redirected to you. This intercepted damage is reduced by " + ((blockingMitigationPercentage * 100.0) as int) + "%.";

val bonusDescriptionFull as string = "Topaz weapons convert " + ((damageToStackConversion * 100.0) as int) + "% of damage dealt into Topaz Stacks. When taking damage Topaz Stacks absorb up to " + ((shieldMitigationPercentage * 100.0) as int) + "% of the hit.";

val material as string = "Topaz";

val head as string = "shinygear:topaz_helmet";
val chest as string = "shinygear:topaz_chestplate";
val legs as string = "shinygear:topaz_leggings";
val feet as string = "shinygear:topaz_boots";

val weapons as string[] = [
    "shinygear:topaz_battleaxe",
    "shinygear:topaz_sword",
    "shinygear:topaz_axe",
    "shinygear:topaz_dagger",
    "shinygear:topaz_katana",
    "shinygear:topaz_warhammer",
    "shinygear:topaz_greatsword",
    "shinygear:topaz_halberd",
    "shinygear:topaz_spear",
    "shinygear:topaz_hammer",
    "shinygear:topaz_lance",
    "shinygear:topaz_crossbow",
    "shinygear:topaz_saber",
    "shinygear:topaz_rapier",
    "shinygear:topaz_longbow",
    "shinygear:topaz_longsword",
    "shinygear:topaz_pike",
    "shinygear:topaz_throwing_knife",
    "shinygear:topaz_throwing_axe",
    "shinygear:topaz_javelin",
    "shinygear:topaz_mace"
];

// ==========================================
// UNIVERSAL REGISTER BLOCK
// ==========================================

val armorSetName as string = material + " Armor Set";
val weaponSetName as string = material + " Weapon Set";

val armorBonusNamePartial as string = material + " Armor Partial Bonus";
val armorBonusNameFull as string = material + " Armor Full Bonus";
val weaponBonusName as string = material + " Weapon Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

// Register weapons to their own set
SB.addEquipToSet(weaponSetName, "mainhand", weapons);

// 2 pieces of armor for partial
SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);

// 4 pieces of armor for full description display
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// Intersection requirement: 4 armor + 1 weapon for the stack generation
SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    
    if (damageSource.damageType == "topaz_intercept") {
        return;
    }

    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(targetEntity)) {
        return;
    }
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC (When a Player takes damage)
    // ---------------------------------------------------------
    if (targetEntity instanceof IPlayer) {
        val targetPlayer as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(targetPlayer)) {
            
            // --- 1. FULL SET (4/4): PARTIAL STACK SHIELD ABSORPTION ---
            if (targetPlayer.hasSetBonus(armorBonusNameFull) == true) {
                val currentStacks = targetPlayer.getStacks(stackId);
                
                if (currentStacks > 0) {
                    val floatStacks = currentStacks as float;
                    val maxDamageAbsorbed = floatStacks / stackDamageAbsorption;
                    
                    val damageToMitigate = event.amount * shieldMitigationPercentage;
                    
                    if (maxDamageAbsorbed >= damageToMitigate) {
                        // Shield has enough stacks to cover the mitigated portion
                        val stacksToRemove = (damageToMitigate * stackDamageAbsorption) as int;
                        targetPlayer.removeStacks(stackId, stacksToRemove);
                        targetPlayer.debugMessage(material + " Shield: Absorbed " + damageToMitigate + " damage.");
                        
                        // Player takes the unmitigated remainder
                        event.amount = event.amount - damageToMitigate;
                    } else {
                        // Shield doesn't have enough stacks. It absorbs what it can and shatters.
                        targetPlayer.clearStacks(stackId);
                        targetPlayer.debugMessage(material + " Shield: Shattered! Absorbed " + maxDamageAbsorbed + " damage.");
                        
                        // Player takes the original damage minus whatever the shield managed to absorb
                        event.amount = event.amount - maxDamageAbsorbed;
                    }
                }
            }
            
            // --- 2. PARTIAL SET (2/4): DAMAGE INTERCEPTION (PvE Co-op) ---
            val nearbyPlayers = targetPlayer.getNearbyPlayers(redirectRadius);
            
            if (!isNull(nearbyPlayers)) {
                for ally in nearbyPlayers {
                    if (!isNull(ally) && ally.uuid != targetPlayer.uuid && ally.isAlive()) {
                        if (ally.hasSetBonus(armorBonusNamePartial) == true) {
                            if (ally.isBlocking()) {
                                
                                val interceptedAmount = event.amount * redirectedDamagePercentage;
                                event.amount = event.amount - interceptedAmount;
                                
                                val mitigatedDamage = interceptedAmount * (1.0 - blockingMitigationPercentage);
                                
                                ally.debugMessage(material + " Armor: Intercepted " + interceptedAmount + " damage for an ally!");
                                targetPlayer.debugMessage("Saved by a nearby Topaz shield!");
                                
                                ally.dealCustomDamage(attackerEntity, mitigatedDamage, "topaz_intercept");
                                
                                break; 
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC (4/4 + Weapon) - Generating Stacks
    // ---------------------------------------------------------
    if (!isNull(attackerEntity)) {
        if (attackerEntity instanceof IPlayer) {
            val attacker as IPlayer = attackerEntity.asIPlayer();
            
            if (!isNull(attacker)) {
                
                // USING THE NEW INTERSECTION BONUS CHECK
                if (attacker.hasSetBonus(weaponBonusName) == true) {
                    
                    if (event.amount > 0) {
                        val stacksToAdd = (event.amount * damageToStackConversion) as int;
                        
                        if (stacksToAdd > 0) {
                            attacker.addStacks(stackId, stacksToAdd);
                            attacker.debugMessage(material + " Weapon: Gained " + stacksToAdd + " shield stacks.");
                        }
                    }
                }
            }
        }
    }
});