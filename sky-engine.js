(function() {
  const canvas = document.getElementById('skyCanvas');
  const ctx    = canvas.getContext('2d');
  let W, H, t  = 0;

  // ── Helpers ──────────────────────────────────────────────
  function rand(a, b) { return Math.random() * (b - a) + a; }
  function lerp(a, b, x) { return a + (b - a) * x; }
  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

  function resize() {
    W = canvas.width  = window.innerWidth;
    H = canvas.height = window.innerHeight;
  }
  window.addEventListener('resize', resize);
  resize();

  // ── Time phase detection (local timezone) ─────────────────
  const PHASES = {
    NIGHT:     'night',
    DAWN:      'dawn',
    MORNING:   'morning',
    AFTERNOON: 'afternoon',
    SUNSET:    'sunset',
    DUSK:      'dusk'
  };

  function getPhase() {
    const h = new Date().getHours() + new Date().getMinutes() / 60;
    if (h >= 5.0  && h < 6.5)  return PHASES.DAWN;
    if (h >= 6.5  && h < 12.0) return PHASES.MORNING;
    if (h >= 12.0 && h < 17.0) return PHASES.AFTERNOON;
    if (h >= 17.0 && h < 19.0) return PHASES.SUNSET;
    if (h >= 19.0 && h < 20.5) return PHASES.DUSK;
    return PHASES.NIGHT;
  }

  // ── Theme palette per phase ───────────────────────────────
  const THEMES = {
    night: {
      bg:'#09090F', bg2:'#0D0D18', surface:'#1A1A2E', surface2:'#252545',
      border:'#2D2D4E', text:'#E8E8F0', muted:'#AAAAC8', dim:'#666688',
      red:'#E05555', navBg:'rgba(9,9,15,0.88)',
      badgeIcon:'🌙', badgeLabel:'Night Mode'
    },
    dawn: {
      bg:'#0D0818', bg2:'#160D22', surface:'#1E0F2E', surface2:'#2A1540',
      border:'#3D2255', text:'#EEE0FF', muted:'#B890CC', dim:'#7A5590',
      red:'#E05580', navBg:'rgba(13,8,24,0.88)',
      badgeIcon:'🌅', badgeLabel:'Dawn'
    },
    morning: {
      bg:'#F5F0E8', bg2:'#EDE6D6', surface:'#FFFFFF', surface2:'#F8F4EC',
      border:'#D8CEBC', text:'#1A1208', muted:'#5A4E38', dim:'#9A8E78',
      red:'#C03020', navBg:'rgba(245,240,232,0.92)',
      badgeIcon:'☀️', badgeLabel:'Good Morning'
    },
    afternoon: {
      bg:'#EEF2F8', bg2:'#E4EAF4', surface:'#FFFFFF', surface2:'#F0F4FA',
      border:'#C8D4E8', text:'#0D1830', muted:'#486090', dim:'#8098B8',
      red:'#C02828', navBg:'rgba(238,242,248,0.92)',
      badgeIcon:'🌤️', badgeLabel:'Afternoon'
    },
    sunset: {
      bg:'#1A0808', bg2:'#240C0C', surface:'#301010', surface2:'#3C1414',
      border:'#5A2020', text:'#FFD0A0', muted:'#C08060', dim:'#806040',
      red:'#FF6030', navBg:'rgba(26,8,8,0.88)',
      badgeIcon:'🌇', badgeLabel:'Sunset'
    },
    dusk: {
      bg:'#0C0812', bg2:'#120E1C', surface:'#1A1428', surface2:'#221A34',
      border:'#342848', text:'#DDD0F0', muted:'#9888B8', dim:'#605878',
      red:'#CC4466', navBg:'rgba(12,8,18,0.88)',
      badgeIcon:'🌆', badgeLabel:'Dusk'
    },
    nl: {
      hero_h1: 'Het <em>mobiele commandocentrum</em><br>voor Red Team operators',
      hero_sub: 'Volg kwetsbaarheden, beheer C2-sessies — vanaf uw telefoon, beveiligd met militaire versleuteling.',
      dl_title: 'RedOps Hub downloaden',
      dl_sub: 'Gratis voor individuele operators tijdens vroege toegang.',
      feat_title: 'Alles wat een Red Team nodig heeft — in één app',
      feat_sub: 'Gebouwd voor operators die niet gebonden kunnen zijn aan een laptop tijdens een opdracht.',
      nav_dl: 'APK downloaden'
    },
    pl: {
      hero_h1: 'Mobilne <em>centrum dowodzenia</em><br>dla operatorów Red Team',
      hero_sub: 'Śledź luki, zarządzaj sesjami C2 — ze swojego telefonu, z szyfrowaniem wojskowym.',
      dl_title: 'Pobierz RedOps Hub',
      dl_sub: 'Bezpłatne dla indywidualnych operatorów podczas wczesnego dostępu.',
      feat_title: 'Wszystko, czego potrzebuje Red Team — w jednej aplikacji',
      feat_sub: 'Zbudowany dla operatorów, którzy nie mogą być przywiązani do laptopa podczas misji.',
      nav_dl: 'Pobierz APK'
    },
    id: {
      hero_h1: '<em>Pusat komando mobile</em><br>untuk operator Red Team',
      hero_sub: 'Lacak kerentanan, kelola sesi C2 — dari ponsel Anda, diamankan dengan enkripsi militer.',
      dl_title: 'Unduh RedOps Hub',
      dl_sub: 'Gratis untuk operator individu selama akses awal.',
      feat_title: 'Semua yang dibutuhkan Red Team — dalam satu aplikasi',
      feat_sub: 'Dibuat untuk operator yang tidak bisa terikat pada laptop saat operasi berlangsung.',
      nav_dl: 'Unduh APK'
    },
    fa: {
      hero_h1: '<em>مرکز فرماندهی موبایل</em><br>برای اپراتورهای Red Team',
      hero_sub: 'آسیب‌پذیری‌ها را ردیابی کنید، جلسات C2 را مدیریت کنید — از گوشی شما، با رمزگذاری نظامی.',
      dl_title: 'دانلود RedOps Hub',
      dl_sub: 'رایگان برای اپراتورهای فردی در طول دسترسی زودهنگام.',
      feat_title: 'همه چیزی که یک Red Team نیاز دارد — در یک اپ',
      feat_sub: 'ساخته شده برای اپراتورهایی که نمی‌توانند در طول یک عملیات به لپ‌تاپ وابسته باشند.',
      nav_dl: 'دانلود APK'
    },
    vi: {
      hero_h1: '<em>Trung tâm chỉ huy di động</em><br>dành cho các nhà khai thác Red Team',
      hero_sub: 'Theo dõi lỗ hổng, quản lý phiên C2 — từ điện thoại của bạn, được bảo mật bằng mã hóa quân sự.',
      dl_title: 'Tải xuống RedOps Hub',
      dl_sub: 'Miễn phí cho các nhà khai thác cá nhân trong giai đoạn truy cập sớm.',
      feat_title: 'Tất cả những gì Red Team cần — trong một ứng dụng',
      feat_sub: 'Được xây dựng cho các nhà khai thác không thể bị ràng buộc vào máy tính xách tay trong khi hoạt động.',
      nav_dl: 'Tải xuống APK'
    },
    th: {
      hero_h1: '<em>ศูนย์บัญชาการมือถือ</em><br>สำหรับผู้ปฏิบัติการ Red Team',
      hero_sub: 'ติดตามช่องโหว่, จัดการเซสชัน C2 — จากโทรศัพท์ของคุณ, ปลอดภัยด้วยการเข้ารหัสระดับทหาร.',
      dl_title: 'ดาวน์โหลด RedOps Hub',
      dl_sub: 'ฟรีสำหรับผู้ปฏิบัติการรายบุคคลในช่วงการเข้าถึงล่วงหน้า.',
      feat_title: 'ทุกสิ่งที่ Red Team ต้องการ — ในแอปเดียว',
      feat_sub: 'สร้างขึ้นสำหรับผู้ปฏิบัติการที่ไม่สามารถผูกติดกับแล็ปท็อปได้ในระหว่างปฏิบัติการ.',
      nav_dl: 'ดาวน์โหลด APK'
    },
    uk: {
      hero_h1: '<em>Мобільний командний центр</em><br>для операторів Red Team',
      hero_sub: 'Відстежуйте вразливості, керуйте сесіями C2 — зі смартфона, з військовим шифруванням.',
      dl_title: 'Завантажити RedOps Hub',
      dl_sub: 'Безкоштовно для індивідуальних операторів у період раннього доступу.',
      feat_title: 'Все, що потрібно Red Team — в одному додатку',
      feat_sub: 'Створено для операторів, які не можуть бути прив\'язані до ноутбука під час операції.',
      nav_dl: 'Завантажити APK'
    },
    sv: {
      hero_h1: 'Det <em>mobila kommandocentret</em><br>för Red Team-operatörer',
      hero_sub: 'Spåra sårbarheter, hantera C2-sessioner — från din telefon, säkrad med militär kryptering.',
      dl_title: 'Ladda ner RedOps Hub',
      dl_sub: 'Gratis för individuella operatörer under tidig åtkomst.',
      feat_title: 'Allt ett Red Team behöver — i en app',
      feat_sub: 'Byggt för operatörer som inte kan vara bundna till en laptop under ett uppdrag.',
      nav_dl: 'Ladda ner APK'
    },
    he: {
      hero_h1: '<em>מרכז הפיקוד הנייד</em><br>למפעילי Red Team',
      hero_sub: 'עקוב אחר פגיעויות, נהל סשנים של C2 — מהטלפון שלך, מאובטח עם הצפנה צבאית.',
      dl_title: 'הורד את RedOps Hub',
      dl_sub: 'חינם למפעילים בודדים במהלך גישה מוקדמת.',
      feat_title: 'כל מה ש-Red Team צריך — באפליקציה אחת',
      feat_sub: 'נבנה עבור מפעילים שאינם יכולים להיות קשורים למחשב נייד במהלך מעורבות.',
      nav_dl: 'הורד APK'
    },
    ro: {
      hero_h1: '<em>Centrul de comandă mobil</em><br>pentru operatorii Red Team',
      hero_sub: 'Urmăriți vulnerabilități, gestionați sesiuni C2 — de pe telefon, securizat cu criptare militară.',
      dl_title: 'Descărcați RedOps Hub',
      dl_sub: 'Gratuit pentru operatorii individuali în perioada de acces timpuriu.',
      feat_title: 'Tot ce are nevoie un Red Team — într-o aplicație',
      feat_sub: 'Construit pentru operatorii care nu pot fi legați de un laptop în timpul unui angajament.',
      nav_dl: 'Descărcați APK'
    },
    cs: {
      hero_h1: '<em>Mobilní velitelské centrum</em><br>pro operátory Red Team',
      hero_sub: 'Sledujte zranitelnosti, spravujte relace C2 — z telefonu, zabezpečeno vojenským šifrováním.',
      dl_title: 'Stáhnout RedOps Hub',
      dl_sub: 'Zdarma pro jednotlivé operátory po dobu předčasného přístupu.',
      feat_title: 'Vše, co Red Team potřebuje — v jedné aplikaci',
      feat_sub: 'Vytvořeno pro operátory, kteří nemohou být vázáni na notebook během operace.',
      nav_dl: 'Stáhnout APK'
    },
    ms: {
      hero_h1: '<em>Pusat komando mudah alih</em><br>untuk pengendali Red Team',
      hero_sub: 'Jejaki kerentanan, urus sesi C2 — dari telefon anda, dilindungi dengan penyulitan tentera.',
      dl_title: 'Muat turun RedOps Hub',
      dl_sub: 'Percuma untuk pengendali individu semasa akses awal.',
      feat_title: 'Semua yang diperlukan Red Team — dalam satu aplikasi',
      feat_sub: 'Dibina untuk pengendali yang tidak boleh terikat dengan komputer riba semasa operasi.',
      nav_dl: 'Muat turun APK'
    },
    hi: {
      hero_h1: 'Red Team ऑपरेटरों के लिए<br><em>मोबाइल कमांड सेंटर</em>',
      hero_sub: 'कमज़ोरियों को ट्रैक करें, C2 सत्रों को प्रबंधित करें — अपने फ़ोन से, सैन्य-ग्रेड एन्क्रिप्शन के साथ सुरक्षित।',
      dl_title: 'RedOps Hub डाउनलोड करें',
      dl_sub: 'अर्ली एक्सेस के दौरान व्यक्तिगत ऑपरेटरों के लिए निःशुल्क।',
      feat_title: 'Red Team की ज़रूरत की हर चीज़ — एक ऐप में',
      feat_sub: 'उन ऑपरेटरों के लिए बनाया गया जो ऑपरेशन के दौरान लैपटॉप से बंधे नहीं रह सकते।',
      nav_dl: 'APK डाउनलोड करें'
    }
  };

  let currentPhase = getPhase();
  let targetPhase  = currentPhase;
  let themeProgress = 1; // 0→1 transition progress

  function applyTheme(phase) {
    const th = THEMES[phase] || THEMES.night;
    const root = document.documentElement.style;
    root.setProperty('--bg',        th.bg);
    root.setProperty('--bg2',       th.bg2);
    root.setProperty('--surface',   th.surface);
    root.setProperty('--surface2',  th.surface2);
    root.setProperty('--border',    th.border);
    root.setProperty('--text',      th.text);
    root.setProperty('--muted',     th.muted);
    root.setProperty('--dim',       th.dim);
    root.setProperty('--red',       th.red);
    
    // Update nav bg
    const nav = document.querySelector('nav');
    if (nav) nav.style.background = th.navBg;
    // Time badge
    const badge = document.getElementById('timeBadge');
    if (badge) {
      const now = new Date();
      const timeStr = now.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'});
      badge.textContent = `${th.badgeIcon} ${th.badgeLabel} · ${timeStr}`;
    }
  }

  // ── Particle systems ──────────────────────────────────────

  // Stars (night/dawn/dusk)
  let stars = [];
  function initStars() {
    stars = [];
    for (let i = 0; i < 260; i++) {
      stars.push({
        x: rand(0,W), y: rand(0,H),
        r: rand(0.25,1.8),
        baseAlpha: rand(0.15,0.95),
        alpha: rand(0,1),
        speed:  rand(0.0004,0.0014),
        phase:  rand(0, Math.PI*2),
        waveAmp:  rand(0.3,2.2),
        waveFreq: rand(0.0004,0.0012),
        wavePhase: rand(0, Math.PI*2),
        baseY: 0,
        hue: Math.random() < 0.12 ? 'rgba(224,130,130,' : Math.random() < 0.2 ? 'rgba(180,180,255,' : 'rgba(215,215,255,'
      });
      stars[stars.length-1].baseY = stars[stars.length-1].y;
    }
  }
  initStars();

  // Sun rays (morning)
  const rays = [];
  for (let i = 0; i < 14; i++) {
    rays.push({ angle: (i / 14) * Math.PI * 2, speed: rand(0.0002, 0.0006), len: rand(0.6, 1.1), alpha: rand(0.04, 0.13) });
  }

  // Cloud puffs (morning/afternoon)
  let clouds = [];
  function initClouds() {
    clouds = [];
    for (let i = 0; i < 6; i++) {
      clouds.push({
        x: rand(-200, W + 200), y: rand(H * 0.05, H * 0.35),
        w: rand(160, 360), h: rand(50, 110),
        speed: rand(0.1, 0.5),
        alpha: rand(0.25, 0.6)
      });
    }
  }
  initClouds();

  // Meteors / shooting stars (sunset + morning)
  let meteors = [];
  function spawnMeteor() {
    meteors.push({
      x: rand(W * 0.1, W * 0.9), y: rand(-40, H * 0.3),
      vx: rand(4, 10) * (Math.random() < 0.5 ? 1 : -1),
      vy: rand(3, 8),
      len: rand(80, 200),
      alpha: 1,
      life: 1,
      decay: rand(0.012, 0.025),
      color: currentPhase === 'morning' ? 'rgba(255,220,100,' : 'rgba(255,140,60,'
    });
  }

  // Heat shimmer particles (afternoon)
  let shimmer = [];
  function initShimmer() {
    shimmer = [];
    for (let i = 0; i < 30; i++) {
      shimmer.push({ x: rand(0,W), y: rand(H*0.6,H), size: rand(1,4), alpha: rand(0.02,0.08), speed: rand(-0.3,-0.05) });
    }
  }
  initShimmer();

  // ── Draw functions per phase ──────────────────────────────

  function drawNight(alpha) {
    // Deep gradient
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,  `rgba(5,5,20,${alpha})`);
    bg.addColorStop(0.5,`rgba(9,9,20,${alpha})`);
    bg.addColorStop(1,  `rgba(12,5,25,${alpha})`);
    ctx.fillStyle = bg; ctx.fillRect(0,0,W,H);

    for (const s of stars) {
      s.alpha = s.baseAlpha * (0.4 + 0.6*(0.5 + 0.5*Math.sin(t*s.speed*60+s.phase)));
      s.y = s.baseY + s.waveAmp*Math.sin(t*s.waveFreq*60+s.wavePhase);
      s.x += 0.008*Math.sin(t*0.0002+s.wavePhase);
      if(s.x>W+2)s.x=-2; if(s.x<-2)s.x=W+2;
      const a = s.alpha * alpha;
      ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2);
      ctx.fillStyle = s.hue+a+')'; ctx.fill();
      if(s.r>1.2 && s.alpha>0.5) {
        const g=ctx.createRadialGradient(s.x,s.y,0,s.x,s.y,s.r*3.5);
        g.addColorStop(0,s.hue+(a*0.3)+')'); g.addColorStop(1,s.hue+'0)');
        ctx.fillStyle=g; ctx.beginPath(); ctx.arc(s.x,s.y,s.r*3.5,0,Math.PI*2); ctx.fill();
      }
    }
    // Spawn shooting stars during the night!
    if(Math.random() < 0.012) spawnMeteor();
  }

  function drawDawn(alpha) {
    // Sky gradient: dark purple → pink horizon
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,  `rgba(8,4,20,${alpha})`);
    bg.addColorStop(0.5,`rgba(30,8,40,${alpha})`);
    bg.addColorStop(0.75,`rgba(80,20,50,${alpha})`);
    bg.addColorStop(1,  `rgba(180,60,60,${alpha})`);
    ctx.fillStyle = bg; ctx.fillRect(0,0,W,H);

    // Fading stars
    for (const s of stars) {
      s.alpha = s.baseAlpha * 0.6 * (0.4+0.6*(0.5+0.5*Math.sin(t*s.speed*60+s.phase)));
      const a = s.alpha * alpha;
      ctx.beginPath(); ctx.arc(s.x,s.y,s.r*0.9,0,Math.PI*2);
      ctx.fillStyle = s.hue+a+')'; ctx.fill();
    }
    // Rising sun glow on horizon
    const sunGlow = ctx.createRadialGradient(W/2,H+80,10,W/2,H+80,H*0.6);
    sunGlow.addColorStop(0, `rgba(255,120,40,${0.35*alpha})`);
    sunGlow.addColorStop(0.4,`rgba(220,60,80,${0.12*alpha})`);
    sunGlow.addColorStop(1,  `rgba(80,0,80,0)`);
    ctx.fillStyle = sunGlow; ctx.fillRect(0,0,W,H);
    // Spawn shooting stars during dawn!
    if(Math.random() < 0.008) spawnMeteor();
  }

  function drawMorning(alpha) {
    // Bright blue sky
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,   `rgba(100,170,255,${alpha})`);
    bg.addColorStop(0.45,`rgba(160,210,255,${alpha})`);
    bg.addColorStop(0.8, `rgba(220,240,255,${alpha})`);
    bg.addColorStop(1,   `rgba(255,250,235,${alpha})`);
    ctx.fillStyle=bg; ctx.fillRect(0,0,W,H);

    // Sun disk
    const sunX=W*0.72, sunY=H*0.15;
    const sunR=ctx.createRadialGradient(sunX,sunY,0,sunX,sunY,H*0.35);
    sunR.addColorStop(0,   `rgba(255,255,200,${0.9*alpha})`);
    sunR.addColorStop(0.04,`rgba(255,240,120,${0.7*alpha})`);
    sunR.addColorStop(0.15,`rgba(255,200,60,${0.2*alpha})`);
    sunR.addColorStop(0.4, `rgba(255,180,40,${0.06*alpha})`);
    sunR.addColorStop(1,   `rgba(255,160,0,0)`);
    ctx.fillStyle=sunR; ctx.fillRect(0,0,W,H);

    // Rotating rays
    ctx.save(); ctx.translate(sunX,sunY);
    for(const r of rays) {
      r.angle += r.speed;
      const x2 = Math.cos(r.angle) * W * r.len;
      const y2 = Math.sin(r.angle) * H * r.len;
      const rg = ctx.createLinearGradient(0,0,x2,y2);
      rg.addColorStop(0,   `rgba(255,230,100,${r.alpha*alpha})`);
      rg.addColorStop(0.3, `rgba(255,220,80,${r.alpha*0.4*alpha})`);
      rg.addColorStop(1,   `rgba(255,210,60,0)`);
      ctx.beginPath();
      ctx.moveTo(0,0);
      ctx.lineTo(x2,y2);
      ctx.strokeStyle = rg;
      ctx.lineWidth = rand(8,20);
      ctx.stroke();
    }
    ctx.restore();

    // Drifting clouds
    for(const c of clouds) {
      c.x += c.speed;
      if(c.x > W+300) c.x = -300;
      ctx.beginPath();
      ctx.ellipse(c.x, c.y, c.w, c.h, 0, 0, Math.PI*2);
      ctx.fillStyle = `rgba(255,255,255,${c.alpha*alpha})`;
      ctx.fill();
      ctx.beginPath();
      ctx.ellipse(c.x+c.w*0.3, c.y-c.h*0.3, c.w*0.6, c.h*0.7, 0, 0, Math.PI*2);
      ctx.fill();
      ctx.beginPath();
      ctx.ellipse(c.x-c.w*0.3, c.y-c.h*0.2, c.w*0.5, c.h*0.6, 0, 0, Math.PI*2);
      ctx.fill();
    }

    // Occasional morning comet
    if(Math.random() < 0.003) spawnMeteor();
  }

  function drawAfternoon(alpha) {
    // Slightly hazier blue sky
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,   `rgba(8,150,240,${alpha})`); // Fixed color format
    bg.addColorStop(0.5, `rgba(140,200,255,${alpha})`);
    bg.addColorStop(1,   `rgba(220,240,255,${alpha})`);
    ctx.fillStyle=bg; ctx.fillRect(0,0,W,H);

    // High sun
    const sunX=W*0.5, sunY=H*0.08;
    const sunR=ctx.createRadialGradient(sunX,sunY,0,sunX,sunY,H*0.28);
    sunR.addColorStop(0,   `rgba(255,255,220,${0.85*alpha})`);
    sunR.addColorStop(0.05,`rgba(255,240,150,${0.5*alpha})`);
    sunR.addColorStop(0.2, `rgba(255,220,80,${0.12*alpha})`);
    sunR.addColorStop(1,   'rgba(255,200,0,0)');
    ctx.fillStyle=sunR; ctx.fillRect(0,0,W,H);

    // Clouds
    for(const c of clouds) {
      c.x += c.speed*0.6;
      if(c.x > W+300) c.x=-300;
      ctx.beginPath();
      ctx.ellipse(c.x, c.y, c.w, c.h, 0, 0, Math.PI*2);
      ctx.fillStyle=`rgba(255,255,255,${c.alpha*0.5*alpha})`; ctx.fill();
    }

    // Heat shimmer
    for(const s of shimmer) {
      s.y += s.speed;
      s.alpha = rand(0.01,0.06)*alpha;
      if(s.y < H*0.5) { s.y=H; s.x=rand(0,W); }
      ctx.beginPath(); ctx.arc(s.x,s.y,s.size,0,Math.PI*2);
      ctx.fillStyle=`rgba(255,240,200,${s.alpha})`; ctx.fill();
    }
  }

  function drawSunset(alpha) {
    // Fiery gradient
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,   `rgba(15,5,30,${alpha})`);
    bg.addColorStop(0.25,`rgba(80,20,20,${alpha})`);
    bg.addColorStop(0.55,`rgba(200,70,20,${alpha})`);
    bg.addColorStop(0.75,`rgba(255,140,30,${alpha})`);
    bg.addColorStop(1,   `rgba(255,80,20,${alpha})`);
    ctx.fillStyle=bg; ctx.fillRect(0,0,W,H);

    // Setting sun glow
    const sunX=W*0.3, sunY=H*0.65;
    const sunR=ctx.createRadialGradient(sunX,sunY,0,sunX,sunY,H*0.5);
    sunR.addColorStop(0,   `rgba(255,200,60,${0.6*alpha})`);
    sunR.addColorStop(0.12,`rgba(255,120,20,${0.3*alpha})`);
    sunR.addColorStop(0.4, `rgba(200,50,0,${0.1*alpha})`);
    sunR.addColorStop(1,   'rgba(100,0,0,0)');
    ctx.fillStyle=sunR; ctx.fillRect(0,0,W,H);

    // Silhouette horizon line
    ctx.fillStyle=`rgba(5,2,15,${0.4*alpha})`;
    ctx.fillRect(0,H*0.82,W,H);

    // A few early stars appearing
    for(let i=0;i<80;i++) {
      const s=stars[i];
      const a=s.baseAlpha*0.5*(0.3+0.3*Math.sin(t*s.speed*60+s.phase))*alpha;
      ctx.beginPath(); ctx.arc(s.x,s.y*0.6,s.r*0.8,0,Math.PI*2);
      ctx.fillStyle=`rgba(255,230,200,${a})`; ctx.fill();
    }

    // Meteors more frequent at sunset
    if(Math.random() < 0.015) spawnMeteor();
  }

  function drawDusk(alpha) {
    // Purple-blue gradient
    const bg = ctx.createLinearGradient(0,0,0,H);
    bg.addColorStop(0,   `rgba(8,4,18,${alpha})`);
    bg.addColorStop(0.4, `rgba(25,10,40,${alpha})`);
    bg.addColorStop(0.7, `rgba(60,15,40,${alpha})`);
    bg.addColorStop(1,   `rgba(100,30,30,${alpha})`);
    ctx.fillStyle=bg; ctx.fillRect(0,0,W,H);

    // Last glow on horizon
    const hg=ctx.createLinearGradient(0,H*0.7,0,H);
    hg.addColorStop(0,'rgba(180,60,20,0)');
    hg.addColorStop(0.5,`rgba(150,40,10,${0.15*alpha})`);
    hg.addColorStop(1,`rgba(80,20,5,${0.25*alpha})`);
    ctx.fillStyle=hg; ctx.fillRect(0,H*0.7,W,H);

    // Stars appearing
    for(let i=0;i<180;i++) {
      const s=stars[i];
      const prog = clamp((t*0.01-i*0.002),0,1);
      const a = s.baseAlpha*prog*(0.4+0.4*Math.sin(t*s.speed*60+s.phase))*alpha;
      ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,Math.PI*2);
      ctx.fillStyle=s.hue+a+')'; ctx.fill();
    }
    // Spawn shooting stars during dusk!
    if(Math.random() < 0.008) spawnMeteor();
  }

  // Draw meteors over any background
  function drawMeteors(alpha) {
    meteors = meteors.filter(m => m.life > 0);
    for(const m of meteors) {
      m.x += m.vx; m.y += m.vy; m.life -= m.decay;
      const a = m.life * alpha;
      const tail = ctx.createLinearGradient(m.x,m.y,m.x-m.vx*(m.len/m.vx||1),m.y-m.vy*(m.len/m.vx||1));
      tail.addColorStop(0, m.color+a+')');
      tail.addColorStop(1, m.color+'0)');
      const angle = Math.atan2(m.vy,m.vx);
      ctx.save();
      ctx.translate(m.x,m.y); ctx.rotate(angle);
      ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(-m.len,0);
      ctx.strokeStyle=tail; ctx.lineWidth=2; ctx.stroke();
      ctx.restore();
      // Head sparkle
      ctx.beginPath(); ctx.arc(m.x,m.y,2,0,Math.PI*2);
      ctx.fillStyle=m.color+Math.min(a+0.3,1)+')'; ctx.fill();
    }
  }

  // ── Main render loop ──────────────────────────────────────
  let lastPhaseCheck = 0;

  function tick() {
    requestAnimationFrame(tick);
    t++;
    ctx.clearRect(0,0,W,H);

    // Check phase every 60s
    if(t % 3600 === 0) {
      const newPhase = getPhase();
      if(newPhase !== currentPhase) { currentPhase = newPhase; applyTheme(newPhase); }
    }

    const phase = currentPhase;
    switch(phase) {
      case 'night':      drawNight(1);     break;
      case 'dawn':       drawDawn(1);      break;
      case 'morning':    drawMorning(1);   break;
      case 'afternoon':  drawAfternoon(1); break;
      case 'sunset':     drawSunset(1);    break;
      case 'dusk':       drawDusk(1);      break;
    }
    drawMeteors(1);

    // Update time badge every 60 frames
    if(t % 60 === 0) {
      const now = new Date();
      const th  = THEMES[phase] || THEMES.night;
      const timeStr = now.toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'});
      const badge = document.getElementById('timeBadge');
      if(badge) badge.textContent = `${th.badgeIcon} ${th.badgeLabel} · ${timeStr}`;
    }
  }

  // Init theme immediately
  applyTheme(currentPhase);
  tick();

})();