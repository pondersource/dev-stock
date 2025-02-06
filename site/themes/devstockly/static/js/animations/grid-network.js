import { EventManager, throttle } from '../utils/Performance.js';

// Grid Animation for hero-background that simulates OCM flows
export function setupGridAnimation() {
    const canvas = document.getElementById('gridCanvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let animationFrameId;
    const eventManager = new EventManager();

    // ------------------------------------
    // CONFIGURATION CONSTANTS
    // ------------------------------------
    const gridSize = 40;          // distance between grid lines
    const nodeRadius = 5;         // radius for each permanent node

    // The user wants a comet-like effect:
    //   - Head travels from 0..1 along the path
    //   - Tail lags behind, then continues traveling until it catches up at 1
    const tailLength = 0.5;       // fraction of path behind the head
    const signalSpeed = 0.00005;  // smaller = slower

    // We will allow the "progress" of a signal to go from [0..1 + tailLength].
    //   headProgress = min(progress, 1)
    //   tailProgress = max(progress - tailLength, 0)
    //   once progress >= 1 + tailLength, we remove the signal.

    const TOTAL_NODES = 20;       // number of permanent nodes

    // Tail fade control: 0 = fully transparent, 1 = fully opaque
    const TAIL_FADE_START = 0.01;  // alpha at tail
    const TAIL_FADE_END = 1.0;    // alpha at head

    // Predefined signals that get assigned randomly
    const signalsCatalog = [
        'GET: /.well-known/ocm (Discovery)',
        'POST: /shares (Create Share)',
        'POST: /notifications (Send Notification)',
        'POST: /invite-accepted (Invite Accepted)',
        'POST: /token (Exchange Code)',
        'POST: /invite (Invite Flow)'
    ];

    // Example universities/institutions across the EU
    const EU_INSTITUTIONS = [
        'CERN',
        'SURF',
        'GARR',
        'FZJ',
        'CNRS',
        'STFC',
        'CESNET',
        'CSIC',
        'PSNC',
        'DFN',
        'HEAnet',
        'GRNET',
        'UNINETT',
        'CARNet',
        'ARNES',
        'INST Luxembourg',
        'Belnet',
    ];

    // Example platforms
    const PLATFORMS = ['Nextcloud', 'ownCloud', 'oCIS', 'Seafile', 'CERNBox'];

    // Fallback name pieces
    const FALLBACK_FIRST = ['Terminal', 'Node', 'Egress', 'Server', 'Relay'];
    const NATO_ALPHABET = [
        'Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Golf', 'Hotel',
        'India', 'Juliet', 'Kilo', 'Lima', 'Mike', 'November', 'Oscar', 'Papa',
        'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey',
        'X-ray', 'Yankee', 'Zulu'
    ];

    // Store nodes and signals
    let nodes = [];
    let signals = [];

    // -----------------------------------------------------------
    // 1) HELPER FUNCTIONS
    // -----------------------------------------------------------
    function randomColor() {
        // e.g. random HSL color
        return `hsl(${Math.floor(Math.random() * 360)}, 70%, 50%)`;
    }

    /**
     * Return something like: "CERN - Nextcloud"
     * or fallback: "Node Alpha"
     */
    function getNodeName(idx) {
        if (idx < EU_INSTITUTIONS.length) {
            const institution = EU_INSTITUTIONS[idx];
            const plat = PLATFORMS[Math.floor(Math.random() * PLATFORMS.length)];
            return `${institution} - ${plat}`;
        } else {
            const first =
                FALLBACK_FIRST[Math.floor(Math.random() * FALLBACK_FIRST.length)];
            const second =
                NATO_ALPHABET[Math.floor(Math.random() * NATO_ALPHABET.length)];
            return `${first} ${second}`;
        }
    }

    /**
     * Resizing logic
     */
    function resizeCanvas() {
        const rect = canvas.parentElement.getBoundingClientRect();
        canvas.width = rect.width * window.devicePixelRatio;
        canvas.height = rect.height * window.devicePixelRatio;
        ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
        canvas.style.width = rect.width + 'px';
        canvas.style.height = rect.height + 'px';
        drawEverything(); // re-draw after resizing
    }

    /**
     * Generate permanent nodes at random grid intersections
     */
    function initNodes() {
        const cols = Math.floor(canvas.width / gridSize);
        const rows = Math.floor(canvas.height / gridSize);

        nodes = [];
        const intersections = [];

        for (let i = 0; i < rows; i++) {
            for (let j = 0; j < cols; j++) {
                intersections.push({ x: j * gridSize, y: i * gridSize });
            }
        }
        // Shuffle
        for (let i = intersections.length - 1; i > 0; i--) {
            const r = Math.floor(Math.random() * (i + 1));
            [intersections[i], intersections[r]] = [intersections[r], intersections[i]];
        }
        // pick as many as TOTAL_NODES
        const selected = intersections.slice(0, TOTAL_NODES);

        selected.forEach((coords, idx) => {
            nodes.push({
                x: coords.x,
                y: coords.y,
                color: randomColor(),
                name: getNodeName(idx),
                isSending: false,
                isReceiving: false,
            });
        });
    }

    /**
     * A path is an array of grid points (no diagonals).
     */
    function findPath(src, dst) {
        const path = [{ x: src.x, y: src.y }];
        let current = { x: src.x, y: src.y };

        while (current.x !== dst.x || current.y !== dst.y) {
            // Move horizontally first
            if (current.x !== dst.x) {
                current.x += gridSize * (current.x < dst.x ? 1 : -1);
                path.push({ x: current.x, y: current.y });
            }
            // Then vertically
            else if (current.y !== dst.y) {
                current.y += gridSize * (current.y < dst.y ? 1 : -1);
                path.push({ x: current.x, y: current.y });
            }
        }
        return path;
    }

    /**
     * Creates a random signal from one node to another.
     */
    function createSignal() {
        if (nodes.length < 2) return;

        const availableSenders = nodes.filter(n => !n.isSending);
        if (availableSenders.length < 1) return;

        const sender = availableSenders[Math.floor(Math.random() * availableSenders.length)];

        const availableReceivers = nodes.filter(n => n !== sender && !n.isReceiving);
        if (availableReceivers.length < 1) return;

        const receiver = availableReceivers[Math.floor(Math.random() * availableReceivers.length)];

        // Mark them as busy
        sender.isSending = true;
        receiver.isReceiving = true;

        // find path
        const path = findPath(sender, receiver);
        // pick random signal name
        const signalLabel = signalsCatalog[Math.floor(Math.random() * signalsCatalog.length)];

        // push signal object
        signals.push({
            source: sender,
            target: receiver,
            path,
            label: signalLabel,
            color: sender.color,
            // For the comet effect, we track overall 'progress' from 0..(1 + tailLength).
            // The head is at min(progress, 1). The tail is at max(progress - tailLength, 0).
            progress: 0,
            hasFreedNodes: false,
            onComplete: () => {
                // once the head arrives, free up the nodes
                sender.isSending = false;
                receiver.isReceiving = false;
            }
        });
    }

    // -----------------------------------------------------------
    // 2) DRAWING LOGIC
    // -----------------------------------------------------------
    function drawNodes() {
        nodes.forEach(node => {
            // node circle
            ctx.beginPath();
            ctx.fillStyle = node.color;
            ctx.arc(node.x, node.y, nodeRadius, 0, Math.PI * 2);
            ctx.fill();

            // label
            ctx.font = '12px sans-serif';
            ctx.fillStyle = '#333';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            ctx.fillText(node.name, node.x, node.y + nodeRadius + 4);
        });
    }

    /**
     * Draw faint grid lines (optional).
     */
    function drawGrid() {
        ctx.save();
        ctx.strokeStyle = 'rgba(26,115,232,0.05)';
        ctx.lineWidth = 1;

        const cols = Math.floor(canvas.width / gridSize);
        const rows = Math.floor(canvas.height / gridSize);

        for (let c = 0; c <= cols; c++) {
            const x = c * gridSize;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, canvas.height);
            ctx.stroke();
        }
        for (let r = 0; r <= rows; r++) {
            const y = r * gridSize;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(canvas.width, y);
            ctx.stroke();
        }
        ctx.restore();
    }

    /**
     * Draw signals with a comet-like effect:
     *   - We store overall signal.progress from 0..(1 + tailLength).
     *   - Head is at min(progress, 1).
     *   - Tail is at max(progress - tailLength, 0).
     *   - Remove the signal once progress >= (1 + tailLength).
     */
    function drawSignals(deltaTime) {
        signals.forEach(signal => {
            const path = signal.path;
            const totalSegments = path.length - 1;
            if (totalSegments < 1) return;

            // 1) Update progress
            signal.progress += signalSpeed * deltaTime;
            if (signal.progress > 1 + tailLength) {
                signal.progress = 1 + tailLength;
            }

            // 2) Determine head/tail progress in [0..1]
            const headProgress = Math.min(signal.progress, 1);
            const tailProgress = Math.max(signal.progress - tailLength, 0);

            const headDist = headProgress * totalSegments;
            const tailDist = tailProgress * totalSegments;

            const headIdx = Math.floor(headDist);
            const headFrac = headDist - headIdx;
            const tailIdx = Math.floor(tailDist);
            const tailFrac = tailDist - tailIdx;

            // 3) Find actual coordinates
            const tailPoint = getPointOnPath(path, tailIdx, tailFrac);
            const headPoint = getPointOnPath(path, headIdx, headFrac);

            // 4) Gradient for the line (tail -> head)
            ctx.save();
            const gradient = ctx.createLinearGradient(
                tailPoint.x, tailPoint.y,
                headPoint.x, headPoint.y
            );
            gradient.addColorStop(0, `rgba(${hexToRgb(signal.color)}, ${TAIL_FADE_START})`);
            gradient.addColorStop(1, `rgba(${hexToRgb(signal.color)}, ${TAIL_FADE_END})`);

            ctx.lineWidth = 3;
            ctx.strokeStyle = gradient;
            ctx.beginPath();
            // draw the path segments from tail to head
            drawPathSegments(path, tailIdx, tailFrac, headIdx, headFrac);
            ctx.stroke();
            ctx.restore();

            // 5) Draw the comet head circle (keep it visible until the entire signal is done)
            ctx.beginPath();
            ctx.fillStyle = signal.color;
            ctx.arc(headPoint.x, headPoint.y, 4, 0, Math.PI * 2);
            ctx.fill();

            // traveling label
            ctx.font = '10px sans-serif';
            ctx.fillStyle = '#444';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'bottom';
            ctx.fillText(signal.label, headPoint.x + 6, headPoint.y - 6);

            // Once head arrives, free up the nodes (onComplete) but do NOT remove the signal yet.
            if (headProgress >= 1 && !signal.hasFreedNodes) {
                if (typeof signal.onComplete === 'function') {
                    signal.onComplete();
                }
                signal.hasFreedNodes = true;
            }
        });

        // Remove signals once the tail has fully arrived
        signals = signals.filter(s => s.progress < 1 + tailLength);
    }

    /**
     * Helper to draw partial path from (startIdx + startFrac) to (endIdx + endFrac)
     */
    function drawPathSegments(path, startIdx, startFrac, endIdx, endFrac) {
        // Starting point
        let s1 = path[startIdx];
        let s2 = path[startIdx + 1] || s1;
        const sx = s1.x + (s2.x - s1.x) * startFrac;
        const sy = s1.y + (s2.y - s1.y) * startFrac;

        // Ending point
        let e1 = path[endIdx];
        let e2 = path[endIdx + 1] || e1;
        const ex = e1.x + (e2.x - e1.x) * endFrac;
        const ey = e1.y + (e2.y - e1.y) * endFrac;

        ctx.moveTo(sx, sy);

        // full segments in between
        for (let i = startIdx + 1; i <= endIdx - 1; i++) {
            ctx.lineTo(path[i].x, path[i].y);
        }
        // final partial
        ctx.lineTo(ex, ey);
    }

    /**
     * Return point at index + fraction along the path.
     */
    function getPointOnPath(path, idx, frac) {
        if (idx >= path.length - 1) {
            return { x: path[path.length - 1].x, y: path[path.length - 1].y };
        }
        const p0 = path[idx];
        const p1 = path[idx + 1];
        return {
            x: p0.x + (p1.x - p0.x) * frac,
            y: p0.y + (p1.y - p0.y) * frac,
        };
    }

    /**
     * Convert hex or HSL to "r,g,b"
     */
    function hexToRgb(color) {
        // If #hex
        if (color.startsWith('#')) {
            const hex = color.replace('#', '');
            const bigint = parseInt(hex, 16);
            const r = (bigint >> 16) & 255;
            const g = (bigint >> 8) & 255;
            const b = bigint & 255;
            return `${r},${g},${b}`;
        }
        // If hsl(...)
        if (color.startsWith('hsl')) {
            const hslMatch = color.match(/hsl\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)/i);
            if (hslMatch) {
                const h = parseFloat(hslMatch[1]);
                const s = parseFloat(hslMatch[2]) / 100;
                const l = parseFloat(hslMatch[3]) / 100;
                const rgb = hslToRgb(h, s, l);
                return `${rgb.r},${rgb.g},${rgb.b}`;
            }
        }
        return '255,255,255'; // fallback
    }

    /**
     * Minimal HSL->RGB converter
     */
    function hslToRgb(h, s, l) {
        const c = (1 - Math.abs(2 * l - 1)) * s;
        const x = c * (1 - Math.abs((h / 60) % 2 - 1));
        const m = l - c / 2;
        let r = 0, g = 0, b = 0;

        if (0 <= h && h < 60) { r = c; g = x; b = 0; }
        else if (60 <= h && h < 120) { r = x; g = c; b = 0; }
        else if (120 <= h && h < 180) { r = 0; g = c; b = x; }
        else if (180 <= h && h < 240) { r = 0; g = x; b = c; }
        else if (240 <= h && h < 300) { r = x; g = 0; b = c; }
        else if (300 <= h && h < 360) { r = c; g = 0; b = x; }

        r = Math.round((r + m) * 255);
        g = Math.round((g + m) * 255);
        b = Math.round((b + m) * 255);
        return { r, g, b };
    }

    // -----------------------------------------------------------
    // 3) MAIN ANIMATION LOOP
    // -----------------------------------------------------------
    let lastTimestamp = 0;
    function drawEverything(timestamp = 0) {
        const deltaTime = timestamp - lastTimestamp;
        lastTimestamp = timestamp;

        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // optional background grid
        drawGrid();

        // signals first
        drawSignals(deltaTime);

        // nodes on top
        drawNodes();

        // small chance each frame to create a new random signal
        if (Math.random() < 0.01) {
            createSignal();
        }

        animationFrameId = requestAnimationFrame(drawEverything);
    }

    // -----------------------------------------------------------
    // 4) INITIALIZATION
    // -----------------------------------------------------------
    resizeCanvas();
    initNodes();

    // Attach a throttled resize
    eventManager.addEvent(window, 'resize', throttle(resizeCanvas, 250));

    // Start loop
    drawEverything();

    // Return a dispose method if needed
    return () => {
        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
        }
        eventManager.removeAll();
    };
}
