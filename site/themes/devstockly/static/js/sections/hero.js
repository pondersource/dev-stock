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

    function init() {
        setupExploreButton();
        setupScrollDownButton();
        setupBackgroundParallax();
        setupResourceCards();
    }

    function dispose() {
        eventManager.removeAll();
    }

    return {
        init,
        dispose
    };
}
