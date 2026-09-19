const tabs = Array.from(document.querySelectorAll('.tab'));
  const sections = tabs.map(t => document.querySelector(t.getAttribute('href')));
  const tabsContainer = document.getElementById('tabs');
  const titlebar = document.querySelector('.titlebar');

  function setActiveTab(){
    const offset = titlebar.offsetHeight + 16;
    let current = sections[0];
    for (let i = 0; i < sections.length; i++){
      if (!sections[i]) continue;
      if (sections[i].getBoundingClientRect().top - offset <= 0) current = sections[i];
    }
    const atBottom = window.innerHeight + Math.round(window.scrollY) >= document.documentElement.scrollHeight - 2;
    if (atBottom) current = sections[sections.length - 1];

    const activeTab = tabs.find(t => document.querySelector(t.getAttribute('href')) === current);
    if (!activeTab || activeTab.classList.contains('active')) return;

    tabs.forEach(t => t.classList.remove('active'));
    activeTab.classList.add('active');

    const tRect = activeTab.getBoundingClientRect();
    const cRect = tabsContainer.getBoundingClientRect();
    if (tRect.left < cRect.left || tRect.right > cRect.right){
      const delta = (tRect.left - cRect.left) - (tabsContainer.clientWidth - activeTab.clientWidth) / 2;
      tabsContainer.scrollTo({ left: tabsContainer.scrollLeft + delta, behavior: 'smooth' });
    }
  }

  let ticking = false;
  function onScroll(){
    if (!ticking){
      window.requestAnimationFrame(() => { setActiveTab(); ticking = false; });
      ticking = true;
    }
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', onScroll);
  setActiveTab();

  const revealer = new IntersectionObserver((entries) => {
    entries.forEach(entry => { if (entry.isIntersecting) { entry.target.classList.add('in'); revealer.unobserve(entry.target); } });
  }, { threshold: 0.1 });
  document.querySelectorAll('.reveal').forEach(el => revealer.observe(el));

  const start = Date.now();
  const uptimeEl = document.getElementById('uptime');
  setInterval(() => {
    const s = Math.floor((Date.now() - start) / 1000);
    const hh = String(Math.floor(s/3600)).padStart(2,'0');
    const mm = String(Math.floor((s%3600)/60)).padStart(2,'0');
    const ss = String(s%60).padStart(2,'0');
    uptimeEl.textContent = hh+':'+mm+':'+ss;
  }, 1000);

  document.getElementById('deployDate').textContent = new Date().toLocaleDateString('en-IN', { year:'numeric', month:'short' });

  const themeBtn = document.getElementById('themeToggle');

  (function typewriter(){
    const line1 = document.getElementById('typeLine1');
    const out1 = document.getElementById('typeOut1');
    const line2 = document.getElementById('typeLine2');
    const leadEl = document.querySelector('.hero .lead');
    const ctaEl = document.querySelector('.hero .cta-row');
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function reveal(){ leadEl.classList.add('show'); ctaEl.classList.add('show'); }

    if (reduceMotion){
      line1.textContent = 'whoami'; line1.classList.add('blink');
      out1.style.opacity = '1';
      line2.textContent = 'cat role.txt'; line2.classList.add('blink');
      reveal();
      return;
    }

    function type(el, text, speed, done){
      let i = 0;
      const timer = setInterval(() => {
        i++;
        el.textContent = text.slice(0, i);
        if (i >= text.length){ clearInterval(timer); el.classList.add('blink'); if (done) done(); }
      }, speed);
    }

    type(line1, 'whoami', 70, () => {
      out1.style.opacity = '1';
      setTimeout(() => {
        line1.classList.remove('blink');
        type(line2, 'cat role.txt', 55, () => setTimeout(reveal, 250));
      }, 400);
    });
  })();
  const root = document.documentElement;
  function applyTheme(t){
    root.setAttribute('data-theme', t);
    themeBtn.textContent = t === 'light' ? './theme dark' : './theme light';
    themeBtn.setAttribute('aria-pressed', t === 'light');
  }
  let currentTheme = 'dark';
  applyTheme(currentTheme);
  themeBtn.addEventListener('click', () => {
    currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
    applyTheme(currentTheme);
  });

  // Mobile -> native mail app (mailto:). Desktop -> Gmail compose in a new tab.
  const isMobile = /Android|iPhone|iPad|iPod|IEMobile|Opera Mini|Mobile/i.test(navigator.userAgent)
    || (window.matchMedia && window.matchMedia('(pointer: coarse)').matches && window.innerWidth < 900);

  document.querySelectorAll('.js-email-link').forEach(link => {
    const to = link.dataset.to;
    const cc = link.dataset.cc;
    const subject = link.dataset.subject || '';

    if (isMobile) {
      const params = new URLSearchParams();
      if (cc) params.set('cc', cc);
      if (subject) params.set('subject', subject);
      link.href = 'mailto:' + encodeURIComponent(to) + (params.toString() ? '?' + params.toString() : '');
    } else {
      const gmailUrl = new URL('https://mail.google.com/mail/');
      gmailUrl.searchParams.set('view', 'cm');
      gmailUrl.searchParams.set('fs', '1');
      gmailUrl.searchParams.set('to', to);
      if (cc) gmailUrl.searchParams.set('cc', cc);
      if (subject) gmailUrl.searchParams.set('su', subject);
      link.href = gmailUrl.toString();
      link.target = '_blank';
      link.rel = 'noopener';
    }
  });

  // Resume + certifications: open Drive PDFs inline in a modal instead of navigating away.
  (function pdfModal(){
    const modal = document.getElementById('resumeModal');
    const backdrop = document.getElementById('resumeBackdrop');
    const closeBtn = document.getElementById('resumeClose');
    const frame = document.getElementById('resumeFrame');
    const openNew = document.getElementById('resumeOpenNew');
    const titleEl = document.getElementById('resumeModalTitle');
    const triggers = document.querySelectorAll('.js-pdf-link');
    if (!modal || !triggers.length) return;

    function toPreviewUrl(driveViewUrl){
      // Converts a Drive "view" share link into an embeddable "preview" link.
      return driveViewUrl.replace(/\/view(\?.*)?$/, '/preview');
    }

    function openModal(driveUrl, title){
      frame.src = toPreviewUrl(driveUrl);
      openNew.href = driveUrl;
      if (titleEl) titleEl.textContent = title || 'document.pdf';
      modal.classList.add('open');
      modal.setAttribute('aria-hidden', 'false');
      document.body.style.overflow = 'hidden';
      closeBtn.focus();
    }

    function closeModal(){
      modal.classList.remove('open');
      modal.setAttribute('aria-hidden', 'true');
      document.body.style.overflow = '';
      frame.src = '';
    }

    triggers.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        openModal(link.getAttribute('href'), link.dataset.title);
      });
    });

    closeBtn.addEventListener('click', closeModal);
    backdrop.addEventListener('click', closeModal);
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modal.classList.contains('open')) closeModal();
    });
  })();