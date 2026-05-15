# n-body forge

An incremental simulation game where players manage a celestial system. By launching objects into orbit around a central star, players generate Energy based on orbital mechanics. The game aims to blend the chaotic beauty of n-body physics with the satisfying progression of automation and eventual prestige.

## Gameplay loops & mechanics

The primary loop involves spending energy to launch objects, maintaining stable orbits to maximize energy generation, and managing collisions to evolve celestial bodies.

### Energy generation

* The central star provides a baseline energy emission based on its mass and radius.  
* Orbiting objects generate energy scaled by their size, kinetic energy (velocity), proximity to the star, and longevity.  
* Shattered objects drop energy fragments that must be manually collected via hover.  
* Out-of-bounds objects provide a minor balance-recovery energy payout.

### Launch & Collision mechanics

Players use a slingshot mechanic to launch payloads. 
* Launches will cost energy based on type of the object and the slingshot distance 

Collisions result in three outcomes based on size and velocity:

* **Shatter:** High velocity, similar size. Results in energy bursts.  
* **Merge:** Low velocity, similar size. Objects evolve into higher-tier bodies (e.g., planets to gas giants).  
* **Debris:** Different sizes. Smaller objects are destroyed, larger objects lose mass as new debris bodies.
* **Star:** Collision with stars will increase the mass and radius of the star and destroy the object colliding with it.

## Progression and Economy

### Phase 1: Manual Discovery

Initial gameplay focuses on discovery. New object types encountered through physics interactions are added to the player's permanent library. Examples include Standard Comets, Heavier Planets, Antimatter Comets, and Dense Iron Cores.

### Phase 2: Automation & Upgrades

* **Auto-Launchers:** Periodic emission of specific objects for a set duration.  
* **Upgrade Tree:**   
  * Players can spend energy to modify:   
    * the Gravitational Constant  
    * the Central Star's properties (Mass/Radius).  
    * emitter properties like speed, cost etc.  
    * slingshot properties like preview duration, cost etc.  
    * properties of individual objects

### Phase 3: Prestige (Supernova)

When the star becomes too massive for orbits to escape, the system collapses into a Black Hole or Supernova. This acts as a soft reset, providing premium currency and permanent multipliers for the next run.

## Art and User Experience (UX)

### Visual Style

* **Theme:** Minimalistic vector art in deep space.  
* **Typography:** Geometric sans-serif fonts (Montserrat/Inter) for menus; monospaced for counters.  
* **Palette:** Stark high contrast; neon blue/yellow for Energy indicators.

### User Interface (UI)

* Trajectory preview curves appear immediately upon slingshot interaction.  
* Unobtrusive side/bottom panels for automation and upgrades.  
* Impactful feedback via bright burst animations and bold weight for reward text.
