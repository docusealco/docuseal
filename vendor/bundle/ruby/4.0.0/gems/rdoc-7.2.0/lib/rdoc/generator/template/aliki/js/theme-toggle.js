(function() {
  'use strict';

  const STORAGE_KEY = 'rdoc-theme';
  const THEME_LIGHT = 'light';
  const THEME_DARK = 'dark';

  /**
   * Get the user's theme preference
   * Priority: localStorage > system preference > light (default)
   */
  function getThemePreference() {
    // Check localStorage first
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === THEME_LIGHT || stored === THEME_DARK) {
      return stored;
    }

    // Check system preference
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return THEME_DARK;
    }

    return THEME_LIGHT;
  }

  /**
   * Apply theme to document
   */
  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(STORAGE_KEY, theme);

    // Update toggle button icon
    const toggleBtn = document.getElementById('theme-toggle');
    if (toggleBtn) {
      const icon = toggleBtn.querySelector('.theme-toggle-icon');
      if (icon) {
        icon.textContent = theme === THEME_DARK ? '☀️' : '🌙';
      }
      toggleBtn.setAttribute('aria-label',
        theme === THEME_DARK ? 'Switch to light mode' : 'Switch to dark mode'
      );
    }
  }

  /**
   * Toggle between light and dark themes
   */
  function toggleTheme() {
    const currentTheme = document.documentElement.getAttribute('data-theme') || THEME_LIGHT;
    const newTheme = currentTheme === THEME_LIGHT ? THEME_DARK : THEME_LIGHT;
    applyTheme(newTheme);

    // Announce to screen readers
    announceThemeChange(newTheme);
  }

  /**
   * Announce theme change to screen readers
   */
  function announceThemeChange(theme) {
    const announcement = document.createElement('div');
    announcement.setAttribute('role', 'status');
    announcement.setAttribute('aria-live', 'polite');
    announcement.className = 'sr-only';
    announcement.textContent = `Switched to ${theme} mode`;
    document.body.appendChild(announcement);

    // Remove after announcement
    setTimeout(() => {
      document.body.removeChild(announcement);
    }, 1000);
  }

  /**
   * Initialize theme on page load
   */
  function initTheme() {
    // Apply theme immediately to prevent flash
    const theme = getThemePreference();
    applyTheme(theme);

    // Set up toggle button listener
    const toggleBtn = document.getElementById('theme-toggle');
    if (toggleBtn) {
      toggleBtn.addEventListener('click', toggleTheme);
    }

    // Listen for system theme changes
    if (window.matchMedia) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        // Only auto-switch if user hasn't manually set a preference
        const stored = localStorage.getItem(STORAGE_KEY);
        if (!stored) {
          applyTheme(e.matches ? THEME_DARK : THEME_LIGHT);
        }
      });
    }
  }

  // Initialize immediately (before DOMContentLoaded to prevent flash)
  if (document.readyState === 'loading') {
    // Apply theme as early as possible
    const theme = getThemePreference();
    document.documentElement.setAttribute('data-theme', theme);

    document.addEventListener('DOMContentLoaded', initTheme);
  } else {
    initTheme();
  }
})();
