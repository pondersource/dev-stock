import { DOMManager, EventManager, throttle } from '../utils/Performance.js';

export function initHeroSection() {
    const eventManager = new EventManager();

    function setupExploreButton() {
        const exploreBtn = DOMManager.getElement('exploreBtn');
        if (exploreBtn) {
            eventManager.addEvent(exploreBtn, 'click', () => {
                const mainContent = DOMManager.getElement('infoSection');
                mainContent?.scrollIntoView({ behavior: 'smooth' });
            });
        }
    }

    function setupScrollDownButton() {
        const scrollDown = DOMManager.getElement('scrollDown');
        if (scrollDown) {
            eventManager.addEvent(scrollDown, 'click', () => {
                window.scrollTo({
                    top: document.documentElement.scrollHeight,
                    behavior: 'smooth'
                });
            });
        }
    }

    function setupParallax() {
        const handleParallax = throttle(() => {
            const scrolled = window.scrollY;
            const parallaxElements = document.querySelectorAll('[data-parallax]');

            DOMManager.batchUpdate(
                Array.from(parallaxElements).map(element => ({
                    id: element.id,
                    updates: {
                        style: {
                            transform: `translateY(${scrolled * parseFloat(element.dataset.parallax)}px)`
                        }
                    }
                }))
            );
        }, 16); // ~60fps

        eventManager.addEvent(window, 'scroll', handleParallax, { passive: true });
    }

    function init() {
        setupExploreButton();
        setupScrollDownButton();
        setupParallax();
    }

    function dispose() {
        eventManager.removeAll();
    }

    return {
        init,
        dispose
    };
}
