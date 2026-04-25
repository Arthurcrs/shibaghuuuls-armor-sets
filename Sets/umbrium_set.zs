import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.EntityLivingUpdateEvent;
import mods.mahzenutils.Stacks;

// ==========================================
// BALANCING
// ==========================================

val umbriumStackId as string = "umbrium_doom_stacks";
val doomTimerId as string = "umbrium_doom_timer";

// Partial Set (2/4) - Executioner
val executionHealthThreshold as double = 0.50; // 50% Health
val executionBonusDamage as double = 0.50; // 50% Bonus Damage

// Full Set (4/4 + Weapon) - Impending Doom
val damageToStackMultiplier as double = 1.0; // 1 Damage = 1 Stack
// CHANGED: Declared as double to prevent JVM VerifyError
val doomExplosionMultiplier as double = 0.50; 
val doomDelayTicks as int = 60; // 3 Seconds without taking damage to trigger the explosion

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Deals " + ((executionBonusDamage * 100.0) as int) + "% bonus damage to enemies that are below " + ((executionHealthThreshold * 100.0) as int) + "% maximum health.";

val bonusDescriptionFull as string = "Umbrium weapons inflict Impending Doom stacks based on damage dealt. If an afflicted enemy does not take damage for " + (doomDelayTicks / 20) + " seconds, the stacks detonate, dealing " + ((doomExplosionMultiplier * 100.0) as int) + "% of the accumulated damage as a massive burst.";

val material as string = "Umbrium";

val head as string = "defiledlands:umbrium_helmet";
val chest as string = "defiledlands:umbrium_chestplate";
val legs as string = "defiledlands:umbrium_leggings";
val feet as string = "defiledlands:umbrium_boots";

val weapons as string[] = [
    "defiledlands:umbrium_sword",
    "defiledlands:umbrium_axe",
    "defiledlands:umbrium_hoe",
    "spartandefiled:dagger_umbrium",
    "spartandefiled:longsword_umbrium",
    "spartandefiled:katana_umbrium",
    "spartandefiled:scythe_umbrium",
    "spartandefiled:saber_umbrium",
    "spartandefiled:rapier_umbrium",
    "spartandefiled:greatsword_umbrium",
    "spartandefiled:hammer_umbrium",
    "spartandefiled:warhammer_umbrium",
    "spartandefiled:spear_umbrium",
    "spartandefiled:halberd_umbrium",
    "spartandefiled:pike_umbrium",
    "spartandefiled:lance_umbrium",
    "spartandefiled:battleaxe_umbrium",
    "spartandefiled:mace_umbrium",
    "spartandefiled:glaive_umbrium",
    "spartandefiled:staff_umbrium",
    "spartandefiled:parrying_dagger_umbrium",
    "spartandefiled:boomerang_umbrium",
    "spartandefiled:longbow_umbrium",
    "spartandefiled:throwing_knife_umbrium",
    "spartandefiled:throwing_axe_umbrium",
    "spartandefiled:javelin_umbrium"
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

// Extremely high cap since it stores a 1:1 ratio of damage points
Stacks.registerStack(umbriumStackId, 99999, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. COMBAT EVENT (Applying Stacks & Executioner)
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    
    // Prevent the detonation burst from triggering infinite loops
    if (damageSource.damageType == "umbrium_burst") {
        return;
    }

    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(targetEntity)) {
        return; 
    }
    
    // --- RESET DOOM TIMER ON ANY HIT ---
    // If an enemy has doom stacks, ANY incoming damage resets the countdown timer.
    val currentDoomStacks = targetEntity.getStacks(umbriumStackId);
    if (currentDoomStacks > 0) {
        targetEntity.startCooldown(doomTimerId, doomDelayTicks);
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (!isNull(attackerEntity) && attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            // --- Partial Set (2/4): Executioner ---
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                val currentHealthRatio = (targetEntity.health as double) / (targetEntity.maxHealth as double);
                
                if (currentHealthRatio <= executionHealthThreshold) {
                    event.amount = event.amount * (1.0 + executionBonusDamage);
                    attacker.debugMessage(material + " Armor: Executioner Bonus! +" + ((executionBonusDamage * 100.0) as int) + "% Damage!");
                }
            }
            
            // --- Full Set (4/4 + Weapon): Impending Doom ---
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                val stacksToAdd = (event.amount * damageToStackMultiplier) as int;
                
                if (stacksToAdd > 0) {
                    targetEntity.addStacks(umbriumStackId, stacksToAdd);
                    
                    // Start/Refresh the detonation countdown on the target
                    targetEntity.startCooldown(doomTimerId, doomDelayTicks);
                    
                    attacker.debugMessage(material + " Weapon: Inflicted " + stacksToAdd + " Impending Doom stacks!");
                }
            }
        }
    }
});

// 2. PASSIVE TARGET TICK (Detonating the Stacks)
events.onEntityLivingUpdate(function(event as EntityLivingUpdateEvent) {
    // Only process this check twice a second to preserve server performance
    if (event.entityLivingBase.world.time % 10 == 0) {
        
        val targetEntity = event.entityLivingBase;
        
        if (!isNull(targetEntity) && targetEntity.isAlive()) {
            
            val stacks = targetEntity.getStacks(umbriumStackId);
            
            // If the entity has stacks, but the countdown timer has expired
            if (stacks > 0 && targetEntity.onCooldown(doomTimerId) == false) {
                
                // Cast to float right before application
                val burstDamage as float = (stacks as float) * (doomExplosionMultiplier as float);
                
                // Clear the stacks immediately so it doesn't multi-detonate
                targetEntity.clearStacks(umbriumStackId);
                
                // Deal the damage to the entity. 
                // We pass the entity itself as the 'attacker' to prevent null crashes in the backend!
                targetEntity.dealCustomDamage(targetEntity as IEntity, burstDamage, "umbrium_burst");
            }
        }
    }
});