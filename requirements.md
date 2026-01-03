# Game Requirements

## Gameplay
- The player character must move along the tangent of the current gravity body using left/right input, accelerating up to a capped tangential speed.
- The player character must be pulled toward the current gravity body by a constant gravity strength each physics frame.
- The player character must jump away from the current gravity body when the jump action is pressed while grounded.
- Jumps must optionally align toward another gravity body within a target cone, granting a jump speed boost and temporarily biasing gravity selection toward that target.
- The player must automatically select the closest gravity body when not locked to a surface or mid-jump.
- The player must snap to the surface of the current gravity body when within a snap distance and moving inward, becoming grounded.
- While grounded on a moving orbiting body, the player must inherit the body’s motion so position and velocity stay aligned.

## World Generation and Layout
- The sun must be positioned near the bottom of the viewport based on the configured surface fraction and scaled to the viewport width.
- The player must spawn just above the sun surface on the upward axis after layout is updated.
- Obstacles must be spawned around the sun perimeter in a random distribution with configurable count and size range.
- Planets must be spawned orbiting the sun with configurable count, size range, orbit offsets/gaps, and randomized orbital angles and directions.
- Planets must be spaced to avoid overlapping each other, the sun surface, and the obstacle buffer, using the player jump height as a minimum surface gap.
- Each planet must spawn a configurable number of satellites that orbit the planet with randomized angles and directions.
- Satellites must be spaced to avoid overlapping each other and the planet surface using the same minimum surface gap logic.

## Gravity Bodies
- Each gravity body (sun, planet, satellite) must provide its unique id, current center, radius, and current velocity for gravity calculations.
- Orbiting gravity bodies must update their position and velocity every physics frame based on orbit radius, speed, and angle.

## Rendering
- Gravity bodies must render as circles using their configured radius and color.
- The player and obstacle visuals must render as colored squares sized based on their configured dimensions.
