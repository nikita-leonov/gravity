# Game Requirements

## Core Gameplay
- Render a main scene that contains a player character, a sun, orbiting gravity objects (planets and satellites), and obstacles.
- Update the player with a list of all gravity objects every physics frame so movement and gravity targeting can be calculated.
- Recompute the scene layout whenever the window size changes.

## Gravity Objects
- Each gravity object must register itself in a `gravity_object` group on startup.
- Gravity objects must expose radius, color, and an orbit configuration (parent body, orbit radius, orbit speed, and orbit angle).
- Gravity objects without an orbit parent or with a non-positive orbit radius must remain stationary.
- Orbiting gravity objects must update their orbit angle and world position every physics frame and compute their current velocity from movement.
- Gravity objects must expose their ID, center position, radius, and current velocity as data for the player.
- Gravity objects must draw themselves as filled circles using their configured radius and color.

## Player Movement
- The player must move tangentially around the current gravity body using left/right input and clamp tangential speed to a maximum.
- When no horizontal input is provided, the player must decelerate tangential velocity toward zero.
- The player must apply radial gravity acceleration toward the current gravity body every physics frame.
- The player must rotate to face its tangential direction around the gravity body.
- The player must apply physics integration by advancing its position with its current velocity every physics frame.

## Gravity Targeting
- The player must choose a gravity target from available gravity bodies, preferring the closest surface distance.
- The player must retain a locked gravity target after landing until that target is unavailable, unless overridden by a jump target lock.
- The player must bias gravity target selection toward a jump-assist target while the jump-assist timer is active.

## Jumping
- The player must only initiate jumps when grounded and the jump input is pressed.
- Jumping must launch the player away from the current gravity body using a base jump speed.
- When a viable jump target is aligned within a configurable angle, the player must receive a jump boost and lock onto the target for assist selection.
- Jump assist must expire after a configurable duration.

## Grounding and Surface Constraints
- The player must snap to the gravity body surface when within snap distance and moving inward toward the surface.
- Grounding must remove the radial component of relative velocity so the player sticks to the surface.
- Grounded movement must inherit the gravity body’s velocity when the body is moving.

## Scene Layout and Spawning
- The sun must be centered horizontally in the viewport and vertically offset so its surface sits above the screen bottom by a configurable fraction.
- The player must spawn on the sun’s surface at the top of the sun.
- Obstacles must spawn around the sun, each at a random angle with a random size in a configurable range.
- Planets must spawn in orbit around the sun with random sizes, orbit angles, and orbit speeds within configurable ranges.
- Planet orbits must be spaced to maintain a minimum surface gap based on the player’s jump height and obstacle buffer.
- Each planet must spawn a configurable number of satellites that orbit the planet at random angles and speeds within configurable ranges.
- Satellite orbits must be spaced to maintain a minimum surface gap based on the player’s jump height.

## Obstacles
- Obstacles must render as squares of a configurable size and color.
- Obstacles must update their visual size when configured via a setter.
