import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4)
val alternatingTargetBonus as double = 0.20; // +20% damage on new target
val lastTargetMarkId as string = "ruby_last_target";

// Full Set (4/4 + Weapon)
val splashDamagePercentage as double = 0.30; // 30% of main hit damage
val recentTargetMarkId as string = "ruby_recent_targets";
val recentTargetDurationTicks as int = 100;  // Enemies remember the hit for 5 seconds

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Deal " + ((alternatingTargetBonus * 100.0) as int) + "% bonus damage when attacking a new target. Bonus is lost if attacking the same enemy consecutively.";

val bonusDescriptionFull as string = "Ruby weapons deal " + ((splashDamagePercentage * 100.0) as int) + "% of your damage to all other enemies you have recently attacked.";

val material as string = "Ruby";

val head as string = "shinygear:ruby_helmet";
val chest as string = "shinygear:ruby_chestplate";
val legs as string = "shinygear:ruby_leggings";
val feet as string = "shinygear:ruby_boots";

val weapons as string[] = [
    "shinygear:ruby_battleaxe",
    "shinygear:ruby_sword",
    "shinygear:ruby_axe",
    "shinygear:ruby_dagger",
    "shinygear:ruby_katana",
    "shinygear:ruby_warhammer",
    "shinygear:ruby_greatsword",
    "shinygear:ruby_halberd",
    "shinygear:ruby_spear",
    "shinygear:ruby_hammer",
    "shinygear:ruby_lance",
    "shinygear:ruby_crossbow",
    "shinygear:ruby_saber",
    "shinygear:ruby_rapier",
    "shinygear:ruby_longbow",
    "shinygear:ruby_longsword",
    "shinygear:ruby_pike",
    "shinygear:ruby_throwing_knife",
    "shinygear:ruby_throwing_axe",
    "shinygear:ruby_javelin",
    "shinygear:ruby_mace"
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

// 2 pieces of armor for partial bonus
SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);

// 4 pieces of armor for full bonus description display
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// Intersection requirement: 4 armor + 1 weapon for the actual splash proc
SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    
    // INFINITE LOOP PREVENTION: 
    // If this damage was caused by our own set bonus splash, immediately stop.
    if (damageSource.damageType == "ruby_splash") {
        return;
    }

    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity)) {
        return;
    }
    
    // ATTACKER LOGIC
    if (!isNull(attackerEntity)) {
        if (attackerEntity instanceof IPlayer) {
            val attacker as IPlayer = attackerEntity.asIPlayer();
            
            if (!isNull(attacker)) {
                
                // ---------------------------------------------------------
                // Partial Set (2/4) - Alternating Target Bonus
                // ---------------------------------------------------------
                if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                    
                    if (attacker.isMarked(lastTargetMarkId, targetEntity) == false) {
                        attacker.debugMessage(material + " Armor: New target detected! Applying bonus damage.");
                        event.amount = event.amount * (1.0 + alternatingTargetBonus);
                    } else {
                        attacker.debugMessage(material + " Armor: Same target attacked. No bonus.");
                    }

                    // Clear the old mark and immediately mark this entity as the new "last target"
                    attacker.clearMarks(lastTargetMarkId);
                    attacker.markEntity(lastTargetMarkId, targetEntity, 600, "overwrite");
                }
                
                // ---------------------------------------------------------
                // Full Set (4/4 + Weapon) - Recent Target Splash Damage
                // ---------------------------------------------------------
                if (attacker.hasSetBonus(weaponBonusName) == true) {
                    
                    val splashAmount = event.amount * splashDamagePercentage;
                    val recentTargets = attacker.getMarkedEntities(recentTargetMarkId);
                    
                    // NESTED IF BLOCKS TO PREVENT BYTECODE CORRUPTION
                    if (!isNull(recentTargets)) {
                        if (recentTargets.length > 0) {
                            attacker.debugMessage(material + " Weapon: Splashing " + splashAmount + " damage to " + recentTargets.length + " recent targets.");
                            
                            for enemy in recentTargets {
                                if (!isNull(enemy)) {
                                    if (enemy.isAlive()) {
                                        if (enemy.uuid != targetEntity.uuid) {
                                            if (enemy instanceof IEntityLivingBase) {
                                                val livingEnemy as IEntityLivingBase = enemy;
                                                livingEnemy.dealCustomDamage(attacker, splashAmount, "ruby_splash");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Mark the current target so they get splashed on the next swing against someone else
                    attacker.markEntity(recentTargetMarkId, targetEntity, recentTargetDurationTicks, "add");
                }
            }
        }
    }
});