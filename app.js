// ============================================================
// AMTGC - Interactive Dashboard Simulation
// ============================================================

let running = true;
let emergency = false;
let tick = 0;

const junctions = {
    A: {
        phase: "NS_GREEN",
        time: 0,
        density: 2,
        pedRequest: false
    },
    B: {
        phase: "NS_GREEN",
        time: 0,
        density: 2,
        pedRequest: false
    }
};

// ------------------------------------------------------------
// DOM ELEMENTS
// ------------------------------------------------------------

const runBtn = document.getElementById("runBtn");
const resetBtn = document.getElementById("resetBtn");
const emergencyBtn = document.getElementById("emergencyBtn");

const densityA = document.getElementById("densityA");
const densityB = document.getElementById("densityB");

const densityAVal = document.getElementById("densityAVal");
const densityBVal = document.getElementById("densityBVal");

const pedABtn = document.getElementById("pedABtn");
const pedBBtn = document.getElementById("pedBBtn");

// ------------------------------------------------------------
// DENSITY INPUT
// ------------------------------------------------------------

densityA.addEventListener("input", () => {
    junctions.A.density = Number(densityA.value);
    densityAVal.textContent = densityA.value;
});

densityB.addEventListener("input", () => {
    junctions.B.density = Number(densityB.value);
    densityBVal.textContent = densityB.value;
});

// ------------------------------------------------------------
// RUN / PAUSE
// ------------------------------------------------------------

runBtn.addEventListener("click", () => {

    running = !running;

    runBtn.textContent = running ? "Pause" : "Run";

    if (running) {
        runBtn.classList.add("primary");
    } else {
        runBtn.classList.remove("primary");
    }
});

// ------------------------------------------------------------
// EMERGENCY
// ------------------------------------------------------------

emergencyBtn.addEventListener("click", () => {

    emergency = !emergency;

    if (emergency) {

        emergencyBtn.textContent = "Emergency ON";
        emergencyBtn.classList.add("active");

        // Immediate safe state
        junctions.A.phase = "ALL_RED";
        junctions.B.phase = "ALL_RED";

        junctions.A.time = 0;
        junctions.B.time = 0;

    } else {

        emergencyBtn.textContent = "Emergency OFF";
        emergencyBtn.classList.remove("active");

        // Restart normal operation
        junctions.A.phase = "NS_GREEN";
        junctions.B.phase = "ALL_RED";

        junctions.A.time = 0;
        junctions.B.time = 0;
    }

    updateDashboard();
});

// ------------------------------------------------------------
// PEDESTRIAN REQUESTS
// ------------------------------------------------------------

pedABtn.addEventListener("click", () => {

    junctions.A.pedRequest = true;

    document.getElementById("pedA").textContent = "REQUESTED";

    setTimeout(() => {

        junctions.A.pedRequest = false;

    }, 3000);
});


pedBBtn.addEventListener("click", () => {

    junctions.B.pedRequest = true;

    document.getElementById("pedB").textContent = "REQUESTED";

    setTimeout(() => {

        junctions.B.pedRequest = false;

    }, 3000);
});

// ------------------------------------------------------------
// ADAPTIVE GREEN TIME
// ------------------------------------------------------------

function getGreenTime(density) {

    // Minimum = 5 seconds
    // Maximum = 12 seconds

    return Math.min(12, 5 + density);
}

// ------------------------------------------------------------
// PHASE DURATIONS
// ------------------------------------------------------------

function getPhaseDuration(junction) {

    switch (junction.phase) {

        case "NS_GREEN":
            return getGreenTime(junction.density);

        case "NS_YELLOW":
            return 3;

        case "ALL_RED":
            return 2;

        case "EW_GREEN":
            return getGreenTime(junction.density);

        case "EW_YELLOW":
            return 3;

        case "PED":
            return 4;

        default:
            return 2;
    }
}

// ------------------------------------------------------------
// JUNCTION STATE MACHINE
// ------------------------------------------------------------

function updateJunction(junction, name) {

    junction.time++;

    const duration = getPhaseDuration(junction);

    if (junction.time >= duration) {

        junction.time = 0;

        switch (junction.phase) {

            case "NS_GREEN":
                junction.phase = "NS_YELLOW";
                break;

            case "NS_YELLOW":
                junction.phase = "ALL_RED";
                break;

            case "ALL_RED":

                if (junction.pedRequest) {
                    junction.phase = "PED";
                } else {
                    junction.phase = "EW_GREEN";
                }

                break;

            case "EW_GREEN":
                junction.phase = "EW_YELLOW";
                break;

            case "EW_YELLOW":
                junction.phase = "ALL_RED";
                break;

            case "PED":
                junction.phase = "EW_GREEN";
                break;
        }
    }
}

// ------------------------------------------------------------
// GREEN WAVE
// ------------------------------------------------------------

function handleGreenWave() {

    // When Junction A starts NS green,
    // Junction B follows after a delay.

    if (
        junctions.A.phase === "NS_GREEN" &&
        junctions.A.time === 1
    ) {

        junctions.B.phase = "ALL_RED";
        junctions.B.time = 0;

        document.getElementById("waveStatus").textContent =
            "A NS Green Active";

        document.getElementById("waveText").textContent =
            "Junction A NS-green started. Waiting for coordinated Junction B trigger.";

        document.getElementById("waveBar").style.width = "35%";
    }

    // Trigger B after A has been green for 3 seconds

    if (
        junctions.A.phase === "NS_GREEN" &&
        junctions.A.time >= 3
    ) {

        junctions.B.phase = "NS_GREEN";
        junctions.B.time = 0;

        document.getElementById("waveStatus").textContent =
            "Green Wave Active";

        document.getElementById("waveText").textContent =
            "Junction B NS-green triggered after the configured coordination delay.";

        document.getElementById("waveBar").style.width = "100%";
    }
}

// ------------------------------------------------------------
// UPDATE TRAFFIC LIGHTS
// ------------------------------------------------------------

function updateLights(prefix, phase) {

    const red = document.getElementById(prefix + "-r");
    const yellow = document.getElementById(prefix + "-y");
    const green = document.getElementById(prefix + "-g");

    const eastRed = document.getElementById(prefix + "-er");
    const eastYellow = document.getElementById(prefix + "-ey");
    const eastGreen = document.getElementById(prefix + "-eg");

    // Turn everything OFF first

    red.classList.remove("on");
    yellow.classList.remove("on");
    green.classList.remove("on");

    eastRed.classList.remove("on");
    eastYellow.classList.remove("on");
    eastGreen.classList.remove("on");

    // Emergency / ALL RED

    if (phase === "ALL_RED") {

        red.classList.add("on");
        eastRed.classList.add("on");

        return;
    }

    // North-South Green

    if (phase === "NS_GREEN") {

        red.classList.remove("on");
        green.classList.add("on");

        eastRed.classList.add("on");

        return;
    }

    // North-South Yellow

    if (phase === "NS_YELLOW") {

        red.classList.remove("on");
        yellow.classList.add("on");

        eastRed.classList.add("on");

        return;
    }

    // East-West Green

    if (phase === "EW_GREEN") {

        red.classList.add("on");

        eastRed.classList.remove("on");
        eastGreen.classList.add("on");

        return;
    }

    // East-West Yellow

    if (phase === "EW_YELLOW") {

        red.classList.add("on");

        eastRed.classList.remove("on");
        eastYellow.classList.add("on");

        return;
    }

    // Pedestrian

    if (phase === "PED") {

        red.classList.add("on");
        eastRed.classList.add("on");

        return;
    }
}

// ------------------------------------------------------------
// UPDATE DASHBOARD
// ------------------------------------------------------------

function updateDashboard() {

    const a = junctions.A;
    const b = junctions.B;

    // State names

    document.getElementById("stateA").textContent =
        formatPhase(a.phase);

    document.getElementById("stateB").textContent =
        formatPhase(b.phase);

    // Timers

    document.getElementById("timeA").textContent =
        a.time;

    document.getElementById("timeB").textContent =
        b.time;

    // Pedestrian

    document.getElementById("pedA").textContent =
        a.pedRequest ? "REQUESTED" : "IDLE";

    document.getElementById("pedB").textContent =
        b.pedRequest ? "REQUESTED" : "IDLE";

    // Lights

    updateLights("a", a.phase);
    updateLights("b", b.phase);

    // Density display

    densityAVal.textContent = a.density;
    densityBVal.textContent = b.density;

    // Emergency status

    if (emergency) {

        document.getElementById("stateA").textContent =
            "EMERGENCY";

        document.getElementById("stateB").textContent =
            "EMERGENCY";

        document.getElementById("waveStatus").textContent =
            "Emergency Override";

        document.getElementById("waveText").textContent =
            "Both junctions are forced to ALL RED for safety.";

        document.getElementById("waveBar").style.width = "100%";
    }
}

// ------------------------------------------------------------
// FORMAT STATE
// ------------------------------------------------------------

function formatPhase(phase) {

    switch (phase) {

        case "NS_GREEN":
            return "NS GREEN";

        case "NS_YELLOW":
            return "NS YELLOW";

        case "EW_GREEN":
            return "EW GREEN";

        case "EW_YELLOW":
            return "EW YELLOW";

        case "ALL_RED":
            return "ALL RED";

        case "PED":
            return "PEDESTRIAN";

        default:
            return phase;
    }
}

// ------------------------------------------------------------
// MAIN SIMULATION LOOP
// ------------------------------------------------------------

setInterval(() => {

    if (!running) {
        return;
    }

    if (!emergency) {

        updateJunction(junctions.A, "A");
        updateJunction(junctions.B, "B");

        handleGreenWave();

    } else {

        junctions.A.phase = "ALL_RED";
        junctions.B.phase = "ALL_RED";

    }

    tick++;

    updateDashboard();

}, 1000);

// ------------------------------------------------------------
// RESET
// ------------------------------------------------------------

resetBtn.addEventListener("click", () => {

    emergency = false;
    running = true;

    junctions.A.phase = "NS_GREEN";
    junctions.A.time = 0;
    junctions.A.density = 2;
    junctions.A.pedRequest = false;

    junctions.B.phase = "ALL_RED";
    junctions.B.time = 0;
    junctions.B.density = 2;
    junctions.B.pedRequest = false;

    densityA.value = 2;
    densityB.value = 2;

    densityAVal.textContent = "2";
    densityBVal.textContent = "2";

    runBtn.textContent = "Pause";

    emergencyBtn.textContent = "Emergency OFF";
    emergencyBtn.classList.remove("active");

    document.getElementById("waveStatus").textContent =
        "Waiting";

    document.getElementById("waveText").textContent =
        "Junction B NS green is triggered after the configured delay.";

    document.getElementById("waveBar").style.width = "0%";

    updateDashboard();
});

// ------------------------------------------------------------
// INITIAL DISPLAY
// ------------------------------------------------------------

updateDashboard();