import { EventManager, throttle } from '../utils/Performance.js';

export function setupGridAnimation() {
    // ----------------------------------------------------------------
    // 1) CANVAS & CONFIG
    // ----------------------------------------------------------------
    const canvas = document.getElementById('gridCanvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let animationFrameId;
    const eventManager = new EventManager();

    // -- Adjustable configuration constants --
    const gridSize = 40;                 // distance between grid lines
    const nodeRadius = 5;                // radius for each permanent node
    const SIGNAL_SPEED = 0.05;           // speed in px/ms
    const SEND_COOLDOWN = 10000;         // ms cooldown after sending
    const TOTAL_NODES = 20;              // number of permanent nodes

    const MAX_CONCURRENT_RECEIVES = 3;   // each node can receive up to N signals at once

    // The “tail only starts after head arrives” approach means each signal
    // travels for 2 * totalLength along the path
    // (Phase 1: head 0..totalLen, Phase 2: tail 0..totalLen)

    // Tail fade control: 0 = fully transparent, 1 = fully opaque
    const TAIL_FADE_START = 0.2;
    const TAIL_FADE_END = 1.0;

    // Predefined signals
    const signalsCatalog = [
        'GET: /.well-known/ocm (Discovery)',
        'POST: /shares (Create Share)',
        'POST: /notifications (Send Notification)',
        'POST: /invite-accepted (Invite Accepted)',
        'POST: /token (Exchange Code)',
        'POST: /invite (Invite Flow)'
    ];

    // Example EU institutions
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

    // Data arrays
    let nodes = [];
    let signals = [];

    // ----------------------------------------------------------------
    // 2) HELPER FUNCTIONS
    // ----------------------------------------------------------------
    function randomColor() {
        return `hsl(${Math.floor(Math.random() * 360)}, 70%, 50%)`;
    }

    function getNodeName(idx) {
        if (idx < EU_INSTITUTIONS.length) {
            const institution = EU_INSTITUTIONS[idx];
            const plat = PLATFORMS[Math.floor(Math.random() * PLATFORMS.length)];
            return `${institution} - ${plat}`;
        } else {
            const first = FALLBACK_FIRST[Math.floor(Math.random() * FALLBACK_FIRST.length)];
            const second = NATO_ALPHABET[Math.floor(Math.random() * NATO_ALPHABET.length)];
            return `${first} ${second}`;
        }
    }

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
     * Create permanent nodes at random grid intersections
     * and track concurrency states:
     *   - isSending (bool): can only send 1 at a time
     *   - currentIncoming (count): up to MAX_CONCURRENT_RECEIVES
     *   - nextSendAllowed (timestamp) for cooldown
     *   - lastReceiver (track last node used as receiver)
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
        const selected = intersections.slice(0, TOTAL_NODES);

        selected.forEach((coords, idx) => {
            nodes.push({
                x: coords.x,
                y: coords.y,
                color: randomColor(),
                name: getNodeName(idx),
                isSending: false,
                currentIncoming: 0,
                nextSendAllowed: 0,
                lastReceiver: null
            });
        });
    }

    /**
     * Build a path along the grid lines from src to dst
     */
    function findPath(src, dst) {
        const path = [{ x: src.x, y: src.y }];
        let current = { x: src.x, y: src.y };
        while (current.x !== dst.x || current.y !== dst.y) {
            // horizontally first
            if (current.x !== dst.x) {
                current.x += gridSize * (current.x < dst.x ? 1 : -1);
                path.push({ x: current.x, y: current.y });
            }
            // then vertically
            else if (current.y !== dst.y) {
                current.y += gridSize * (current.y < dst.y ? 1 : -1);
                path.push({ x: current.x, y: current.y });
            }
        }
        return path;
    }

    /**
     * Compute segment lengths + cumulative lengths
     */
    function precomputeDistances(path) {
        const segmentLengths = [];
        const cumulativeLengths = [0];
        let totalLength = 0;

        for (let i = 0; i < path.length - 1; i++) {
            const dx = path[i + 1].x - path[i].x;
            const dy = path[i + 1].y - path[i].y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            segmentLengths.push(dist);
            totalLength += dist;
            cumulativeLengths.push(totalLength);
        }
        return { segmentLengths, cumulativeLengths, totalLength };
    }

    /**
     * Find which segment 'dist' is on, plus fraction along that segment
     */
    function getSegmentIndexFrac(dist, cumulativeLengths) {
        const lastIndex = cumulativeLengths.length - 1;
        if (dist <= 0) return { index: 0, frac: 0 };

        const totalLen = cumulativeLengths[lastIndex];
        if (dist >= totalLen) return { index: lastIndex - 1, frac: 1 };

        let seg = 0;
        while (seg < lastIndex && cumulativeLengths[seg] <= dist) {
            seg++;
        }
        const distBefore = cumulativeLengths[seg - 1] || 0;
        const segmentDist = cumulativeLengths[seg] - distBefore;
        const localDist = dist - distBefore;
        const frac = localDist / segmentDist;
        return { index: seg - 1, frac };
    }

    /**
     * Interpolate x,y for path segment
     */
    function interpolate(path, indexFrac) {
        const { index, frac } = indexFrac;
        const p0 = path[index];
        const p1 = path[index + 1] || p0;
        return {
            x: p0.x + (p1.x - p0.x) * frac,
            y: p0.y + (p1.y - p0.y) * frac
        };
    }

    /**
     * Create a new signal from a random available sender to a random receiver
     * applying:
     *   - One-signal-at-a-time sending (isSending = false)
     *   - up to N concurrent receives (currentIncoming < MAX_CONCURRENT_RECEIVES)
     *   - optional cooldown
     *   - skip lastReceiver if possible
     */
    function createSignal() {
        const now = performance.now();

        // 1) pick from nodes that are not sending & are past cooldown
        const availableSenders = nodes.filter(n => {
            return !n.isSending && now >= n.nextSendAllowed;
        });
        if (availableSenders.length < 1) return; // no senders available

        // 2) pick random sender
        const sender = availableSenders[Math.floor(Math.random() * availableSenders.length)];

        // 3) gather possible receivers
        //    skip self, skip those at max concurrency
        //    skip lastReceiver if possible
        let possibleReceivers = nodes.filter(r => {
            if (r === sender) return false;
            if (r.currentIncoming >= MAX_CONCURRENT_RECEIVES) return false;
            return r !== sender.lastReceiver; // skip last used if possible
        });
        if (possibleReceivers.length < 1) {
            // fallback: allow lastReceiver if everything else fails
            possibleReceivers = nodes.filter(r => {
                if (r === sender) return false;
                return r.currentIncoming < MAX_CONCURRENT_RECEIVES;
            });
            if (possibleReceivers.length < 1) return; // no receivers available
        }

        // 4) pick random from possibleReceivers
        const receiver = possibleReceivers[Math.floor(Math.random() * possibleReceivers.length)];

        // 5) Mark concurrency states
        sender.isSending = true;
        sender.nextSendAllowed = now + SEND_COOLDOWN; // cooldown
        sender.lastReceiver = receiver;

        receiver.currentIncoming += 1; // increment

        // 6) find path & precompute distances
        const path = findPath(sender, receiver);
        const { segmentLengths, cumulativeLengths, totalLength } = precomputeDistances(path);

        // 7) pick random label
        const signalLabel = signalsCatalog[Math.floor(Math.random() * signalsCatalog.length)];

        // 8) push the new signal
        signals.push({
            source: sender,
            target: receiver,
            path,
            segmentLengths,
            cumulativeLengths,
            totalLength,
            distanceTravelled: 0, // goes 0..2*totalLength
            label: signalLabel,
            color: sender.color,
            hasFreedNodes: false,
            onComplete: () => {
                // once head arrives, free up the sender
                sender.isSending = false;
            }
        });
    }

    // ----------------------------------------------------------------
    // 3) DRAWING LOGIC
    // ----------------------------------------------------------------
    function drawNodes() {
        nodes.forEach(node => {
            ctx.beginPath();
            ctx.fillStyle = node.color;
            ctx.arc(node.x, node.y, nodeRadius, 0, Math.PI * 2);
            ctx.fill();

            // label
            ctx.font = '12px "JetBrains Mono"';
            ctx.fillStyle = '#333';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'top';
            ctx.fillText(node.name, node.x, node.y + nodeRadius + 4);

            // debug concurrency? (optional)
            // ctx.font = '10px "JetBrains Mono"';
            // ctx.fillStyle = '#999';
            // ctx.fillText(`IN:${node.currentIncoming}`, node.x, node.y - 12);
        });
    }

    /**
     * Draw faint grid lines
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
     * Draw a partial stepped path from tailDist..headDist
     */
    function drawSteppedPath(path, cumulativeLengths, tailDist, headDist, color) {
        const tailInfo = getSegmentIndexFrac(tailDist, cumulativeLengths);
        const headInfo = getSegmentIndexFrac(headDist, cumulativeLengths);

        const tailPt = interpolate(path, tailInfo);
        const headPt = interpolate(path, headInfo);

        const gradient = ctx.createLinearGradient(tailPt.x, tailPt.y, headPt.x, headPt.y);
        gradient.addColorStop(0, `rgba(${hexToRgb(color)}, ${TAIL_FADE_START})`);
        gradient.addColorStop(1, `rgba(${hexToRgb(color)}, ${TAIL_FADE_END})`);

        ctx.strokeStyle = gradient;
        ctx.lineWidth = 3;

        ctx.beginPath();
        ctx.moveTo(tailPt.x, tailPt.y);

        // if in the same segment
        if (tailInfo.index === headInfo.index) {
            ctx.lineTo(headPt.x, headPt.y);
            ctx.stroke();
            return;
        }

        // finish the tail’s segment
        const tailSegmentEnd = path[tailInfo.index + 1];
        ctx.lineTo(tailSegmentEnd.x, tailSegmentEnd.y);

        // draw intermediate full segments
        for (let i = tailInfo.index + 1; i < headInfo.index; i++) {
            ctx.lineTo(path[i + 1].x, path[i + 1].y);
        }

        // partial segment for the head
        if (headInfo.index < path.length - 1) {
            ctx.lineTo(headPt.x, headPt.y);
        }
        ctx.stroke();
    }

    /**
     * Animate each signal in two phases:
     *  Phase 1) 0..totalLen => line from 0..headDist
     *  Phase 2) totalLen..(2*totalLen) => line from tailDist..totalLen
     */
    function drawSignals(deltaTime) {
        signals.forEach(signal => {
            signal.distanceTravelled += SIGNAL_SPEED * deltaTime;
            const dist = signal.distanceTravelled;
            const totalLen = signal.totalLength;

            let headDist, tailDist;
            if (dist < totalLen) {
                // Phase 1
                headDist = dist;
                tailDist = 0;
            } else {
                // Phase 2
                headDist = totalLen;
                tailDist = dist - totalLen; // 0..totalLen
            }

            // clamp tailDist
            if (tailDist < 0) tailDist = 0;
            if (tailDist > totalLen) tailDist = totalLen;

            // draw the stepped path
            drawSteppedPath(
                signal.path,
                signal.cumulativeLengths,
                tailDist,
                headDist,
                signal.color
            );

            // draw the “head” circle
            const headInfo = getSegmentIndexFrac(headDist, signal.cumulativeLengths);
            const headPt = interpolate(signal.path, headInfo);

            ctx.beginPath();
            ctx.fillStyle = signal.color;
            ctx.arc(headPt.x, headPt.y, 4, 0, 2 * Math.PI);
            ctx.fill();

            // traveling label
            ctx.font = '10px "JetBrains Mono"';
            ctx.fillStyle = '#444';
            ctx.textAlign = 'left';
            ctx.textBaseline = 'bottom';
            ctx.fillText(signal.label, headPt.x + 6, headPt.y - 6);

            // once head arrives, free up sender if not done
            if (!signal.hasFreedNodes && dist >= totalLen) {
                signal.onComplete?.();
                signal.hasFreedNodes = true;
            }
        });

        // remove signals that fully finished
        // (distanceTravelled >= 2*totalLength => tail has arrived)
        // also free the receiver concurrency here
        signals = signals.filter(s => {
            const keep = s.distanceTravelled < 2 * s.totalLength;
            if (!keep) {
                // the tail has fully arrived => free concurrency on receiver
                s.target.currentIncoming = Math.max(s.target.currentIncoming - 1, 0);
            }
            return keep;
        });
    }

    // ----------------------------------------------------------------
    // 4) COLOR UTILS
    // ----------------------------------------------------------------
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

    // ----------------------------------------------------------------
    // 5) MAIN ANIMATION LOOP
    // ----------------------------------------------------------------
    let lastTimestamp = 0;
    function drawEverything(timestamp = 0) {
        const deltaTime = timestamp - lastTimestamp;
        lastTimestamp = timestamp;

        ctx.clearRect(0, 0, canvas.width, canvas.height);

        drawGrid();
        drawSignals(deltaTime);
        drawNodes();

        // small chance each frame to spawn a new signal
        if (Math.random() < 0.01) {
            createSignal();
        }

        animationFrameId = requestAnimationFrame(drawEverything);
    }

    // ----------------------------------------------------------------
    // 6) INITIALIZATION
    // ----------------------------------------------------------------
    resizeCanvas();
    initNodes();

    // Attach a throttled resize
    eventManager.addEvent(window, 'resize', throttle(resizeCanvas, 250));

    // Start the loop
    drawEverything();

    // Return a dispose method if needed
    return () => {
        if (animationFrameId) {
            cancelAnimationFrame(animationFrameId);
        }
        eventManager.removeAll();
    };
}
