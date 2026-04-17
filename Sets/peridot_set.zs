import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import mods.mahzenutils.Stacks;
import mods.mahzenutils.PlayerUtils;

// ==========================================
// BALANCING
// ==========================================

val peridotStackId as string = "peridot_stagger_stacks";
val damageToStackMultiplier as int = 10; // 1 Damage Point = 10 Stacks (Preserves decimal precision)

// Partial Set (2/4) - Stagger Mitigation
val staggerInterceptPercentage as double = 0.6; // 60% of incoming damage converted to Stagger
val bleedPercentagePerSecond as double = 0.10; // 10% of total stagger pool taken as damage per second

// Full Set (4/4 + Weapon) - Stagger Cleansing
val damageBoostPerStack as double = 0.05; // 5% bonus damage per 1 full point of stagger damage (10 stacks)
val stackClearPercentage as double = 0.50; // 50% of your outgoing damage clears stagger

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "While sneaking, deflects " + ((staggerInterceptPercentage * 100.0) as int) + "% of incoming damage into Stagger Stacks (Cap equals Max Health). Every second you take unblockable damage equal to " + ((bleedPercentagePerSecond * 100.0) as int) + "% of your total Stagger clearing those stacks.";

val bonusDescriptionFull as string = "While standing, Peridot weapons deal " + ((damageBoostPerStack * 100.0) as int) + "% bonus damage for every full point of damage in your Stagger pool. Dealing damage with Peridot clears Stagger equal to " + ((stackClearPercentage * 100.0) as int) + "% of the damage you deal.";

val material as string = "Peridot";

val head as string = "shinygear:peridot_helmet";
val chest as string = "shinygear:peridot_chestplate";
val legs as string = "shinygear:peridot_leggings";
val feet as string = "shinygear:peridot_boots";

val weapons as string[] = [
    "shinygear:peridot_battleaxe",
    "shinygear:peridot_sword",
    "shinygear:peridot_axe",
    "shinygear:peridot_dagger",
    "shinygear:peridot_katana",
    "shinygear:peridot_warhammer",
    "shinygear:peridot_greatsword",
    "shinygear:peridot_halberd",
    "shinygear:peridot_spear",
    "shinygear:peridot_hammer",
    "shinygear:peridot_lance",
    "shinygear:peridot_crossbow",
    "shinygear:peridot_saber",
    "shinygear:peridot_rapier",
    "shinygear:peridot_longbow",
    "shinygear:peridot_longsword",
    "shinygear:peridot_pike",
    "shinygear:peridot_throwing_knife",
    "shinygear:peridot_throwing_axe",
    "shinygear:peridot_javelin",
    "shinygear:peridot_mace"
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

SB.addEquipToSet(weaponSetName, "mainhand", weapons);

SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// STACK REGISTRY
// ==========================================

Stacks.registerStack(peridotStackId, 99999, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT (Stagger Bleeding)
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END") {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNamePartial) == true) {
            
            if (player.onCooldown("peridot_bleed_tick") == false) {
                val currentStacks = player.getStacks(peridotStackId);
                
                if (currentStacks > 0) {
                    
                    // Calculate exactly how many stacks to bleed (Min 1 stack / 0.1 damage)
                    var stacksToRemove = (currentStacks as double * bleedPercentagePerSecond) as int;
                    if (stacksToRemove < 1) { stacksToRemove = 1; }
                    
                    // Convert stacks back into exact float damage
                    val bleedDamage as float = (stacksToRemove as float) / (damageToStackMultiplier as float);
                    
                    val newHealth = player.health - bleedDamage;
                    
                    // Direct Health Manipulation ensures it completely bypasses all armor and i-frames
                    if (newHealth <= 0.0) {
                        player.dealCustomDamage(player, 9999.0, "peridot_bleed"); 
                    } else {
                        player.health = newHealth;
                    }
                    
                    player.removeStacks(peridotStackId, stacksToRemove);
                }
                
                player.startCooldown("peridot_bleed_tick", 20); // 1-second bleed cycle
            }
        }
    }
});

// 2. COMBAT EVENT
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    
    // Prevent the execution damage from triggering loops
    if (damageSource.damageType == "peridot_bleed") { return; }

    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC (2/4) - Intercepting Damage
    // ---------------------------------------------------------
    if (!isNull(targetEntity) && targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(defender) && defender.hasSetBonus(armorBonusNamePartial) == true) {
            
            // MUST BE SNEAKING TO ABSORB STAGGER
            if (PlayerUtils.isSneaking(defender)) {
                
                // Calculate dynamic maximum stagger limit based on current Max Health
                val maxStacks = (defender.maxHealth as int) * damageToStackMultiplier;
                val currentStacks = defender.getStacks(peridotStackId);
                
                if (currentStacks < maxStacks) {
                    
                    val interceptDamage = event.amount * staggerInterceptPercentage;
                    var stacksToAdd = (interceptDamage * damageToStackMultiplier) as int;
                    
                    // Clamp the addition so it never exceeds the Max Health limit
                    if (currentStacks + stacksToAdd > maxStacks) {
                        stacksToAdd = maxStacks - currentStacks;
                    }
                    
                    if (stacksToAdd > 0) {
                        val actualInterceptedDamage = (stacksToAdd as float) / (damageToStackMultiplier as float);
                        
                        // Reduce incoming damage by the intercepted amount
                        event.amount = event.amount - actualInterceptedDamage;
                        defender.addStacks(peridotStackId, stacksToAdd);
                        
                        defender.debugMessage(material + " Armor: Guarding! Staggered " + actualInterceptedDamage + " damage.");
                    }
                }
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC (4/4 + Weapon) - Cleansing Stagger
    // ---------------------------------------------------------
    if (!isNull(attackerEntity) && attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                // MUST BE STANDING TO GAIN DAMAGE BOOST AND CLEANSE
                if (!PlayerUtils.isSneaking(attacker)) {
                    val currentStacks = attacker.getStacks(peridotStackId);
                    
                    if (currentStacks > 0) {
                        
                        // 1. Amplification (Based on full damage points in the pool)
                        val floatDamagePool = (currentStacks as float) / (damageToStackMultiplier as float);
                        val damageBoost = floatDamagePool * damageBoostPerStack;
                        event.amount = event.amount * (1.0 + damageBoost);
                        
                        attacker.debugMessage(material + " Weapon: Striking! +" + ((damageBoost * 100.0) as int) + "% damage from Stagger pool!");
                        
                        // 2. Cleansing
                        val damageCleared = event.amount * stackClearPercentage;
                        val stacksToClear = (damageCleared * damageToStackMultiplier) as int;
                        
                        if (stacksToClear > 0) {
                            if (stacksToClear >= currentStacks) {
                                attacker.clearStacks(peridotStackId);
                                attacker.debugMessage(material + " Weapon: Purified ALL Stagger!");
                            } else {
                                attacker.removeStacks(peridotStackId, stacksToClear);
                                val actualDamageCleared = (stacksToClear as float) / (damageToStackMultiplier as float);
                                attacker.debugMessage(material + " Weapon: Purified " + actualDamageCleared + " Stagger damage.");
                            }
                        }
                    }
                }
            }
        }
    }
});