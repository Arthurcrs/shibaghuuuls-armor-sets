import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

val recentAttackerDurationTicks as int = 100; // 5 seconds of memory
val attackerMarkId as string = "tanzanite_attackers";

// Partial Set (2/4) - Swarm Defense
val damageReductionPerAttacker as double = 0.05; // 5% less damage taken per unique attacker
val maxDamageReduction as double = 0.50; // Cap at 50% damage reduction (10 enemies)

// Full Set (4/4) - Swarm Offense
val bonusDamagePerAttacker as double = 0.10; // 10% bonus damage dealt per unique attacker
val maxBonusDamage as double = 1.0; // Cap at 100% bonus damage (10 enemies)

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Take " + ((damageReductionPerAttacker * 100.0) as int) + "% less damage for every unique enemy that attacked you in the last " + (recentAttackerDurationTicks / 20) + " seconds (Max " + ((maxDamageReduction * 100.0) as int) + "% reduction).";

val bonusDescriptionFull as string = "Tanzanite weapons deal " + ((bonusDamagePerAttacker * 100.0) as int) + "% bonus damage for every unique enemy that recently attacked you (Max " + ((maxBonusDamage * 100.0) as int) + "% bonus).";

val material as string = "Tanzanite";

val head as string = "shinygear:tanzanite_helmet";
val chest as string = "shinygear:tanzanite_chestplate";
val legs as string = "shinygear:tanzanite_leggings";
val feet as string = "shinygear:tanzanite_boots";

val weapons as string[] = [
    "shinygear:tanzanite_battleaxe",
    "shinygear:tanzanite_sword",
    "shinygear:tanzanite_axe",
    "shinygear:tanzanite_dagger",
    "shinygear:tanzanite_katana",
    "shinygear:tanzanite_warhammer",
    "shinygear:tanzanite_greatsword",
    "shinygear:tanzanite_halberd",
    "shinygear:tanzanite_spear",
    "shinygear:tanzanite_hammer",
    "shinygear:tanzanite_lance",
    "shinygear:tanzanite_crossbow",
    "shinygear:tanzanite_saber",
    "shinygear:tanzanite_rapier",
    "shinygear:tanzanite_longbow",
    "shinygear:tanzanite_longsword",
    "shinygear:tanzanite_pike",
    "shinygear:tanzanite_throwing_knife",
    "shinygear:tanzanite_throwing_axe",
    "shinygear:tanzanite_javelin",
    "shinygear:tanzanite_mace"
];

// ==========================================
// UNIVERSAL REGISTER BLOCK (DO NOT EDIT)
// ==========================================

val armorSetName as string = material + " Armor Set";
val armorBonusNamePartial as string = material + " Armor Partial Bonus";
val armorBonusNameFull as string = material + " Armor Full Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// ==========================================
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC (When Player gets hit)
    // ---------------------------------------------------------
    if (targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(defender)) {
            
            // 1. Record the attacker
            defender.markEntity(attackerMarkId, attackerEntity, recentAttackerDurationTicks, "add");
            
            // 2. Partial Set (2/4) - Swarm Defense
            if (defender.hasSetBonus(armorBonusNamePartial) == true) {
                
                val recentAttackers = defender.getMarkedEntities(attackerMarkId);
                
                if (!isNull(recentAttackers)) {
                    var activeAttackers = 0;
                    
                    for enemy in recentAttackers {
                        if (!isNull(enemy) && enemy.isAlive()) {
                            activeAttackers += 1;
                        }
                    }
                    
                    if (activeAttackers > 0) {
                        var reduction as double = (activeAttackers as double) * damageReductionPerAttacker;
                        if (reduction > maxDamageReduction) {
                            reduction = maxDamageReduction;
                        }
                        
                        defender.debugMessage(material + " Armor: Incoming damage reduced by " + ((reduction * 100.0) as int) + "% (" + activeAttackers + " attackers).");
                        event.amount = event.amount * (1.0 - reduction);
                    }
                }
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC (When Player hits something)
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker)) {
            if (attacker.hasSetBonus(armorBonusNameFull) == true) {
                
                val heldItem = attacker.mainHandHeldItem;
                
                if (!isNull(heldItem)) {
                    var holdingValidWeapon = false;
                    val heldId = heldItem.definition.id;
                    
                    for wep in weapons {
                        if (heldId == wep) {
                            holdingValidWeapon = true;
                            break;
                        }
                    }
                    
                    if (holdingValidWeapon && event.amount > 0) {
                        
                        val recentAttackers = attacker.getMarkedEntities(attackerMarkId);
                        
                        if (!isNull(recentAttackers)) {
                            var activeAttackers = 0;
                            
                            for enemy in recentAttackers {
                                if (!isNull(enemy) && enemy.isAlive()) {
                                    activeAttackers += 1;
                                }
                            }
                            
                            if (activeAttackers > 0) {
                                var totalBonus as double = (activeAttackers as double) * bonusDamagePerAttacker;
                                
                                // CLAMP THE MAXIMUM BONUS DAMAGE
                                if (totalBonus > maxBonusDamage) {
                                    totalBonus = maxBonusDamage;
                                }
                                
                                attacker.debugMessage(material + " Weapon: +" + ((totalBonus * 100.0) as int) + "% damage fueled by " + activeAttackers + " attackers.");
                                event.amount = event.amount * (1.0 + totalBonus);
                            }
                        }
                    }
                }
            }
        }
    }
});