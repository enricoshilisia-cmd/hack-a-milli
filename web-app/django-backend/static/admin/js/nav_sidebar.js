'use strict';
{
    const toggleNavSidebar = document.getElementById('toggle-nav-sidebar');
    if (toggleNavSidebar !== null) {
        const navSidebar = document.getElementById('nav-sidebar');
        const main = document.getElementById('main');
        let navSidebarIsOpen = localStorage.getItem('django.admin.navSidebarIsOpen');
        if (navSidebarIsOpen === null) {
            navSidebarIsOpen = 'true';
        }
        main.classList.toggle('shifted', navSidebarIsOpen === 'true');
        navSidebar.setAttribute('aria-expanded', navSidebarIsOpen);
        // Add ARIA label for toggle button
        toggleNavSidebar.setAttribute('aria-label', navSidebarIsOpen === 'true' ? 'Collapse sidebar' : 'Expand sidebar');

        toggleNavSidebar.addEventListener('click', function() {
            if (navSidebarIsOpen === 'true') {
                navSidebarIsOpen = 'false';
                toggleNavSidebar.setAttribute('aria-label', 'Expand sidebar');
                toggleNavSidebar.classList.remove('opened');
                toggleNavSidebar.classList.add('closed');
            } else {
                navSidebarIsOpen = 'true';
                toggleNavSidebar.setAttribute('aria-label', 'Collapse sidebar');
                toggleNavSidebar.classList.remove('closed');
                toggleNavSidebar.classList.add('opened');
            }
            localStorage.setItem('django.admin.navSidebarIsOpen', navSidebarIsOpen);
            main.classList.toggle('shifted');
            navSidebar.setAttribute('aria-expanded', navSidebarIsOpen);
        });
    }

    function initSidebarQuickFilter() {
        const options = [];
        const navSidebar = document.getElementById('nav-sidebar');
        if (!navSidebar) {
            return;
        }
        navSidebar.querySelectorAll('th[scope=row] a').forEach((container) => {
            options.push({title: container.innerHTML, node: container});
        });

        function checkValue(event) {
            let filterValue = event.target.value;
            if (filterValue) {
                filterValue = filterValue.toLowerCase();
            }
            if (event.key === 'Escape') {
                filterValue = '';
                event.target.value = ''; // clear input
            }
            let matches = false;
            for (const o of options) {
                let displayValue = '';
                if (filterValue) {
                    if (o.title.toLowerCase().indexOf(filterValue) === -1) {
                        displayValue = 'none';
                    } else {
                        matches = true;
                    }
                }
                // show/hide parent <TR>
                o.node.parentNode.parentNode.style.display = displayValue;
            }
            if (!filterValue || matches) {
                event.target.classList.remove('no-results');
            } else {
                event.target.classList.add('no-results');
            }
            sessionStorage.setItem('django.admin.navSidebarFilterValue', filterValue);
        }

        const nav = document.getElementById('nav-filter');
        if (nav) {
            nav.setAttribute('aria-label', 'Filter sidebar items');
            nav.addEventListener('change', checkValue, false);
            nav.addEventListener('input', checkValue, false);
            nav.addEventListener('keyup', checkValue, false);

            const storedValue = sessionStorage.getItem('django.admin.navSidebarFilterValue');
            if (storedValue) {
                nav.value = storedValue;
                checkValue({target: nav, key: ''});
            }

            // Add clear filter button
            const clearButton = document.createElement('button');
            clearButton.textContent = 'Clear';
            clearButton.classList.add('clear-filter');
            clearButton.setAttribute('aria-label', 'Clear sidebar filter');
            clearButton.addEventListener('click', () => {
                nav.value = '';
                checkValue({target: nav, key: ''});
                nav.focus();
            });
            nav.parentNode.appendChild(clearButton);
        }
    }
    window.initSidebarQuickFilter = initSidebarQuickFilter;
    initSidebarQuickFilter();
}