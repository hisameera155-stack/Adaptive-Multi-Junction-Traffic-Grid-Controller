# Verification Plan

## Task 1 planned scenarios
1. Reset to all-red.
2. Normal A NS sequence.
3. Normal A EW sequence.
4. Normal B NS sequence.
5. Normal B EW sequence.
6. Full traffic cycle.
7. Green-wave delay.
8. Green-wave disabled/baseline behavior.
9. Pedestrian A request.
10. Pedestrian B request.
11. Simultaneous pedestrian requests.
12. Repeated simultaneous requests.
13. Continuous A requests with B request.
14. Continuous B requests with A request.
15. Pedestrian request during yellow.
16. Emergency during NS green.
17. Emergency during EW green.
18. Emergency during pedestrian phase.
19. Emergency during green-wave coordination.
20. Reset from multiple active states.

## Task 2 corner cases
- Generic timer target values 3, 7 and 12.
- Generic timer target 0.
- Reset while timer is counting.
- Parameter changes without RTL changes.
- Non-zero all-red safety gap.
- Pedestrian request arriving during yellow.

## Task 3 integration checks
- Both junctions operate concurrently.
- Named port connections are used.
- Shared arbiter is independent of junction internals.
- Repeated simultaneous requests alternate fairly.
- Emergency during pedestrian service.
- Emergency release resumes from a valid phase.
- Green-wave relationship is observed in simulation.

## Task 4 adaptive checks
- Sweep all density values 0–7.
- Minimum green limit.
- Maximum green limit.
- Both junctions at maximum density.
- Density changes while green is active: sampled-at-entry policy.
- Green-wave test across multiple density combinations.
- `generic_timer.sv` remains unchanged.

## Task 5 self-checking
The integration testbench contains assertions for conflicting greens and fatal checks for emergency/reset failures. It also performs repeated pedestrian-request cycles and reports grant counts for both sides.
