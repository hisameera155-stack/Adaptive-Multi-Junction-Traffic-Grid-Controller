# AMTGC Final Technical Delivery Report

## 1. Overview
AMTGC is a reusable SystemVerilog traffic-control architecture for two coordinated 4-way junctions. The implementation separates timing, junction sequencing, pedestrian arbitration and green-wave coordination into independent modules.

## 2. Design decisions
- Single synchronous clock domain.
- Synchronous active-high reset.
- Moore FSM for deterministic light outputs.
- Standalone timer to avoid duplicated timing counters.
- Round-robin pedestrian arbitration to prevent permanent priority.
- Traffic density is sampled at green-phase entry to avoid unstable mid-phase timing.
- Minimum and maximum adaptive green limits protect safety and fairness.
- Emergency mode forces all-red and returns through a safe phase after release.

## 3. Reusability
Junction A and Junction B are instances of the same `junction_controller` module with different parameter values. `generic_timer` is instantiated inside each controller and is not specialized for traffic-light states.

## 4. Verification evidence
The repository contains standalone timer and junction testbenches plus a unified integration testbench. The testbenches generate VCD files where supported and include self-checking assertions/fatal checks for safety conditions.

## 5. Bug/fix record
During integration, the pedestrian path and timer phase-entry behavior were treated as explicit state-machine concerns rather than relying on implicit timing. Phase-entry triggering was separated from the timer's counting logic. The pedestrian arbiter was separated from junction internals so it only receives requests and produces grants.

## 6. Known verification note
Exact green-wave offset is architecture-dependent when Junction B is not at a safe all-red boundary at the moment the delayed trigger arrives. The trigger is latched and applied at the next safe boundary. For a strict fixed-cycle offset in a future revision, the junction scheduler should expose a synchronization-ready interface or the top-level should align both cycle schedules.

## 7. Delivery
The `/website` folder is a static project demonstration suitable for GitHub Pages or another static host. The public hosted URL and GitHub URL should be entered into the internship portal only after verifying that both are accessible from an incognito browser window.
