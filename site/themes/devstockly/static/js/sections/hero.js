import { DOMManager, EventManager, throttle } from '../utils/Performance.js';

export function initHeroSection() {
    const eventManager = new EventManager();

    function setupExploreButton() {
        const exploreBtn = DOMManager.getElement('exploreBtn');
        if (exploreBtn) {
            eventManager.addEvent(exploreBtn, 'click', () => {
                const testMatrix = document.getElementById('testMatrix');
                if (testMatrix) {
                    testMatrix.scrollIntoView({ behavior: 'smooth' });
                }
            });
        }
    }

    function setupScrollDownButton() {
        const scrollDown = DOMManager.getElement('scrollDown');
        if (scrollDown) {
            eventManager.addEvent(scrollDown, 'click', () => {
                const testMatrix = document.getElementById('testMatrix');
                if (testMatrix) {
                    testMatrix.scrollIntoView({ behavior: 'smooth' });
                }
            });
        }
    }

    function setupBackgroundParallax() {
        let lastScrollY = window.scrollY;
        let ticking = false;

        const handleParallax = () => {
            const scrolled = window.scrollY;
            const gradientCircle = document.querySelector('.gradient-circle');
            const patternGrid = document.querySelector('.pattern-grid');
            const heroContent = document.querySelector('.hero-content');

            // Only apply parallax if the device has enough height
            if (window.innerHeight > 700) {
                if (gradientCircle) {
                    gradientCircle.style.transform = `translate(${scrolled * 0.05}px, ${scrolled * 0.02}px)`;
                }

                if (patternGrid) {
                    patternGrid.style.transform = `translateY(${scrolled * 0.01}px)`;
                }

                if (heroContent) {
                    const opacity = Math.max(0, 1 - (scrolled * 0.002));
                    heroContent.style.transform = `translateY(${scrolled * 0.05}px)`;
                    heroContent.style.opacity = opacity;
                }
            }

            ticking = false;
        };

        const requestTick = () => {
            if (!ticking) {
                requestAnimationFrame(handleParallax);
                ticking = true;
            }
        };

        eventManager.addEvent(window, 'scroll', () => {
            lastScrollY = window.scrollY;
            requestTick();
        }, { passive: true });
    }

    function setupResourceCards() {
        const cards = document.querySelectorAll('.resource-card');
        const isMobile = () => window.innerWidth <= 768;

        cards.forEach(card => {
            let touchStartY = 0;
            let touchEndY = 0;

            // Mouse events
            eventManager.addEvent(card, 'mouseenter', () => {
                if (!isMobile()) {
                    card.style.transform = 'translateY(-2px)';
                }
            });

            eventManager.addEvent(card, 'mouseleave', () => {
                if (!isMobile()) {
                    card.style.transform = 'translateY(0)';
                }
            });

            // Touch events
            eventManager.addEvent(card, 'touchstart', (e) => {
                touchStartY = e.touches[0].clientY;
                card.style.transition = 'transform 0.2s ease';
            }, { passive: true });

            eventManager.addEvent(card, 'touchmove', (e) => {
                touchEndY = e.touches[0].clientY;
                const deltaY = touchEndY - touchStartY;
                
                if (deltaY < 0 && deltaY > -20) {
                    card.style.transform = `translateY(${deltaY}px)`;
                }
            }, { passive: true });

            eventManager.addEvent(card, 'touchend', () => {
                card.style.transform = 'translateY(0)';
            });
        });

        // Handle resize events
        const handleResize = throttle(() => {
            cards.forEach(card => {
                card.style.transform = 'translateY(0)';
            });
        }, 250);

        eventManager.addEvent(window, 'resize', handleResize);
    }

    // Grid Animation
    function setupGridAnimation() {
        const canvas = document.getElementById('gridCanvas');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        let animationFrameId;
        let nodes = [];
        let connections = [];
        const gridSize = 40;
        const nodeRadius = 2;
        const maxConnections = 3;
        const connectionLifetime = 4000; // 4 seconds
        const traceSpeed = 0.2;

        function resizeCanvas() {
            const rect = canvas.parentElement.getBoundingClientRect();
            canvas.width = rect.width * window.devicePixelRatio;
            canvas.height = rect.height * window.devicePixelRatio;
            ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
            canvas.style.width = rect.width + 'px';
            canvas.style.height = rect.height + 'px';

            // Recalculate nodes
            initNodes();
        }

        function initNodes() {
            nodes = [];
            const cols = Math.floor(canvas.width / gridSize);
            const rows = Math.floor(canvas.height / gridSize);

            for (let i = 0; i < rows; i++) {
                for (let j = 0; j < cols; j++) {
                    nodes.push({
                        x: j * gridSize,
                        y: i * gridSize,
                        connections: 0
                    });
                }
            }
        }

        function createConnection() {
            if (nodes.length < 2) return;

            // Find available nodes
            const availableNodes = nodes.filter(node => node.connections < maxConnections);
            if (availableNodes.length < 2) return;

            // Select random source and target nodes
            const sourceIndex = Math.floor(Math.random() * availableNodes.length);
            const source = availableNodes[sourceIndex];
            availableNodes.splice(sourceIndex, 1);
            const target = availableNodes[Math.floor(Math.random() * availableNodes.length)];

            // Calculate path through grid
            const path = findPath(source, target);

            // Create new connection
            connections.push({
                path,
                progress: 0,
                startTime: Date.now(),
                color: `rgba(26, 115, 232, ${Math.random() * 0.3 + 0.2})`,
                width: Math.random() * 1 + 1
            });

            // Update node connection counts
            source.connections++;
            target.connections++;

            // Schedule connection removal
            setTimeout(() => {
                const index = connections.indexOf(connections[connections.length - 1]);
                if (index > -1) {
                    source.connections--;
                    target.connections--;
                    connections.splice(index, 1);
                }
            }, connectionLifetime);
        }

        function findPath(start, end) {
            const path = [{ x: start.x, y: start.y }];
            let current = { x: start.x, y: start.y };

            while (current.x !== end.x || current.y !== end.y) {
                // Move horizontally first
                if (current.x !== end.x) {
                    current.x += gridSize * (current.x < end.x ? 1 : -1);
                    path.push({ x: current.x, y: current.y });
                }
                // Then vertically
                else if (current.y !== end.y) {
                    current.y += gridSize * (current.y < end.y ? 1 : -1);
                    path.push({ x: current.x, y: current.y });
                }
            }

            return path;
        }

        function drawConnections() {
            connections.forEach(connection => {
                const elapsed = Date.now() - connection.startTime;
                connection.progress = Math.min(1, elapsed / connectionLifetime);

                ctx.beginPath();
                ctx.strokeStyle = connection.color;
                ctx.lineWidth = connection.width;

                // Draw completed path
                const pathProgress = Math.min(1, elapsed * traceSpeed / connectionLifetime);
                const currentPathIndex = Math.floor(pathProgress * connection.path.length);

                for (let i = 0; i < currentPathIndex; i++) {
                    const point = connection.path[i];
                    const nextPoint = connection.path[i + 1];
                    if (nextPoint) {
                        ctx.moveTo(point.x, point.y);
                        ctx.lineTo(nextPoint.x, nextPoint.y);
                    }
                }

                // Draw current segment with partial progress
                if (currentPathIndex < connection.path.length - 1) {
                    const point = connection.path[currentPathIndex];
                    const nextPoint = connection.path[currentPathIndex + 1];
                    const segmentProgress = (pathProgress * connection.path.length) % 1;
                    
                    ctx.moveTo(point.x, point.y);
                    ctx.lineTo(
                        point.x + (nextPoint.x - point.x) * segmentProgress,
                        point.y + (nextPoint.y - point.y) * segmentProgress
                    );
                }

                ctx.stroke();
            });
        }

        function animate() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Create new connections randomly
            if (Math.random() < 0.02) { // 2% chance each frame
                createConnection();
            }

            drawConnections();
            animationFrameId = requestAnimationFrame(animate);
        }

        // Initialize
        resizeCanvas();
        eventManager.addEvent(window, 'resize', throttle(resizeCanvas, 250));
        animate();

        return () => {
            if (animationFrameId) {
                cancelAnimationFrame(animationFrameId);
            }
        };
    }

    function init() {
        setupExploreButton();
        setupScrollDownButton();
        setupBackgroundParallax();
        setupResourceCards();
        setupGridAnimation();
    }

    function dispose() {
        eventManager.removeAll();
    }

    return {
        init,
        dispose
    };
}
