export class StateManager {
    constructor(initialState = {}) {
        this.state = initialState;
        this.listeners = new Set();
        this.history = [];
    }

    getState() {
        return { ...this.state };
    }

    setState(newState, options = { persist: false }) {
        const oldState = { ...this.state };
        this.history.push(oldState);
        
        this.state = {
            ...this.state,
            ...newState
        };

        if (options.persist) {
            this.persistState();
        }

        this.notifyListeners(oldState);
    }

    subscribe(listener) {
        this.listeners.add(listener);
        return () => this.listeners.delete(listener);
    }

    notifyListeners(oldState) {
        this.listeners.forEach(listener => {
            listener(this.state, oldState);
        });
    }

    persistState() {
        try {
            localStorage.setItem('app_state', JSON.stringify(this.state));
        } catch (error) {
            console.warn('Failed to persist state:', error);
        }
    }

    loadPersistedState() {
        try {
            const persistedState = localStorage.getItem('app_state');
            if (persistedState) {
                this.setState(JSON.parse(persistedState));
            }
        } catch (error) {
            console.warn('Failed to load persisted state:', error);
        }
    }

    undo() {
        if (this.history.length > 0) {
            const previousState = this.history.pop();
            this.state = previousState;
            this.notifyListeners(this.state);
        }
    }

    reset() {
        this.state = {};
        this.history = [];
        this.notifyListeners({});
    }
} 