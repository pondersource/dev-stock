import { EventManager, throttle } from '../utils/Performance.js';

// Grid Animation for hero-background that simulates ordered OCM flows
export function setupGridAnimation() {
    const canvas = document.getElementById('gridCanvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let animationFrameId;
    const eventManager = new EventManager();

    // ------------------------------------
    // CONFIGURATION CONSTANTS
    // ------------------------------------
    const gridSize = 40;              // distance between grid lines
    const nodeRadius = 5;             // radius for each permanent node
    const tailLength = 1.0;           // fraction of path from head to tail
    const signalSpeed = 0.00004;      // smaller = slower
    const TOTAL_NODES = 20;           // number of permanent nodes

    // Tail fade control: 0 = fully transparent, 1 = fully opaque
    const TAIL_FADE_START = 0.2;      // alpha at tail
    const TAIL_FADE_END = 1.0;      // alpha at head

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
    // Feel free to expand or alter this list as you like.
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
        'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whiskey', 'X-ray', 'Yankee', 'Zulu'
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
     * or fallback: "Terminal Alpha"
     * We iterate an index to pick from EU_INSTITUTIONS first, then fallback if out of range
     */
    function getNodeName(idx) {
        // If we still have institutions left
        if (idx < EU_INSTITUTIONS.length) {
            const institution = EU_INSTITUTIONS[idx];
            // random platform
            const plat = PLATFORMS[Math.floor(Math.random() * PLATFORMS.length)];
            return `${institution} - ${plat}`;
        } else {
            // Fallback: "Node Alpha", "Egress Bravo", etc.
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

        // Collect all possible intersection coordinates
        const intersections = [];
        for (let i = 0; i < rows; i++) {
            for (let j = 0; j < cols; j++) {
                intersections.push({ x: j * gridSize, y: i * gridSize });
            }
        }

        // Shuffle and pick as many as TOTAL_NODES
        for (let i = intersections.length - 1; i > 0; i--) {
            const r = Math.floor(Math.random() * (i + 1));
            [intersections[i], intersections[r]] = [intersections[r], intersections[i]];
        }
        const selected = intersections.slice(0, TOTAL_NODES);

        // Create node objects
        selected.forEach((coords, idx) => {
            nodes.push({
                x: coords.x,
                y: coords.y,
                color: randomColor(),
                name: getNodeName(idx), // see above
                isSending: false,
                isReceiving: false,
            });
        });
    }

    /**
     * A path is an array of points. We must be able to draw a partial path from
     * tailIndex to headIndex (both can be fractional).
     */
    function drawPathSegments(path, startIdx, startFrac, endIdx, endFrac) {
        // We'll move from [startIdx + startFrac] to [endIdx + endFrac] stepping on grid lines.
        ctx.beginPath();

        // Get the starting point
        let s1 = path[startIdx];
        let s2 = path[startIdx + 1];
        if (!s2) s2 = s1; // edge case if path is just 1 point
        const sx = s1.x + (s2.x - s1.x) * startFrac;
        const sy = s1.y + (s2.y - s1.y) * startFrac;
        ctx.moveTo(sx, sy);

        // Walk full integer segments in between
        for (let i = startIdx + 1; i <= endIdx - 1; i++) {
            ctx.lineTo(path[i].x, path[i].y);
        }

        // The ending point
        let e1 = path[endIdx];
        let e2 = path[endIdx + 1];
        if (!e2) e2 = e1;
        const ex = e1.x + (e2.x - e1.x) * endFrac;
        const ey = e1.y + (e2.y - e1.y) * endFrac;
        ctx.lineTo(ex, ey);

        ctx.stroke();
    }

    // -----------------------------------------------------------
    // 2) SIGNAL LOGIC
    // -----------------------------------------------------------
    /**
     * Find a path from one node to another (no diagonals).
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
     * Create a new signal from a random sender to a random receiver
     */
    function createSignal() {
        if (nodes.length < 2) return;

        // pick a random sender that is not currently sending
        const availableSenders = nodes.filter(n => !n.isSending);
        if (availableSenders.length < 1) return;

        const sender = availableSenders[Math.floor(Math.random() * availableSenders.length)];

        // pick a random receiver that is not the same node or currently receiving
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

        // add signal
        signals.push({
            source: sender,
            target: receiver,
            path,
            progress: 0,
            label: signalLabel,
            color: sender.color,
            onComplete: () => {
                sender.isSending = false;
                receiver.isReceiving = false;
            }
        });
    }

    // -----------------------------------------------------------
    // 3) DRAWING LOGIC
    // -----------------------------------------------------------
    function drawNodes() {
        nodes.forEach(node => {
            // draw node circle
            ctx.beginPath();
            ctx.fillStyle = node.color;
            ctx.arc(node.x, node.y, nodeRadius, 0, Math.PI * 2);
            ctx.fill();

            // draw node label below circle
            ctx.font = '12px sans-serif';
            ctx.fillStyle = '#333';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            ctx.fillText(node.name, node.x, node.y + nodeRadius + 4);
        });
    }

    /**
     * Draw signals with a “comet effect” while respecting the grid lines for tail.
     */
    function drawSignals(deltaTime) {
        signals.forEach(signal => {
            // Update the signal’s progress
            signal.progress += signalSpeed * deltaTime;
            if (signal.progress > 1) signal.progress = 1;

            const path = signal.path;
            const totalSegments = path.length - 1;
            if (totalSegments < 1) return;

            // HEAD position
            const headDist = signal.progress * totalSegments;
            const headIdx = Math.floor(headDist);
            const headFrac = headDist - headIdx;

            // === HARD-PIN TAIL AT SENDER (index=0, fraction=0) ===
            const tailIdx = 0;
            const tailFrac = 0;

            // Draw the line from the sender (index=0) to the head (headIdx + headFrac)
            ctx.save();
            {
                // We'll fade from TAIL_FADE_START near the sender to TAIL_FADE_END near the head
                const startPt = path[tailIdx];                   // the sender
                const endPt = getPointOnPath(path, headIdx, headFrac); // the current head

                const gradient = ctx.createLinearGradient(
                    startPt.x, startPt.y,
                    endPt.x, endPt.y
                );

                gradient.addColorStop(0, `rgba(${hexToRgb(signal.color)}, ${TAIL_FADE_START})`);
                gradient.addColorStop(1, `rgba(${hexToRgb(signal.color)}, ${TAIL_FADE_END})`);

                ctx.lineWidth = 3;
                ctx.strokeStyle = gradient;

                // Draw the segmented path from [0,0] to [headIdx,headFrac]
                drawPathSegments(path, tailIdx, tailFrac, headIdx, headFrac);
            }
            ctx.restore();

            // Draw the comet head
            const headPoint = getPointOnPath(path, headIdx, headFrac);
            ctx.beginPath();
            ctx.fillStyle = signal.color;  // fully opaque for the head
            ctx.arc(headPoint.x, headPoint.y, 4, 0, Math.PI * 2);
            ctx.fill();

            // traveling label near the head
            ctx.font = '10px sans-serif';
            ctx.fillStyle = '#444';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'bottom';
            ctx.fillText(signal.label, headPoint.x + 6, headPoint.y - 6);

            // If done
            if (signal.progress >= 1) {
                if (typeof signal.onComplete === 'function') {
                    signal.onComplete();
                }
            }
        });

        // remove completed signals
        signals = signals.filter(s => s.progress < 1);
    }

    /**
     * Simple helper to get X/Y on a path at [idx + frac]
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
     * Draw faint grid lines (optional).
     */
    function drawGrid() {
        ctx.save();
        ctx.strokeStyle = 'rgba(26,115,232,0.05)';
        ctx.lineWidth = 1;

        const cols = Math.floor(canvas.width / gridSize);
        const rows = Math.floor(canvas.height / gridSize);

        // vertical
        for (let c = 0; c <= cols; c++) {
            const x = c * gridSize;
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, canvas.height);
            ctx.stroke();
        }
        // horizontal
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
     * Convert a color like "hsl(...)" or "#rrggbb" to an RGB string "r,g,b".
     * For simplicity, here's a quick approach that handles #hex only.
     * If you want to handle HSL, you'd parse that or use a small color parser.
     */
    function hexToRgb(color) {
        // If it’s #hex
        if (color.startsWith('#')) {
            const hex = color.replace('#', '');
            const bigint = parseInt(hex, 16);
            const r = (bigint >> 16) & 255;
            const g = (bigint >> 8) & 255;
            const b = bigint & 255;
            return `${r},${g},${b}`;
        }
        // If it’s hsl(...) we do a quick approximate:
        if (color.startsWith('hsl')) {
            // hsl(210,70%,50%)
            // parse out numbers
            const hslMatch = color.match(/hsl\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%\s*\)/i);
            if (hslMatch) {
                const h = parseFloat(hslMatch[1]);
                const s = parseFloat(hslMatch[2]) / 100;
                const l = parseFloat(hslMatch[3]) / 100;
                // Quick conversion HSL -> RGB
                const rgb = hslToRgb(h, s, l);
                return `${rgb.r},${rgb.g},${rgb.b}`;
            }
        }
        // fallback
        return '255,255,255';
    }

    /**
     * Minimal HSL->RGB converter. Returns object {r,g,b}
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
    // 4) MAIN ANIMATION LOOP
    // -----------------------------------------------------------
    let lastTimestamp = 0;
    function drawEverything(timestamp = 0) {
        const deltaTime = timestamp - lastTimestamp;
        lastTimestamp = timestamp;

        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Optionally draw your static grid
        drawGrid();

        // Draw signals first
        drawSignals(deltaTime);

        // Draw nodes on top
        drawNodes();

        // Possibly create random signals (small chance each frame)
        if (Math.random() < 0.01) {
            createSignal();
        }

        animationFrameId = requestAnimationFrame(drawEverything);
    }

    // -----------------------------------------------------------
    // 5) INITIALIZATION
    // -----------------------------------------------------------
    resizeCanvas();
    initNodes();

    // Attach a throttled resize
    eventManager.addEvent(window, 'resize', throttle(resizeCanvas, 250));

    // Start the loop
    drawEverything();

    // Return a dispose if needed
    return () => {
        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
        }
    };
}
