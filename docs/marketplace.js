const toolkitEndpoint = '/api/public/products/coco-office/toolkits';

const marketplace = {
  items: [],
  category: '全部',
  query: '',
  request: 0,
  status: 'loading',
  page: 0,
  pageSize: 20,
  total: 0,
  hasMore: false,
  loadingMore: false,
};

const grid = document.querySelector('#marketplace-grid');
const filters = document.querySelector('#marketplace-filters');
const summary = document.querySelector('#marketplace-summary');
const empty = document.querySelector('#marketplace-empty');
const error = document.querySelector('#marketplace-error');
const search = document.querySelector('#marketplace-search');
const searchForm = document.querySelector('#marketplace-search-form');
const clearSearch = document.querySelector('.marketplace-search-clear');
const loadMore = document.querySelector('#marketplace-load-more');
const loadMoreLabel = loadMore.querySelector('span');
const loadMoreButton = loadMore.querySelector('button');
const controls = document.querySelector('.marketplace-controls');
const controlsSentinel = document.querySelector('.marketplace-controls-sentinel');
const lightbox = document.querySelector('#marketplace-lightbox');
const lightboxTitle = document.querySelector('#marketplace-lightbox-title');
const lightboxCount = document.querySelector('#marketplace-lightbox-count');
const lightboxImage = document.querySelector('#marketplace-lightbox-image');
const lightboxPrevious = document.querySelector('.marketplace-lightbox-previous');
const lightboxNext = document.querySelector('.marketplace-lightbox-next');
const lightboxClose = document.querySelector('.marketplace-lightbox-close');
const galleryState = { item: null, index: 0 };

const firstText = (...values) => values.find(value => typeof value === 'string' && value.trim())?.trim() || '';
const asLabel = value => typeof value === 'string' ? value.trim() : firstText(value?.name, value?.title, value?.label);
const asList = value => Array.isArray(value) ? value.map(asLabel).filter(Boolean) : (asLabel(value) ? [asLabel(value)] : []);
const typeLabels = { word: 'Word', excel: 'Excel', ppt: 'PPT', powerpoint: 'PPT' };
const productionWebsiteHosts = new Set(['cooco.me', 'www.cooco.me']);

function trialUrl(toolId) {
  const isProductionWebsite = productionWebsiteHosts.has(window.location.hostname);
  const url = isProductionWebsite
    ? new URL('https://chat.cooco.me/')
    : new URL(window.location.href);
  if (!isProductionWebsite) {
    url.protocol = 'http:';
    url.port = '9530';
    url.pathname = '/';
    url.search = '';
    url.hash = '';
  }
  url.searchParams.set('open', 'application-tool');
  url.searchParams.set('toolId', toolId);
  return url.href;
}

function formatDate(value) {
  if (typeof value !== 'string' || !value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(date)
    .replaceAll('/', '-');
}

function downloadCount(raw) {
  for (const value of [raw.downloads, raw.downloadCount, raw.download_count, raw.installCount, raw.install_count]) {
    const count = Number(value);
    if (Number.isFinite(count) && count >= 0) return Math.floor(count);
  }
  return null;
}

function formatDownloads(value) {
  return new Intl.NumberFormat('zh-CN', value >= 10000
    ? { notation: 'compact', maximumFractionDigits: 1 }
    : { maximumFractionDigits: 0 }).format(value);
}

function unwrapItems(payload) {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== 'object') return [];
  for (const key of ['items', 'toolkits', 'products', 'results', 'list', 'records']) {
    if (Array.isArray(payload[key])) return payload[key];
  }
  if (payload.data !== payload) return unwrapItems(payload.data);
  return [];
}

function pagination(payload, itemCount) {
  const source = payload?.data && typeof payload.data === 'object' && !Array.isArray(payload.data) ? payload.data : payload;
  const page = Number(source?.page);
  const pageSize = Number(source?.pageSize ?? source?.page_size);
  const total = Number(source?.total);
  return {
    page: Number.isFinite(page) && page > 0 ? page : 1,
    pageSize: Number.isFinite(pageSize) && pageSize > 0 ? pageSize : marketplace.pageSize,
    total: Number.isFinite(total) && total >= 0 ? total : itemCount,
  };
}

function safeUrl(value) {
  if (typeof value !== 'string' || !value.trim()) return '';
  try {
    const url = new URL(value, window.location.href);
    return ['http:', 'https:'].includes(url.protocol) ? url.href : '';
  } catch {
    return '';
  }
}

function imageUrls(raw) {
  const source = [raw.imageUrls, raw.image_urls, raw.images, raw.screenshots].find(Array.isArray) || [];
  return [...new Set(source.map(image => safeUrl(typeof image === 'string'
    ? image
    : firstText(image?.url, image?.src, image?.imageUrl, image?.image_url))).filter(Boolean))];
}

function normalizeToolkit(raw, index) {
  if (!raw || typeof raw !== 'object') return null;
  const name = firstText(raw.name, raw.title, raw.displayName, raw.display_name);
  if (!name) return null;
  const targets = [...new Set(asList(raw.types)
    .map(type => type.toLocaleLowerCase('en-US'))
    .map(type => type === 'powerpoint' ? 'ppt' : type)
    .filter(type => type === 'word' || type === 'excel' || type === 'ppt'))];
  const categories = [...new Set([
    ...asList(raw.category),
    ...asList(raw.categories),
    ...asList(raw.tags),
    ...asList(raw.types).map(type => typeLabels[type.toLocaleLowerCase('en-US')] || type),
  ])];
  const publisher = asLabel(raw.publisher) || asLabel(raw.developer) || asLabel(raw.author) || 'Coco Office';
  return {
    id: firstText(String(raw.id ?? ''), raw.slug) || `toolkit-${index}`,
    name,
    description: firstText(raw.summary, raw.description, raw.shortDescription, raw.short_description) || '打开应用查看可用能力与使用方式。',
    category: categories[0] || '其他',
    categories,
    targets,
    publisher,
    version: firstText(raw.version, raw.releaseVersion, raw.release_version),
    date: formatDate(firstText(raw.updatedAt, raw.updated_at, raw.uploadedAt, raw.uploaded_at, raw.createdAt, raw.created_at)),
    downloads: downloadCount(raw),
    images: imageUrls(raw),
    featured: Boolean(raw.featured ?? raw.isFeatured ?? raw.is_featured ?? raw.recommended),
  };
}

function createElement(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text) element.textContent = text;
  return element;
}

function createCard(item) {
  const article = createElement('article', 'marketplace-card');
  const content = createElement('div');

  const head = createElement('div', 'marketplace-card-head');
  const title = createElement('div');
  title.append(createElement('h3', '', item.name));
  head.append(title);
  if (item.downloads !== null) {
    const downloads = createElement('span', 'marketplace-card-downloads');
    downloads.setAttribute('aria-label', `${item.downloads.toLocaleString('zh-CN')} 次下载`);
    const icon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    icon.setAttribute('viewBox', '0 0 24 24');
    icon.setAttribute('aria-hidden', 'true');
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', 'M12 3v11m0 0 4-4m-4 4-4-4M5 19h14');
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', 'currentColor');
    path.setAttribute('stroke-width', '1.8');
    path.setAttribute('stroke-linecap', 'round');
    path.setAttribute('stroke-linejoin', 'round');
    icon.append(path);
    downloads.append(icon, createElement('span', '', formatDownloads(item.downloads)));
    head.append(downloads);
  }

  const description = createElement('p', 'marketplace-card-description', item.description);
  content.append(head, description);
  if (item.images.length) {
    const gallery = createElement('div', 'marketplace-card-gallery');
    gallery.setAttribute('aria-label', `${item.name} 图片`);
    for (const [index, source] of item.images.entries()) {
      const button = createElement('button', 'marketplace-card-image');
      button.type = 'button';
      button.dataset.itemId = item.id;
      button.dataset.galleryIndex = String(index);
      button.setAttribute('aria-label', `查看 ${item.name} 第 ${index + 1} 张图片`);
      const image = document.createElement('img');
      image.src = source;
      image.alt = '';
      image.loading = 'lazy';
      image.decoding = 'async';
      image.addEventListener('error', () => button.remove(), { once: true });
      button.append(image);
      gallery.append(button);
    }
    content.append(gallery);
  }
  const foot = createElement('div', 'marketplace-card-foot');
  const metadata = createElement('div', 'marketplace-card-meta');
  metadata.append(createElement('span', 'marketplace-card-category', item.categories.join(' · ') || item.category));
  if (item.date) metadata.append(createElement('span', 'marketplace-card-date', item.date));
  foot.append(metadata);
  if (item.targets.includes('excel')) {
    const action = createElement('a', 'marketplace-card-action', '试用 →');
    action.href = trialUrl(item.id);
    action.target = '_blank';
    action.rel = 'noopener noreferrer';
    foot.append(action);
  }
  content.append(foot);
  article.append(content);
  return article;
}

function renderLightbox() {
  if (!galleryState.item) return;
  const images = galleryState.item.images;
  galleryState.index = (galleryState.index + images.length) % images.length;
  lightboxTitle.textContent = galleryState.item.name;
  lightboxCount.textContent = `${galleryState.index + 1} / ${images.length}`;
  lightboxImage.src = images[galleryState.index];
  lightboxImage.alt = `${galleryState.item.name} 第 ${galleryState.index + 1} 张图片`;
  lightboxPrevious.hidden = images.length < 2;
  lightboxNext.hidden = images.length < 2;
}

function openLightbox(item, index) {
  galleryState.item = item;
  galleryState.index = index;
  renderLightbox();
  lightbox.showModal();
}

function moveLightbox(step) {
  if (!galleryState.item || galleryState.item.images.length < 2) return;
  galleryState.index += step;
  renderLightbox();
}

function getCategories() {
  const counts = new Map([['全部', marketplace.total]]);
  for (const item of marketplace.items) {
    for (const category of item.categories.length ? item.categories : [item.category]) {
      counts.set(category, (counts.get(category) || 0) + 1);
    }
  }
  return [...counts.entries()].sort((a, b) => a[0] === '全部' ? -1 : b[1] - a[1] || a[0].localeCompare(b[0], 'zh-CN'));
}

function renderFilters() {
  filters.replaceChildren();
  for (const [category, count] of getCategories()) {
    const button = createElement('button', 'marketplace-filter');
    button.type = 'button';
    button.dataset.category = category;
    button.setAttribute('aria-pressed', String(category === marketplace.category));
    button.append(document.createTextNode(category), createElement('span', 'num', String(count)));
    filters.append(button);
  }
}

function visibleItems() {
  const query = marketplace.query.trim().toLocaleLowerCase('zh-CN');
  return marketplace.items.filter(item => {
    const categoryMatches = marketplace.category === '全部' || item.categories.includes(marketplace.category) || item.category === marketplace.category;
    const searchable = [item.name, item.description, item.publisher, ...item.categories].join(' ').toLocaleLowerCase('zh-CN');
    return categoryMatches && (!query || searchable.includes(query));
  });
}

function renderItems() {
  if (marketplace.status !== 'ready') return;
  const items = visibleItems();
  grid.removeAttribute('aria-busy');
  grid.replaceChildren(...items.map(createCard));
  grid.hidden = items.length === 0;
  empty.hidden = items.length !== 0;
  error.hidden = true;
  summary.textContent = marketplace.query || marketplace.category !== '全部'
    ? `找到 ${marketplace.category === '全部' ? marketplace.total : items.length} 个应用`
    : `共 ${marketplace.total} 个应用`;
}

function updateLoadMore() {
  loadMore.hidden = !marketplace.hasMore;
  loadMoreLabel.hidden = false;
  loadMoreLabel.textContent = marketplace.loadingMore ? '正在加载更多' : '继续向下滚动加载';
  loadMoreButton.hidden = true;
}

function setLoading() {
  marketplace.status = 'loading';
  marketplace.page = 0;
  marketplace.total = 0;
  marketplace.hasMore = false;
  marketplace.loadingMore = false;
  grid.hidden = false;
  grid.setAttribute('aria-busy', 'true');
  grid.replaceChildren(...Array.from({ length: 6 }, () => createElement('div', 'marketplace-skeleton')));
  empty.hidden = true;
  error.hidden = true;
  loadMore.hidden = true;
  summary.textContent = '正在读取应用列表';
}

function setError() {
  marketplace.status = 'error';
  grid.hidden = true;
  empty.hidden = true;
  error.hidden = false;
  filters.replaceChildren();
  loadMore.hidden = true;
  summary.textContent = '未能读取应用列表';
}

function requestUrl(page) {
  const url = new URL(toolkitEndpoint, window.location.href);
  url.searchParams.set('page', String(page));
  url.searchParams.set('pageSize', String(marketplace.pageSize));
  const query = marketplace.query.trim();
  if (query) url.searchParams.set('search', query);
  return url;
}

async function loadToolkits({ reset = true } = {}) {
  if (!reset && (marketplace.loadingMore || !marketplace.hasMore)) return;
  const request = ++marketplace.request;
  const nextPage = reset ? 1 : marketplace.page + 1;
  if (reset) {
    setLoading();
  } else {
    marketplace.loadingMore = true;
    grid.setAttribute('aria-busy', 'true');
    updateLoadMore();
  }
  try {
    const response = await fetch(requestUrl(nextPage), { headers: { Accept: 'application/json' }, credentials: 'same-origin' });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const payload = await response.json();
    if (request !== marketplace.request) return;
    const received = unwrapItems(payload)
      .map(normalizeToolkit)
      .filter(Boolean);
    const pageInfo = pagination(payload, received.length);
    const combined = reset ? received : [...marketplace.items, ...received];
    marketplace.items = [...new Map(combined.map(item => [item.id, item])).values()]
      .sort((a, b) => Number(b.featured) - Number(a.featured) || a.name.localeCompare(b.name, 'zh-CN'));
    marketplace.page = pageInfo.page;
    marketplace.pageSize = pageInfo.pageSize;
    marketplace.total = pageInfo.total;
    marketplace.hasMore = marketplace.items.length < marketplace.total && received.length > 0;
    marketplace.loadingMore = false;
    marketplace.status = 'ready';
    renderFilters();
    renderItems();
    updateLoadMore();
  } catch (loadError) {
    if (request !== marketplace.request) return;
    console.warn('[coco-marketplace] Failed to load toolkits:', loadError);
    if (reset) {
      setError();
    } else {
      marketplace.loadingMore = false;
      grid.removeAttribute('aria-busy');
      loadMore.hidden = false;
      loadMoreLabel.hidden = true;
      loadMoreButton.hidden = false;
      loadMoreButton.textContent = '加载失败，点击重试';
    }
  }
}

let searchTimer;
function runSearch() {
  clearTimeout(searchTimer);
  loadToolkits({ reset: true });
}

searchForm.addEventListener('submit', event => {
  event.preventDefault();
  runSearch();
});
search.addEventListener('input', () => {
  marketplace.query = search.value;
  clearSearch.hidden = !search.value;
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => loadToolkits({ reset: true }), 280);
});
clearSearch.addEventListener('click', () => {
  search.value = '';
  marketplace.query = '';
  clearSearch.hidden = true;
  search.focus();
  runSearch();
});
filters.addEventListener('click', event => {
  const button = event.target.closest('[data-category]');
  if (!button) return;
  marketplace.category = button.dataset.category;
  for (const filter of filters.querySelectorAll('[data-category]')) filter.setAttribute('aria-pressed', String(filter === button));
  renderItems();
});
grid.addEventListener('click', event => {
  const button = event.target.closest('[data-gallery-index]');
  if (!button) return;
  const item = marketplace.items.find(candidate => candidate.id === button.dataset.itemId);
  if (item) openLightbox(item, Number(button.dataset.galleryIndex));
});
lightboxPrevious.addEventListener('click', () => moveLightbox(-1));
lightboxNext.addEventListener('click', () => moveLightbox(1));
lightboxClose.addEventListener('click', () => lightbox.close());
lightbox.addEventListener('click', event => {
  if (event.target === lightbox) lightbox.close();
});
lightbox.addEventListener('keydown', event => {
  if (event.key === 'ArrowLeft') moveLightbox(-1);
  if (event.key === 'ArrowRight') moveLightbox(1);
});
document.querySelector('.marketplace-reset').addEventListener('click', () => {
  marketplace.category = '全部';
  marketplace.query = '';
  search.value = '';
  clearSearch.hidden = true;
  renderFilters();
  loadToolkits({ reset: true });
  search.focus();
});
loadMoreButton.addEventListener('click', () => loadToolkits({ reset: false }));
for (const retry of document.querySelectorAll('.marketplace-retry')) retry.addEventListener('click', () => loadToolkits({ reset: true }));

const loadMoreObserver = new IntersectionObserver(entries => {
  if (entries.some(entry => entry.isIntersecting)) loadToolkits({ reset: false });
}, { rootMargin: '500px 0px' });
loadMoreObserver.observe(loadMore);

const stickyObserver = new IntersectionObserver(([entry]) => {
  controls.classList.toggle('is-stuck', !entry.isIntersecting);
}, { threshold: 0 });
stickyObserver.observe(controlsSentinel);

loadToolkits({ reset: true });
