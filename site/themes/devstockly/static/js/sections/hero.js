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
        const handleParallax = throttle(() => {
            const scrolled = window.scrollY;
            const gradientCircle = document.querySelector('.gradient-circle');
            const patternGrid = document.querySelector('.pattern-grid');
            const heroContent = document.querySelector('.hero-content');

            if (gradientCircle) {
                gradientCircle.style.transform = `translate(${scrolled * 0.1}px, ${scrolled * 0.05}px)`;
            }

            if (patternGrid) {
                patternGrid.style.transform = `translateY(${scrolled * 0.02}px)`;
            }

            if (heroContent) {
                heroContent.style.transform = `translateY(${scrolled * 0.1}px)`;
                heroContent.style.opacity = 1 - (scrolled * 0.002);
            }
        }, 16);

        eventManager.addEvent(window, 'scroll', handleParallax, { passive: true });
    }

    function setupResourceCards() {
        const cards = document.querySelectorAll('.resource-card');
        cards.forEach(card => {
            eventManager.addEvent(card, 'mouseenter', () => {
                card.style.transform = 'translateY(-6px)';
            });

            eventManager.addEvent(card, 'mouseleave', () => {
                card.style.transform = 'translateY(0)';
            });
        });
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
