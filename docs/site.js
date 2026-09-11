// Progressive enhancement for document demonstrations; no model calls or file access.
for (const group of document.querySelectorAll('[data-demo-group]')) {
  const tabs = [...group.querySelectorAll('[role="tab"]')];
  const activate = (tab, focus = false) => {
    for (const item of tabs) {
      const selected = item === tab;
      item.setAttribute('aria-selected', String(selected));
      item.tabIndex = selected ? 0 : -1;
      const panel = document.getElementById(item.getAttribute('aria-controls'));
      if (panel) panel.hidden = !selected;
    }
    if (focus) tab.focus();
  };
  for (const tab of tabs) {
    tab.addEventListener('click', () => activate(tab));
    tab.addEventListener('keydown', (event) => {
      const index = tabs.indexOf(tab);
      const next = event.key === 'ArrowRight' ? (index + 1) % tabs.length
        : event.key === 'ArrowLeft' ? (index + tabs.length - 1) % tabs.length
        : event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1 : -1;
      if (next < 0) return;
      event.preventDefault();
      activate(tabs[next], true);
    });
  }
}
for (const menu of document.querySelectorAll('.site-menu, .product-menu')) {
  menu.addEventListener('click', (event) => {
    if (event.target.closest('a')) menu.open = false;
  });
  menu.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      menu.open = false;
      menu.querySelector('summary').focus();
    }
  });
}

const navigationMenus = [...document.querySelectorAll('.site-menu, .product-menu')];
document.addEventListener('click', (event) => {
  for (const menu of navigationMenus) {
    if (!menu.contains(event.target)) menu.open = false;
  }
});
document.addEventListener('focusin', (event) => {
  for (const menu of navigationMenus) {
    if (!menu.contains(event.target)) menu.open = false;
  }
});
// History restoration must not leave a menu covering the destination page.
window.addEventListener('pageshow', () => {
  for (const menu of navigationMenus) menu.open = false;
});
