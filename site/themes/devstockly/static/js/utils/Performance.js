export function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

export function throttle(func, limit) {
    let inThrottle;
    return function executedFunction(...args) {
        if (!inThrottle) {
            func(...args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

export class DOMManager {
    static elements = new Map();

    static getElement(id) {
        if (!this.elements.has(id)) {
            const element = document.getElementById(id);
            if (element) {
                this.elements.set(id, element);
            }
        }
        return this.elements.get(id);
    }

    static clearCache() {
        this.elements.clear();
    }

    static batchUpdate(updates) {
        requestAnimationFrame(() => {
            updates.forEach(({ id, updates }) => {
                const element = this.getElement(id);
                if (element) {
                    Object.entries(updates).forEach(([key, value]) => {
                        element[key] = value;
                    });
                }
            });
        });
    }
}

export class EventManager {
    constructor() {
        this.handlers = new Map();
    }

    addEvent(element, event, handler, options = {}) {
        const optimizedHandler = options.debounce ? 
            debounce(handler, options.debounce) : 
            options.throttle ? 
                throttle(handler, options.throttle) : 
                handler;

        element.addEventListener(event, optimizedHandler, {
            passive: options.passive ?? true,
            capture: options.capture ?? false
        });

        const key = `${element.id || 'anonymous'}-${event}`;
        this.handlers.set(key, { element, event, handler: optimizedHandler });

        return () => this.removeEvent(key);
    }

    removeEvent(key) {
        const handler = this.handlers.get(key);
        if (handler) {
            const { element, event, handler: optimizedHandler } = handler;
            element.removeEventListener(event, optimizedHandler);
            this.handlers.delete(key);
        }
    }

    removeAll() {
        this.handlers.forEach(({ element, event, handler }) => {
            element.removeEventListener(event, handler);
        });
        this.handlers.clear();
    }
} 