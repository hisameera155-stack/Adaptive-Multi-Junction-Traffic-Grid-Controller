# AMTGC – Adaptive Multi-Junction Traffic Grid Controller

A modular SystemVerilog implementation for an internship project covering Tasks 1–6: architecture planning, parameterized RTL, system integration, adaptive timing, self-checking verification, and professional delivery.

## Features
- Two reusable 4-way junction controllers instantiated from the same RTL.
- Moore FSM: NS Green → NS Yellow → All Red → EW Green → EW Yellow → All Red, with pedestrian phase.
- Standalone `generic_timer` used inside each junction controller.
- Shared round-robin pedestrian arbiter.
- System-wide emergency override to a safe all-red state.
- Green-wave coordination trigger from Junction A NS green to Junction B.
- 3-bit traffic-density input with minimum/maximum adaptive green-time limits.
- Single synchronous clock/reset strategy.
- Standalone and integration-level self-checking testbenches.
- Static interactive website in `/website` for the required hosted URL.

## Repository layout
```
/rtl
  generic_timer.sv
  junction_controller.sv
  ped_arbiter.sv
  green_wave_controller.sv
  amtgc_top.sv
/tb
  timer_testbench.sv
  junction_testbench.sv
  amtgc_top_tb.sv
/docs
  architecture.md
  verification_plan.md
  delivery_report.md
/sim
  README.md
/website
  index.html
  style.css
  app.js
```

## Simulation
The project is standard SystemVerilog. Use ModelSim/Questa, Icarus Verilog, Verilator, or another SystemVerilog simulator available in your environment.

### ModelSim/Questa – integration test
```tcl
vlib work
vlog rtl/generic_timer.sv rtl/junction_controller.sv rtl/ped_arbiter.sv rtl/green_wave_controller.sv rtl/amtgc_top.sv tb/amtgc_top_tb.sv
vsim -c amtgc_top_tb -do "run -all; quit -f"
```

### ModelSim/Questa – waveform
```tcl
vlib work
vlog rtl/generic_timer.sv rtl/junction_controller.sv tb/junction_testbench.sv
vsim junction_testbench
add wave *
run -all
```

The testbenches call `$dumpfile/$dumpvars` for VCD-compatible simulators and use assertions/fatal checks for key safety conditions.

## Website
The repository root contains `index.html`, `style.css`, and `app.js`, so GitHub Pages can serve the project website directly from the `main` branch root. The same files are also kept in `/website` for organization.

### GitHub Pages — easiest deployment
1. Create a **public** GitHub repository, for example `amtgc-traffic-controller`.
2. Upload all files from this project folder.
3. In GitHub open **Settings → Pages**.
4. Under **Build and deployment**, choose **Deploy from a branch**.
5. Select branch **main** and folder **/(root)**, then Save.
6. Wait for GitHub to publish the site.
7. Open the generated `https://YOUR-USERNAME.github.io/amtgc-traffic-controller/` URL in an incognito window.
8. Paste that public URL into the internship portal's **Website Hosted URL** field.

## Submission fields shown in the portal
- **Website Hosted URL:** your public GitHub Pages/Netlify website URL.
- **GitHub Repository:** your public repository URL.
- **Project report:** use `docs/delivery_report.md` as the source for the final report and attach/convert it to the portal's requested format.

## Important
Do not submit AWS credentials or any secret/password in GitHub or the public website. The project itself does not require credentials to demonstrate the RTL design.
