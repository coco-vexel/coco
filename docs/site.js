// Keep Coco Office as one product family while making its three working
// surfaces directly reachable from every desktop page. With JavaScript off,
// the original product-overview link remains fully usable.
for (const officeLink of document.querySelectorAll('.site-links > a[href="./products.html"]')) {
  const menu = document.createElement('details');
  menu.className = 'product-menu';
  const summary = document.createElement('summary');
  summary.textContent = 'Coco Office';
  summary.setAttribute('aria-label', '打开 Coco Office 菜单');
  if (officeLink.getAttribute('aria-current') === 'page') summary.setAttribute('aria-current', 'page');
  const panel = document.createElement('div');
  panel.className = 'product-menu-panel';
  panel.innerHTML = `
    <div class="product-menu-inner">
      <div class="product-menu-overview">
        <a href="./products.html"><strong>产品概览</strong><span>比较三种使用方式</span></a>
      </div>
      <nav class="product-menu-destinations" aria-label="Coco Office 产品入口">
        <a href="./web.html"><strong>网页版</strong><span>在浏览器中打开文档</span></a>
        <a href="./plugins.html"><strong>Office 插件</strong><span>留在熟悉的 Office 里</span></a>
        <a href="./desktop.html"><strong>桌面应用</strong><span>围绕本地文件继续工作</span></a>
      </nav>
    </div>`;
  const page = window.location.pathname.split('/').pop() || 'index.html';
  const current = page === 'products.html' ? './products.html'
    : page === 'web.html' ? './web.html'
    : ['plugins.html', 'word.html', 'excel.html', 'install.html'].includes(page) ? './plugins.html'
    : page === 'desktop.html' ? './desktop.html' : '';
  if (current) panel.querySelector(`a[href="${current}"]`)?.setAttribute('aria-current', 'page');
  menu.append(summary, panel);
  officeLink.replaceWith(menu);
}

// Keep the primary site action identical on every public page.
for (const action of document.querySelectorAll('.site-chat')) {
  action.href = 'https://chat.cooco.me';
  action.target = '_blank';
  action.rel = 'noopener noreferrer';
  action.textContent = '打开网页版 ↗';
}

// Keep developer resources grouped by product, then send external resources to a new tab.
for (const group of document.querySelectorAll('.site-footer > div')) {
  if (group.querySelector('h2')?.textContent.trim() !== '开发者') continue;
  const links = [...group.querySelectorAll('a')];
  const core = links.find(link => link.textContent.trim() === 'Core SDK');
  const editor = links.find(link => link.textContent.trim() === '浏览器编辑器');
  if (core && editor) core.after(editor);
}

for (const link of document.querySelectorAll('a[href]')) {
  const url = new URL(link.href, window.location.href);
  if (url.hostname !== 'www.npmjs.com' && url.hostname !== 'github.com') continue;
  link.target = '_blank';
  link.rel = 'noopener noreferrer';
}

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
  const activateHash = () => {
    const tab = tabs.find(item => '#' + item.getAttribute('aria-controls') === window.location.hash);
    if (tab) activate(tab);
  };
  activateHash();
  window.addEventListener('hashchange', activateHash);
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
  const summary = menu.querySelector('summary');
  const openLabel = menu.classList.contains('product-menu') ? '打开 Coco Office 菜单' : '打开导航菜单';
  const closeLabel = menu.classList.contains('product-menu') ? '关闭 Coco Office 菜单' : '关闭导航菜单';
  const syncLabel = () => summary.setAttribute('aria-label', menu.open ? closeLabel : openLabel);
  syncLabel();
  menu.addEventListener('toggle', syncLabel);
  menu.addEventListener('click', (event) => {
    if (event.target.closest('a')) menu.open = false;
  });
  menu.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
      menu.open = false;
      summary.focus();
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

for (const button of document.querySelectorAll('[data-copy-text], [data-copy-target]')) {
  button.addEventListener('click', async () => {
    const target = button.dataset.copyTarget && document.getElementById(button.dataset.copyTarget);
    const text = button.dataset.copyText || target?.textContent || '';
    if (!text) return;
    const label = button.textContent;
    try {
      await navigator.clipboard.writeText(text.trim());
      button.textContent = '已复制';
      window.setTimeout(() => { button.textContent = label; }, 1600);
    } catch {
      button.textContent = '复制失败';
      window.setTimeout(() => { button.textContent = label; }, 1600);
    }
  });
}
