for (const demo of document.querySelectorAll('[data-product-demo]')) {
  const image = demo.querySelector('[data-demo-image]');
  const caption = demo.querySelector('[data-demo-caption]');
  const steps = demo.querySelectorAll('[data-demo-step]');
  for (const step of steps) {
    step.addEventListener('click', () => {
      image.src = step.dataset.src;
      demo.dataset.view = step.dataset.view;
      image.alt = step.dataset.alt;
      caption.textContent = step.dataset.caption;
      for (const item of steps) item.setAttribute('aria-pressed', String(item === step));
    });
  }
}
