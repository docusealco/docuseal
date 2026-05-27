'use strict';

/* ===== Method Source Code Toggling ===== */

function showSource(e) {
  let target = e.target;
  while (!target.classList.contains('method-detail')) {
    target = target.parentNode;
  }
  if (typeof target !== "undefined" && target !== null) {
    target = target.querySelector('.method-source-code');
  }
  if (typeof target !== "undefined" && target !== null) {
    target.classList.toggle('active-menu')
  }
}

function hookSourceViews() {
  document.querySelectorAll('.method-source-toggle').forEach((codeObject) => {
    codeObject.addEventListener('click', showSource);
  });
}

/* ===== Search Functionality ===== */

function createSearchInstance(input, result) {
  if (!input || !result) return null;

  result.classList.remove("initially-hidden");

  const search = new SearchController(search_data, input, result);

  search.renderItem = function(result) {
    const li = document.createElement('li');
    let html = '';

    // TODO add relative path to <script> per-page
    html += `<p class="search-match"><a href="${index_rel_prefix}${this.escapeHTML(result.path)}">${this.hlt(result.title)}`;
    if (result.params)
      html += `<span class="params">${result.params}</span>`;
    html += '</a>';

    // Add type indicator
    if (result.type) {
      const typeLabel = this.formatType(result.type);
      const typeClass = result.type.replace(/_/g, '-');
      html += `<span class="search-type search-type-${this.escapeHTML(typeClass)}">${typeLabel}</span>`;
    }

    if (result.snippet)
      html += `<div class="search-snippet">${result.snippet}</div>`;

    li.innerHTML = html;

    return li;
  }

  search.formatType = function(type) {
    const typeLabels = {
      'class': 'class',
      'module': 'module',
      'constant': 'const',
      'instance_method': 'method',
      'class_method': 'method'
    };
    return typeLabels[type] || type;
  }

  search.select = function(result) {
    window.location.href = result.firstChild.firstChild.href;
  }

  return search;
}

function hookSearch() {
  const input  = document.querySelector('#search-field');
  const result = document.querySelector('#search-results-desktop');

  if (!input || !result) return; // Exit if search elements not found

  const search_section = document.querySelector('#search-section');
  if (search_section) {
    search_section.classList.remove("initially-hidden");
  }

  const search = createSearchInstance(input, result);
  if (!search) return;

  // Hide search results when clicking outside the search area
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.navbar-search-desktop')) {
      search.hide();
    }
  });

  // Hide search results on Escape key on desktop too
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && input.matches(":focus")) {
      search.hide();
      input.blur();
    }
  });

  // Show search results when focusing on input (if there's a query)
  input.addEventListener('focus', () => {
    if (input.value.trim()) {
      search.show();
    }
  });

  // Check for ?q= URL parameter and trigger search automatically
  if (typeof URLSearchParams !== 'undefined') {
    const urlParams = new URLSearchParams(window.location.search);
    const queryParam = urlParams.get('q');
    if (queryParam) {
      input.value = queryParam;
      search.search(queryParam, false);
    }
  }
}

/* ===== Keyboard Shortcuts ===== */

function hookFocus() {
  document.addEventListener("keydown", (event) => {
    if (document.activeElement.tagName === 'INPUT') {
      return;
    }
    if (event.key === "/") {
      event.preventDefault();
      document.querySelector('#search-field').focus();
    }
  });
}

/* ===== Mobile Navigation ===== */

function hookSidebar() {
  const navigation = document.querySelector('#navigation');
  const navigationToggle = document.querySelector('#navigation-toggle');

  if (!navigation || !navigationToggle) return;

  const closeNav = () => {
    navigation.hidden = true;
    navigationToggle.ariaExpanded = 'false';
    document.body.classList.remove('nav-open');
  };

  const openNav = () => {
    navigation.hidden = false;
    navigationToggle.ariaExpanded = 'true';
    document.body.classList.add('nav-open');
  };

  const toggleNav = () => {
    if (navigation.hidden) {
      openNav();
    } else {
      closeNav();
    }
  };

  navigationToggle.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleNav();
  });

  const isSmallViewport = window.matchMedia("(max-width: 1023px)").matches;

  // The sidebar is hidden by default with the `hidden` attribute
  // On large viewports, we display the sidebar with JavaScript
  // This is better than the opposite approach of hiding it with JavaScript
  // because it avoids flickering the sidebar when the page is loaded, especially on mobile devices
  if (isSmallViewport) {
    // Close nav when clicking links inside it
    document.addEventListener('click', (e) => {
      if (e.target.closest('#navigation a')) {
        closeNav();
      }
    });

    // Close nav when clicking backdrop
    document.addEventListener('click', (e) => {
      if (!navigation.hidden &&
          !e.target.closest('#navigation') &&
          !e.target.closest('#navigation-toggle')) {
        closeNav();
      }
    });
  } else {
    openNav();
  }
}

/* ===== Right Sidebar Table of Contents ===== */

function generateToc() {
  const tocNav = document.querySelector('#toc-nav');
  if (!tocNav) return; // Exit if TOC nav doesn't exist

  const main = document.querySelector('main');
  if (!main) return;

  // Find all h2 and h3 headings in the main content
  const headings = main.querySelectorAll('h1, h2, h3');
  if (headings.length === 0) return;

  const tocList = document.createElement('ul');
  tocList.className = 'toc-list';

  headings.forEach((heading) => {
    // Skip if heading doesn't have an id
    if (!heading.id) return;

    const li = document.createElement('li');
    const level = heading.tagName.toLowerCase();
    li.className = `toc-item toc-${level}`;

    const link = document.createElement('a');
    link.href = `#${heading.id}`;
    link.className = 'toc-link';
    link.textContent = heading.textContent.trim();
    link.setAttribute('data-target', heading.id);

    li.appendChild(link);
    setHeadingScrollHandler(heading, link);
    tocList.appendChild(li);
  });

  if (tocList.children.length > 0) {
    tocNav.appendChild(tocList);
  } else {
    // Hide TOC if no headings found
    const tocContainer = document.querySelector('.table-of-contents');
    if (tocContainer) {
      tocContainer.style.display = 'none';
    }
  }
}

function hookTocActiveHighlighting() {
  const tocLinks = document.querySelectorAll('.toc-link');
  const targetHeadings = [];
  tocLinks.forEach((link) => {
    const targetId = link.getAttribute('data-target');
    const heading = document.getElementById(targetId);
    if (heading) {
      targetHeadings.push(heading);
    }
  });

  if (targetHeadings.length === 0) return;

  const observerOptions = {
    root: null,
    rootMargin: '0% 0px -35% 0px',
    threshold: 0
  };

  const intersectingHeadings = new Set();
  const update = () => {
    const firstIntersectingHeading = targetHeadings.find((heading) => {
      return intersectingHeadings.has(heading);
    });
    if (!firstIntersectingHeading) return;
    const correspondingLink = document.querySelector(`.toc-link[data-target="${firstIntersectingHeading.id}"]`);
    if (!correspondingLink) return;

    // Remove active class from all links
    tocLinks.forEach((link) => {
      link.classList.remove('active');
    });

    // Add active class to current link
    correspondingLink.classList.add('active');

    // Scroll link into view if needed
    const tocNav = document.querySelector('#toc-nav');
    if (tocNav) {
      const linkRect = correspondingLink.getBoundingClientRect();
      const navRect = tocNav.getBoundingClientRect();

      if (linkRect.top < navRect.top || linkRect.bottom > navRect.bottom) {
        correspondingLink.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
    }
  };
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        intersectingHeadings.add(entry.target);
      } else {
        intersectingHeadings.delete(entry.target);
      }
    });
    update();
  }, observerOptions);

  // Observe all headings that have corresponding TOC links
  targetHeadings.forEach((heading) => {
    observer.observe(heading);
  });
}

function setHeadingScrollHandler(heading, link) {
  // Smooth scroll to heading when clicking link
  if (!heading.id) return;

  link.addEventListener('click', (e) => {
    e.preventDefault();
    heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
    history.pushState(null, '', `#${heading.id}`);
  });
}

function setHeadingSelfLinkScrollHandlers() {
  // Clicking link inside heading scrolls smoothly to heading itself
  const headings = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
  headings.forEach((heading) => {
    if (!heading.id) return;

    const link = heading.querySelector(`a[href^="#${heading.id}"]`);
    if (link) setHeadingScrollHandler(heading, link);
  })
}

/* ===== Mobile Search Modal ===== */

function hookSearchModal() {
  const searchToggle = document.querySelector('#search-toggle');
  const searchModal = document.querySelector('#search-modal');
  const searchModalClose = document.querySelector('#search-modal-close');
  const searchModalBackdrop = document.querySelector('.search-modal-backdrop');
  const searchInput = document.querySelector('#search-field-mobile');
  const searchResults = document.querySelector('#search-results-mobile');
  const searchEmpty = document.querySelector('.search-modal-empty');

  if (!searchToggle || !searchModal) return;

  // Initialize search for mobile modal
  const mobileSearch = createSearchInstance(searchInput, searchResults);
  if (!mobileSearch) return;

  // Hide empty state when there are results
  const originalRenderItem = mobileSearch.renderItem;
  mobileSearch.renderItem = function(result) {
    if (searchEmpty) searchEmpty.style.display = 'none';
    return originalRenderItem.call(this, result);
  };

  const openSearchModal = () => {
    searchModal.hidden = false;
    document.body.style.overflow = 'hidden';
    // Focus input after animation
    setTimeout(() => {
      if (searchInput) searchInput.focus();
    }, 100);
  };

  const closeSearchModal = () => {
    searchModal.hidden = true;
    document.body.style.overflow = '';
  };

  // Open on button click
  searchToggle.addEventListener('click', openSearchModal);

  // Close on close button click
  if (searchModalClose) {
    searchModalClose.addEventListener('click', closeSearchModal);
  }

  // Close on backdrop click
  if (searchModalBackdrop) {
    searchModalBackdrop.addEventListener('click', closeSearchModal);
  }

  // Close on Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !searchModal.hidden) {
      closeSearchModal();
    }
  });

  // Check for ?q= URL parameter on mobile and open modal
  if (typeof URLSearchParams !== 'undefined') {
    const urlParams = new URLSearchParams(window.location.search);
    const queryParam = urlParams.get('q');
    const isSmallViewport = window.matchMedia("(max-width: 1023px)").matches;

    if (queryParam && isSmallViewport) {
      openSearchModal();
      searchInput.value = queryParam;
      mobileSearch.search(queryParam, false);
    }
  }
}

/* ===== Code Block Copy Functionality ===== */

function createCopyButton() {
  const button = document.createElement('button');
  button.className = 'copy-code-button';
  button.type = 'button';
  button.setAttribute('aria-label', 'Copy code to clipboard');
  button.setAttribute('title', 'Copy code');

  // Create clipboard icon SVG
  const clipboardIcon = `
    <svg viewBox="0 0 24 24">
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
      <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
    </svg>
  `;

  // Create checkmark icon SVG (for copied state)
  const checkIcon = `
    <svg viewBox="0 0 24 24">
      <polyline points="20 6 9 17 4 12"></polyline>
    </svg>
  `;

  button.innerHTML = clipboardIcon;
  button.dataset.clipboardIcon = clipboardIcon;
  button.dataset.checkIcon = checkIcon;

  return button;
}

function wrapCodeBlocksWithCopyButton() {
  // Copy buttons are generated dynamically rather than statically in rhtml templates because:
  // - Code blocks are generated by RDoc's markup formatter (RDoc::Markup::ToHtml),
  //   not directly in rhtml templates
  // - Modifying the formatter would require extending RDoc's core internals

  // Find all pre elements that are not already wrapped
  const preElements = document.querySelectorAll('main pre:not(.code-block-wrapper pre)');

  preElements.forEach((pre) => {
    // Skip if already wrapped
    if (pre.parentElement.classList.contains('code-block-wrapper')) {
      return;
    }

    // Create wrapper
    const wrapper = document.createElement('div');
    wrapper.className = 'code-block-wrapper';

    // Insert wrapper before pre
    pre.parentNode.insertBefore(wrapper, pre);

    // Move pre into wrapper
    wrapper.appendChild(pre);

    // Create and add copy button
    const copyButton = createCopyButton();
    wrapper.appendChild(copyButton);

    // Add click handler
    copyButton.addEventListener('click', () => {
      copyCodeToClipboard(pre, copyButton);
    });
  });
}

function copyCodeToClipboard(preElement, button) {
  const code = preElement.textContent;

  // Use the Clipboard API (supported by all modern browsers)
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(code).then(() => {
      showCopySuccess(button);
    }).catch(() => {
      alert('Failed to copy code.');
    });
  } else {
    alert('Failed to copy code.');
  }
}

function showCopySuccess(button) {
  // Change icon to checkmark
  button.innerHTML = button.dataset.checkIcon;
  button.classList.add('copied');
  button.setAttribute('aria-label', 'Copied!');
  button.setAttribute('title', 'Copied!');

  // Revert back after 2 seconds
  setTimeout(() => {
    button.innerHTML = button.dataset.clipboardIcon;
    button.classList.remove('copied');
    button.setAttribute('aria-label', 'Copy code to clipboard');
    button.setAttribute('title', 'Copy code');
  }, 2000);
}

/* ===== Initialization ===== */

document.addEventListener('DOMContentLoaded', () => {
  hookSourceViews();
  hookSearch();
  hookFocus();
  hookSidebar();
  generateToc();
  setHeadingSelfLinkScrollHandlers();
  hookTocActiveHighlighting();
  hookSearchModal();
  wrapCodeBlocksWithCopyButton();
});
