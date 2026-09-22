# AMTGC Architecture

## Top-level blocks
1. `amtgc_top`
2. `junction_controller` × 2
3. `generic_timer` × 2 (one inside each junction controller)
4. `ped_arbiter`
5. `green_wave_controller`

## Clock and reset
A single synchronous clock domain is used. Reset is synchronous and active-high. After reset, each junction starts in an all-red safety state.

## Junction controller
Each junction is a reusable Moore FSM. Timing is parameterized by `GREEN_TIME`, `YELLOW_TIME`, `RED_TIME`, `PED_TIME`, and adaptive limits. The current traffic-density value is sampled when entering a green phase; changing density during the active green does not destabilize the current phase.

## Pedestrian fairness
Requests are received by the shared `ped_arbiter`. Simultaneous requests use round-robin selection based on the last served side. The arbiter does not access internal FSM states.

## Emergency
`emergency_override` is synchronous. When asserted, each junction enters `S_EMERGENCY`, whose outputs are all-red. When the override is removed, the controller resumes through a valid all-red phase before normal traffic.

## Green wave
A registered `ns_green_start` pulse from Junction A starts the green-wave delay. After `WAVE_DELAY` cycles, `green_wave_controller` generates a trigger for Junction B. Junction B records the trigger and uses it at its next safe all-red boundary. This keeps the timing interface modular and allows the coordination policy to be changed without modifying `generic_timer`.
