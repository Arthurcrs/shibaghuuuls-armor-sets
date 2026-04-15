import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import mods.mahzenutils.Stacks;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4) - Swiftness Charges
val outOfCombatSeconds as int = 5; 
val maxCharges as int = 2;
val speedBuffDurationTicks as int = 60; // 3 seconds of Haste V
val speedBuffAmplifier as int = 4; // Haste V

// Full Set (4/4) - 3-Hit Combo
val thirdHitBonusDamage as double = 1.0; // 100% bonus damage on the 3rd hit

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "After " + outOfCombatSeconds + " seconds of not dealing damage gain " + maxCharges + " Swiftness charges. Dealing damage consumes a charge to grant immense Attack Speed for your next strike.";

val bonusDescriptionFull as string = "Iron and Steel weapons deal " + ((thirdHitBonusDamage * 100.0) as int) + "% bonus damage on every 3rd consecutive strike against the same enemy.";

val material as string = "Chain";

val head as string = "minecraft:chainmail_helmet";
val chest as string = "minecraft:chainmail_chestplate";
val legs as string = "minecraft:chainmail_leggings";
val feet as string = "minecraft:chainmail_boots";

val weapons as string[] = [
    // Vanilla Iron
    "minecraft:iron_sword",
    "minecraft:iron_axe",
    
    // Spartan Weaponry Iron
    "spartanweaponry:dagger_iron",
    "spartanweaponry:longsword_iron",
    "spartanweaponry:katana_iron",
    "spartanweaponry:scythe_iron",
    "spartanweaponry:saber_iron",
    "spartanweaponry:rapier_iron",
    "spartanweaponry:greatsword_iron",
    "spartanweaponry:hammer_iron",
    "spartanweaponry:warhammer_iron",
    "spartanweaponry:spear_iron",
    "spartanweaponry:halberd_iron",
    "spartanweaponry:pike_iron",
    "spartanweaponry:lance_iron",
    "spartanweaponry:battleaxe_iron",
    "spartanweaponry:mace_iron",
    "spartanweaponry:glaive_iron",
    "spartanweaponry:staff_iron",
    
    // Steel Weapons
    "spartanweaponry:dagger_steel",
    "spartanweaponry:longsword_steel",
    "spartanweaponry:katana_steel",
    "spartanweaponry:scythe_steel",
    "spartanweaponry:saber_steel",
    "spartanweaponry:rapier_steel",
    "spartanweaponry:greatsword_steel",
    "spartanweaponry:hammer_steel",
    "spartanweaponry:warhammer_steel",
    "spartanweaponry:spear_steel",
    "spartanweaponry:halberd_steel",
    "spartanweaponry:pike_steel",
    "spartanweaponry:lance_steel",
    "spartanweaponry:battleaxe_steel",
    "spartanweaponry:mace_steel",
    "spartanweaponry:glaive_steel",
    "spartanweaponry:staff_steel"
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

Stacks.registerStack("chain_speed_charges", maxCharges, 0, "PERMANENT", "PRESERVE");
// Register the combo tracker to apply to the enemies!
Stacks.registerStack("chain_combo", 3, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT (For 2/4 Swiftness Charges)
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END" && event.player.world.time % 20 == 0) {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNamePartial) == true) {
            
            // Check if player is out of combat
            if (player.onCooldown("chain_combat_timer") == false) {
                
                val currentCharges = player.getStacks("chain_speed_charges");
                
                if (currentCharges < maxCharges) {
                    // Safe addition without clearing
                    player.addStacks("chain_speed_charges", 1);
                    player.debugMessage(material + " Armor: Gained Swiftness charge (" + (currentCharges + 1) + "/" + maxCharges + ").");
                }
            }
        }
    }
});

// 2. COMBAT EVENT
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            // --- Partial Set (2/4): Consume charge and lock out-of-combat timer ---
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                attacker.startCooldown("chain_combat_timer", outOfCombatSeconds * 20);
                
                val currentCharges = attacker.getStacks("chain_speed_charges");
                if (currentCharges > 0) {
                    attacker.removeStacks("chain_speed_charges", 1);
                    
                    attacker.applyPotionEffect("minecraft:haste", speedBuffDurationTicks, speedBuffAmplifier);
                    attacker.debugMessage(material + " Armor: Charge consumed. Haste V applied. (" + (currentCharges - 1) + " remaining)");
                }
            }
            
            // --- Full Set (4/4 + Weapon): Target-Based Combo Logic ---
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                // Track the combo ON THE ENEMY!
                targetEntity.addStacks("chain_combo", 1);
                val currentCombo = targetEntity.getStacks("chain_combo");
                
                if (currentCombo >= 3) {
                    // 3rd hit! Apply bonus damage
                    val totalBonus as double = thirdHitBonusDamage;
                    event.amount = event.amount * (1.0 + totalBonus);
                    
                    attacker.debugMessage(material + " Weapon: 3rd Strike combo! +" + ((totalBonus * 100.0) as int) + "% damage!");
                    
                    // Shatter the combo so it starts over on the next hit
                    targetEntity.clearStacks("chain_combo");
                    
                } else {
                    attacker.debugMessage(material + " Weapon: Strike " + currentCombo + " logged.");
                }
            }
        }
    }
});