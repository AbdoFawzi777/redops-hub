// RedOps Tactical Console - Unified Web & Flutter Client
const firebaseConfig = {
  apiKey: "AIzaSyCDfuULBbTywKiN89zLvMN_0sT55dZD0ww",
  authDomain: "redops-hub.firebaseapp.com",
  projectId: "redops-hub",
  storageBucket: "redops-hub.firebasestorage.app",
  messagingSenderId: "1074549343563",
  appId: "1:1074549343563:android:66a357b9834ccaccdb14ce"
};

// --- Cryptographic Module (PBKDF2 + AES-GCM) ---
function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes) {
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function deriveKeysPBKDF2(password, saltHex) {
  const saltBytes = hexToBytes(saltHex);
  const baseKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    { name: "PBKDF2" },
    false,
    ["deriveBits"]
  );
  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: saltBytes,
      iterations: 100000,
      hash: "SHA-256"
    },
    baseKey,
    512
  );
  const derivedBytes = new Uint8Array(derivedBits);
  const authHashBytes = derivedBytes.slice(0, 32);
  const encKeyBytes = derivedBytes.slice(32, 64);
  return {
    authHashHex: bytesToHex(authHashBytes),
    encKeyHex: bytesToHex(encKeyBytes)
  };
}

async function importAesKey(rawKeyHex) {
  const rawKeyBytes = hexToBytes(rawKeyHex);
  return crypto.subtle.importKey(
    "raw",
    rawKeyBytes,
    { name: "AES-GCM" },
    false,
    ["encrypt", "decrypt"]
  );
}

async function encryptAesGcm(plaintext, rawKeyHex) {
  const key = await importAesKey(rawKeyHex);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plaintext);
  const ciphertext = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: iv },
    key,
    encoded
  );
  const cipherBytes = new Uint8Array(ciphertext);
  const combined = new Uint8Array(iv.length + cipherBytes.length);
  combined.set(iv, 0);
  combined.set(cipherBytes, iv.length);
  return bytesToHex(combined);
}

async function decryptAesGcm(ciphertextHex, rawKeyHex) {
  try {
    const key = await importAesKey(rawKeyHex);
    const combined = hexToBytes(ciphertextHex);
    const iv = combined.slice(0, 12);
    const ciphertext = combined.slice(12);
    const decrypted = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: iv },
      key,
      ciphertext
    );
    return new TextDecoder().decode(decrypted);
  } catch (err) {
    console.error("AES Decryption failed:", err);
    return "[Decryption Failure - Invalid Key]";
  }
}

function escapeHtml(string) {
  return String(string).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

// Global Variables
let currentFindings = [];
let selectedFindingId = null;
let vaultCredentials = [];

// Wait for DOM to be fully loaded and parsed before querying elements or attaching listeners
document.addEventListener('DOMContentLoaded', () => {
  console.log('DEBUG: toast-login-btn exists?', !!document.getElementById('toast-login-btn'));
  // DOM Elements
  const overlay = document.getElementById('console-overlay');
  const openTriggers = document.querySelectorAll('.open-console-trigger');
  const closeBtn = document.getElementById('close-console-btn');
  const logoutBtn = document.getElementById('logout-btn');
  const operatorInfo = document.getElementById('operator-info');
  const loginForm = document.getElementById('console-login-form');
  const authScreen = document.getElementById('console-auth-screen');
  const dashboardScreen = document.getElementById('console-dashboard-screen');
  const authErrorMsg = document.getElementById('auth-error-msg');

  // Obfuscated Admin Path Routing Configuration
  const secretAdminPath = '/hq-terminal-omega-7a91';
  let isAdminUplinkRequested = (
    window.location.pathname.includes('hq-terminal-omega') || 
    window.location.hash.includes('hq-terminal-omega') ||
    window.location.pathname.includes('hq_terminal_omega') || 
    window.location.hash.includes('hq_terminal_omega')
  );

  // Mitigate scanning: Immediately redirect any access on guessable '/admin' path to home page
  if (window.location.pathname === '/admin' || window.location.hash === '#admin') {
    window.location.href = '/';
    return;
  }

  // Global variables shared across Firebase modules
  let db;
  let auth;

  const adminScreen = document.getElementById('console-admin-screen');

  const searchInput = document.getElementById('finding-search');
  const severityFilter = document.getElementById('severity-filter');
  const findingsList = document.getElementById('findings-list');
  const detailsEmpty = document.getElementById('finding-details-empty');
  const detailsContent = document.getElementById('finding-details-content');

  const tabLogin = document.getElementById('tab-auth-login');
  const tabSignup = document.getElementById('tab-auth-signup');
  const signupForm = document.getElementById('console-signup-form');

  const vaultForm = document.getElementById('vault-add-form');
  const vaultUserIn = document.getElementById('vault-user');
  const vaultPassIn = document.getElementById('vault-pass');
  const vaultTypeIn = document.getElementById('vault-type');
  const vaultTargetIn = document.getElementById('vault-target');
  const vaultTableBody = document.querySelector('#vault-credentials-table tbody');

  const vaultLockScreen = document.getElementById('vault-lock-screen');
  const vaultUnlockForm = document.getElementById('vault-unlock-form');
  const vaultUnlockKeyIn = document.getElementById('vault-unlock-key');
  const vaultUnlockError = document.getElementById('vault-unlock-error');

  // Severities & Status Mapping
  const severities = ['Critical', 'High', 'Medium', 'Low', 'Info'];
  const severityClasses = ['badge-crit', 'badge-high', 'badge-med', 'badge-low', 'badge-low'];
  const statuses = ['Open', 'In Review', 'Remediated', 'Accepted', 'False Positive'];
  const statusClasses = ['badge-status-open', 'badge-status-review', 'badge-status-rem', 'badge-low', 'badge-low'];

  // Ensure body overflow is reset to default at startup
  document.body.style.overflow = '';

  // Ensure body overflow is reset to default at startup
  document.body.style.overflow = '';

  // ─── AUTH TOAST / GUEST MODE HELPERS ───────────────────────────────────────
  const invitationToast = document.getElementById('auth-invitation-toast');
  const warningToast    = document.getElementById('auth-warning-toast');
  const toastCloseBtn   = document.getElementById('toast-close-btn');
  const toastLoginBtn   = document.getElementById('toast-login-btn');
  const guestModeBtn    = document.getElementById('guest-mode-btn');

  function openOverlay() {
    if (overlay) {
      overlay.classList.add('active');
      document.body.style.overflow = 'hidden';
      // Explicitly toggle visual child container states on open
      const firebase = window.firebase;
      const hasSession = firebase && firebase.apps && firebase.apps.length > 0;
      const isLoggedIn = hasSession && firebase.auth().currentUser;
      if (!isLoggedIn) {
        if (authScreen) authScreen.style.display = 'flex';
        if (dashboardScreen) dashboardScreen.style.display = 'none';
        if (adminScreen) adminScreen.style.display = 'none';
      } else {
        if (isAdminUplinkRequested) {
          firebase.auth().currentUser.getIdTokenResult().then((idTokenResult) => {
            if (idTokenResult.claims.admin) {
              if (authScreen) authScreen.style.display = 'none';
              if (dashboardScreen) dashboardScreen.style.display = 'none';
              if (adminScreen) adminScreen.style.display = 'flex';
              loadAdminTelemetry(db);
            } else {
              window.location.href = '/';
            }
          }).catch(() => {
            window.location.href = '/';
          });
        } else {
          if (authScreen) authScreen.style.display = 'none';
          if (dashboardScreen) dashboardScreen.style.display = 'flex';
          if (adminScreen) adminScreen.style.display = 'none';
        }
      }
    }
  }
  function closeOverlay() {
    if (overlay) {
      overlay.classList.remove('active');
      document.body.style.overflow = '';
    }
  }
  function enterGuestMode() {
    sessionStorage.setItem('guest_mode', '1');
    closeOverlay();
  }
  function exitGuestMode() {
    sessionStorage.removeItem('guest_mode');
    if (invitationToast) invitationToast.style.display = 'none';
    if (warningToast) warningToast.style.display = 'none';
  }
  function isGuestMode() {
    return sessionStorage.getItem('guest_mode') === '1';
  }

  // ─── 1. DELAYED TOAST TRIGGER (6 seconds delay) ────────────────────────────
  setTimeout(() => {
    if (isAdminUplinkRequested) return; // do not show popup on admin route
    const firebase = window.firebase;
    const hasSession = firebase && firebase.apps && firebase.apps.length > 0;
    const isLoggedIn = hasSession && firebase.auth().currentUser;
    if (!isLoggedIn && !isGuestMode()) {
      if (invitationToast) invitationToast.style.display = 'block';
    }
  }, 6000);

  // ─── EVENT DELEGATION ──────────────────────────────────────────────────────
  document.addEventListener('click', function(e) {
    // 1. Toast Login Button
    if (e.target.closest('#toast-login-btn')) {
      e.preventDefault();
      if (invitationToast) invitationToast.style.display = 'none';
      openOverlay();
    }
    // 2. Toast Close Button
    else if (e.target.closest('#toast-close-btn')) {
      e.preventDefault();
      if (invitationToast) invitationToast.style.display = 'none';
      enterGuestMode();
      if (warningToast) {
        warningToast.style.display = 'block';
        setTimeout(() => {
          warningToast.style.display = 'none';
        }, 5000);
      }
    }
    // 3. Manual Open (Console Gateway button)
    else if (e.target.closest('.open-console-trigger')) {
      e.preventDefault();
      openOverlay();
    }
    // 4. Close button inside overlay
    else if (e.target.closest('#close-console-btn')) {
      e.preventDefault();
      closeOverlay();
      const firebase = window.firebase;
      const hasSession = firebase && firebase.apps && firebase.apps.length > 0;
      if (!hasSession || !firebase.auth().currentUser) {
        enterGuestMode();
      }
    }
    // 6. Welcome Toast Close
    else if (e.target.closest('#welcome-toast-close')) {
      e.preventDefault();
      const welcomeToast = document.getElementById('welcome-toast');
      if (welcomeToast) {
        welcomeToast.style.opacity = '0';
        setTimeout(() => { welcomeToast.style.display = 'none'; }, 300);
      }
    }
  });

  // 2. Auth Tabs Toggling (Works 100% independent of Firebase loading!)
  if (tabLogin && tabSignup && loginForm && signupForm) {
    tabLogin.addEventListener('click', () => {
      tabLogin.classList.add('active');
      tabSignup.classList.remove('active');
      loginForm.style.display = 'block';
      signupForm.style.display = 'none';
      if (authErrorMsg) authErrorMsg.style.display = 'none';
    });

    tabSignup.addEventListener('click', () => {
      tabSignup.classList.add('active');
      tabLogin.classList.remove('active');
      signupForm.style.display = 'block';
      loginForm.style.display = 'none';
      if (authErrorMsg) authErrorMsg.style.display = 'none';
    });
  }

  // --- CLIENT-SIDE SECURITY DETERRENTS (Production only) ---
  const isProduction = window.location.hostname !== 'localhost'
    && window.location.hostname !== '127.0.0.1'
    && window.location.protocol !== 'file:';

  if (isProduction) {
  document.addEventListener('contextmenu', (e) => {
    e.preventDefault();
    addConsoleLog("Security Warning: Operator context menu disabled by security policy.", "warning");
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'F12' || e.keyCode === 123) {
      e.preventDefault();
      addConsoleLog("Security Warning: F12 diagnostic tools shortcut blocked.", "warning");
      return false;
    }
    if (e.ctrlKey && (e.shiftKey && (e.key === 'I' || e.key === 'J' || e.key === 'C' || e.keyCode === 73 || e.keyCode === 74 || e.keyCode === 67) || (e.key === 'U' || e.keyCode === 85))) {
      e.preventDefault();
      addConsoleLog("Security Warning: Code audit shortcuts blocked.", "warning");
      return false;
    }
  });
  } // end isProduction

  // --- INACTIVITY AUTO-LOCK LOGIC ---
  let inactivityTimer = null;
  const INACTIVITY_TIMEOUT = 5 * 60 * 1000; // 5 minutes

  function resetInactivityTimer() {
    if (inactivityTimer) clearTimeout(inactivityTimer);
    inactivityTimer = setTimeout(() => {
      const encKey = sessionStorage.getItem("vault_enc_key");
      if (encKey) {
        sessionStorage.removeItem("vault_enc_key");
        vaultCredentials.forEach(c => { c.isEncrypted = true; });
        renderVault();
        addConsoleLog("Tactical Credential Safe auto-locked due to operator inactivity.", "warning");
      }
    }, INACTIVITY_TIMEOUT);
  }

  ['mousemove', 'keypress', 'click', 'scroll'].forEach(evt => {
    window.addEventListener(evt, resetInactivityTimer);
  });
  resetInactivityTimer();

  // Helper Console Logging
  function addConsoleLog(msg, type = 'info') {
    const sidebarLogs = document.getElementById('sidebar-logs');
    if (!sidebarLogs) return;

    const logDiv = document.createElement('div');
    logDiv.className = 'log-item';
    const time = new Date().toLocaleTimeString();
    logDiv.innerHTML = `<span style="color:var(--red); font-weight:bold;">[${time}]</span> ${escapeHtml(msg)}`;
    
    sidebarLogs.appendChild(logDiv);
    sidebarLogs.scrollTop = sidebarLogs.scrollHeight;
  }

  // Render Credential Vault UI
  function renderVault() {
    const encKeyHex = sessionStorage.getItem("vault_enc_key");
    
    if (encKeyHex) {
      if (vaultLockScreen) vaultLockScreen.style.display = 'none';
      if (vaultForm) vaultForm.style.display = 'block';
    } else {
      if (vaultLockScreen) vaultLockScreen.style.display = 'block';
      if (vaultForm) vaultForm.style.display = 'none';
      return;
    }
    
    if (!vaultTableBody) return;
    vaultTableBody.innerHTML = '';
    vaultCredentials.forEach((c, idx) => {
      const row = document.createElement('tr');
      row.style.borderBottom = '1px solid rgba(255,255,255,0.02)';
      
      let passDisplay = "";
      let decryptBtnHtml = "";
      if (c.isEncrypted) {
        passDisplay = `<span id="pass-val-${idx}" style="font-family: var(--mono); font-size: 10px; color: var(--dim);">${escapeHtml(c.pass.substring(0, 16))}... (Encrypted)</span>`;
        decryptBtnHtml = `<button class="decrypt-vault-btn" data-idx="${idx}" style="background: transparent; color: var(--green); border: 1px solid rgba(93,202,165,0.3); border-radius: 4px; padding: 2px 6px; font-size: 9.5px; cursor: pointer; font-family: var(--mono); margin-left: 8px;">🔓 DECRYPT</button>`;
      } else {
        passDisplay = `<span id="pass-val-${idx}" style="color: var(--green); font-family: var(--mono); font-size: 11px; font-weight: bold;">${escapeHtml(c.pass)}</span>`;
        decryptBtnHtml = `<button class="encrypt-row-btn" data-idx="${idx}" style="background: transparent; color: var(--muted); border: 1px solid var(--border); border-radius: 4px; padding: 2px 6px; font-size: 9.5px; cursor: pointer; font-family: var(--mono); margin-left: 8px;">🔒 ENCRYPT</button>`;
      }
      
      row.innerHTML = `
        <td style="padding: 10px 12px; font-weight: bold;">${escapeHtml(c.user)}</td>
        <td style="padding: 10px 12px; font-family: var(--mono); font-size: 11px; word-break: break-all;">
          <div style="display: flex; align-items: center; justify-content: space-between;">
            ${passDisplay}
            ${decryptBtnHtml}
          </div>
        </td>
        <td style="padding: 10px 12px;"><span class="badge ${c.type === 'Plaintext' ? 'badge-med' : 'badge-high'}">${escapeHtml(c.type)}</span></td>
        <td style="padding: 10px 12px; color: var(--muted);">${escapeHtml(c.target)}</td>
        <td style="padding: 10px 12px; text-align: right;">
          <button class="delete-vault-btn" data-idx="${idx}" style="background: transparent; color: var(--red); border: none; cursor: pointer; font-size: 13px;">✕</button>
        </td>
      `;
      vaultTableBody.appendChild(row);
    });
    
    // Bind actions
    document.querySelectorAll('.delete-vault-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const idx = parseInt(btn.getAttribute('data-idx'));
        addConsoleLog(`Removed vault credentials for user: ${vaultCredentials[idx].user}`, 'info');
        vaultCredentials.splice(idx, 1);
        renderVault();
      });
    });

    document.querySelectorAll('.decrypt-vault-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const idx = parseInt(btn.getAttribute('data-idx'));
        const cred = vaultCredentials[idx];
        const valSpan = document.getElementById(`pass-val-${idx}`);
        
        try {
          const decrypted = await decryptAesGcm(cred.pass, encKeyHex);
          valSpan.textContent = decrypted;
          valSpan.style.color = "var(--green)";
          valSpan.style.fontWeight = "bold";
          
          btn.textContent = "🔒 ENCRYPT";
          btn.className = "encrypt-row-btn";
          btn.onclick = () => {
            cred.isEncrypted = true;
            renderVault();
          };
        } catch (err) {
          console.error("Decryption failed:", err);
        }
      });
    });
  }

  // Tab Buttons Switching (Works 100% offline!)
  const tabButtons = document.querySelectorAll('.sidebar-tab-btn');
  const panels = document.querySelectorAll('.workspace-panel');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const tabId = btn.getAttribute('data-tab');
      
      // SECURITY: Tab change key flushing
      const currentActiveTab = document.querySelector('.sidebar-tab-btn.active');
      if (currentActiveTab && currentActiveTab.getAttribute('data-tab') === 'vault' && tabId !== 'vault') {
        sessionStorage.removeItem("vault_enc_key");
        vaultCredentials.forEach(c => { c.isEncrypted = true; });
        renderVault();
        addConsoleLog("Tactical Credential Safe automatically locked (keys flushed from session memory).", "info");
      }
      
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      panels.forEach(p => p.classList.remove('active'));
      const targetPanel = document.getElementById(`panel-${tabId}`);
      if (targetPanel) {
        targetPanel.classList.add('active');
        if (tabId === 'c2') {
          const termBody = document.getElementById('c2-terminal-body');
          if (termBody) termBody.scrollTop = termBody.scrollHeight;
        }
      }
      addConsoleLog(`Switched active operation to: ${tabId.toUpperCase()}`, 'info');
    });
  });

  // Initialize empty vault layout
  renderVault();

  // --- FIREBASE AND CLOUD BACKEND MODULES ---
  const firebase = window.firebase;
  if (typeof firebase !== 'undefined') {
    try {
      const app = firebase.initializeApp(firebaseConfig);
      auth = firebase.auth();
      db = firebase.firestore();

      // Quick logout route handler (clears guest mode flags and credentials)
      if (window.location.hash.includes('logout')) {
        sessionStorage.clear();
        auth.signOut().then(() => {
          window.location.hash = '';
          window.location.reload();
        }).catch(e => {
          window.location.hash = '';
          window.location.reload();
        });
        return;
      }

      // Activate App Check (Temporarily disabled due to placeholder reCAPTCHA key)
      // try {
      //   const appCheck = firebase.appCheck();
      //   appCheck.activate(
      //     new firebase.appCheck.ReCaptchaEnterpriseProvider('6Ld-dwwqAAAAAKN89zLvMN_0sT55dZD0ww_RECAPTCHA_KEY'),
      //     true
      //   );
      //   console.log("✓ Firebase App Check activated successfully");
      // } catch(e) {
      //   console.warn("App Check failed to start:", e);
      // }

      // Auth State Listener — handles auto-open, session restore, guest mode
      auth.onAuthStateChanged(async (user) => {
        if (user) {
          // ── Logged in ──────────────────────────────────────────────────────
          exitGuestMode();          // clear guest flag
          const navLogoutBtn = document.getElementById('navbar-logout-btn');
          if (navLogoutBtn) navLogoutBtn.style.display = 'inline-flex';
          
          // Welcome Toast Trigger
          const welcomeToast = document.getElementById('welcome-toast');
          const welcomeToastMsg = document.getElementById('welcome-toast-msg');
          if (welcomeToast && !sessionStorage.getItem('welcome_shown')) {
            sessionStorage.setItem('welcome_shown', '1');
            const userEmail = user.email || 'Operator';
            if (welcomeToastMsg) {
              welcomeToastMsg.innerHTML = `Welcome back, <strong>${userEmail}</strong>!<br>The team welcomes you, thanks you, and wishes you a successful engagement. Have a great day!`;
            }
            welcomeToast.style.display = 'block';
            welcomeToast.style.opacity = '0';
            setTimeout(() => { welcomeToast.style.opacity = '1'; }, 50);
            setTimeout(() => {
              welcomeToast.style.opacity = '0';
              setTimeout(() => { welcomeToast.style.display = 'none'; }, 300);
            }, 8000);
          }
          
          try {
            // Check if user is deactivated/disabled in Firestore
            const userDocRef = db.collection("users").doc(user.uid);
            const docSnap = await userDocRef.get();
            if (docSnap.exists) {
              const profile = docSnap.data();
              if (profile.disabled) {
                alert("ACCESS REVOKED: This account has been deactivated by administrative command.");
                auth.signOut();
                return;
              }
              if (operatorInfo) operatorInfo.textContent = `OPERATOR: ${profile.email} (${profile.displayName})`;
              await userDocRef.update({ lastLogin: Date.now() });
            } else {
              const newProfile = {
                uid: user.uid,
                email: user.email || "oauth-operator@redopshub.com",
                displayName: user.displayName || "OAuth Operator",
                role: "Operator",
                createdAt: Date.now(),
                lastLogin: Date.now(),
                platform: "Web"
              };
              await userDocRef.set(newProfile);
              if (operatorInfo) operatorInfo.textContent = `OPERATOR: ${newProfile.email} (${newProfile.displayName})`;
            }
          } catch (err) {
            console.error("Failed to load user profile:", err);
          }

          // Verify admin claims
          try {
            const idTokenResult = await user.getIdTokenResult(true);
            const isAdmin = !!idTokenResult.claims.admin;
            
            if (isAdminUplinkRequested) {
              if (isAdmin) {
                // Log admin access
                db.collection("security_logs").add({
                  type: "ADMIN_ACCESS_SUCCESS",
                  email: user.email,
                  uid: user.uid,
                  timestamp: Date.now(),
                  userAgent: navigator.userAgent
                }).catch(e => console.error(e));

                if (authScreen) authScreen.style.display = 'none';
                if (dashboardScreen) dashboardScreen.style.display = 'none';
                if (adminScreen) adminScreen.style.display = 'flex';
                
                loadAdminTelemetry(db);
              } else {
                // Unauthorized access attempt
                db.collection("security_logs").add({
                  type: "ADMIN_ACCESS_UNAUTHORIZED",
                  email: user.email,
                  uid: user.uid,
                  timestamp: Date.now(),
                  userAgent: navigator.userAgent
                }).catch(e => console.error(e));

                alert("ACCESS DENIED: Administrative credentials required.");
                window.location.href = '/';
                return;
              }
            } else {
              if (authScreen) authScreen.style.display = 'none';
              if (dashboardScreen) dashboardScreen.style.display = 'flex';
              if (adminScreen) adminScreen.style.display = 'none';
              if (logoutBtn) logoutBtn.style.display = 'inline-block';
            }
          } catch (err) {
            console.error("Error checking token claims:", err);
            if (authScreen) authScreen.style.display = 'none';
            if (dashboardScreen) dashboardScreen.style.display = 'flex';
            if (adminScreen) adminScreen.style.display = 'none';
          }
          
          startSyncListener();
        } else {
          // ── Not logged in ──────────────────────────────────────────────────
          const navLogoutBtn = document.getElementById('navbar-logout-btn');
          if (navLogoutBtn) navLogoutBtn.style.display = 'none';
          if (authScreen) authScreen.style.display = 'flex';
          if (dashboardScreen) dashboardScreen.style.display = 'none';
          if (adminScreen) adminScreen.style.display = 'none';
          if (logoutBtn) logoutBtn.style.display = 'none';
          if (operatorInfo) operatorInfo.textContent = '';
          if (findingsList) findingsList.innerHTML = '<div class="loading-placeholder">Establishing secure stream...</div>';
          if (detailsContent) detailsContent.style.display = 'none';
          if (detailsEmpty) detailsEmpty.style.display = 'flex';
          selectedFindingId = null;
        }
      });

      // Email/Password login
      if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
          e.preventDefault();
          if (authErrorMsg) authErrorMsg.style.display = 'none';
          const email = document.getElementById('auth-email').value.trim();
          const password = document.getElementById('auth-password').value;
          try {
            const userCredential = await auth.signInWithEmailAndPassword(email, password);
            db.collection("security_logs").add({
              type: "LOGIN_SUCCESS",
              email: email,
              uid: userCredential.user.uid,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          } catch (err) {
            if (authErrorMsg) {
              authErrorMsg.textContent = err.message || "Authentication failed.";
              authErrorMsg.style.display = 'block';
            }
            db.collection("security_logs").add({
              type: "LOGIN_FAILED",
              email: email,
              error: err.message,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          }
        });
      }

      // Signup form submit
      if (signupForm) {
        signupForm.addEventListener('submit', async (e) => {
          e.preventDefault();
          if (authErrorMsg) authErrorMsg.style.display = 'none';
          
          const name = document.getElementById('signup-name').value.trim();
          const email = document.getElementById('signup-email').value.trim();
          const password = document.getElementById('signup-password').value;
          const vaultKey = document.getElementById('signup-vault-key').value;
          
          if (password.length < 6) {
            if (authErrorMsg) {
              authErrorMsg.textContent = "Security validation error: Password must be at least 6 characters.";
              authErrorMsg.style.display = 'block';
            }
            return;
          }
          
          try {
            const userCredential = await auth.createUserWithEmailAndPassword(email, password);
            const user = userCredential.user;
            await user.updateProfile({ displayName: name });
            
            const saltBytes = crypto.getRandomValues(new Uint8Array(16));
            const saltHex = bytesToHex(saltBytes);
            const { authHashHex, encKeyHex } = await deriveKeysPBKDF2(vaultKey, saltHex);
            
            await db.collection("users").doc(user.uid).set({
              uid: user.uid,
              email: email,
              displayName: name,
              saltHex: saltHex,
              vaultKeyHash: authHashHex,
              role: "Operator",
              createdAt: Date.now(),
              lastLogin: Date.now()
            });
            
             sessionStorage.setItem("vault_enc_key", encKeyHex);
             exitGuestMode();
             logOperatorActivity("VAULT_INIT", "Initialized and unlocked new tactical credential safe.");

            // Show mobile app download suggestion after new signup
            const apkBanner = document.createElement('div');
            apkBanner.id = 'apk-download-banner';
            apkBanner.style.cssText = `
              position: fixed; bottom: 24px; right: 24px; z-index: 99999;
              background: linear-gradient(135deg, rgba(25,12,25,0.98), rgba(15,8,20,0.98));
              border: 1px solid rgba(93,202,165,0.4); border-radius: 12px;
              padding: 18px 20px; max-width: 320px;
              box-shadow: 0 8px 32px rgba(0,0,0,0.5);
              font-family: var(--sans); animation: slideInUp 0.4s ease;
            `;
            apkBanner.innerHTML = `
              <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:10px;">
                <strong style="color:var(--green);font-family:var(--mono);font-size:12px;">✓ ACCOUNT CREATED</strong>
                <button onclick="this.parentElement.parentElement.remove()" style="background:none;border:none;color:var(--dim);cursor:pointer;font-size:14px;">✕</button>
              </div>
              <p style="font-size:12.5px;color:var(--text);line-height:1.5;margin-bottom:14px;">
                📱 Get the <strong>RedOps Hub</strong> Android app for the full mobile command center experience.
              </p>
              <a href="https://github.com/AbdoFawzi777/redops-hub/releases" target="_blank"
                style="display:block;text-align:center;padding:9px;background:var(--green);color:#0a0010;
                border-radius:7px;font-family:var(--mono);font-size:11.5px;font-weight:700;
                text-decoration:none;transition:opacity 0.15s;">
                ⬇ Download APK
              </a>
            `;
            document.body.appendChild(apkBanner);
            
            db.collection("security_logs").add({
              type: "SIGNUP_SUCCESS",
              email: email,
              uid: user.uid,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
            
            signupForm.reset();
          } catch (err) {
            if (authErrorMsg) {
              authErrorMsg.textContent = err.message || "Account creation failed.";
              authErrorMsg.style.display = 'block';
            }
            db.collection("security_logs").add({
              type: "SIGNUP_FAILED",
              email: email,
              error: err.message,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          }
        });
      }

      // Google Login button
      const googleBtn = document.getElementById('google-login-btn');
      if (googleBtn) {
        googleBtn.addEventListener('click', async () => {
          if (authErrorMsg) authErrorMsg.style.display = 'none';
          const provider = new firebase.auth.GoogleAuthProvider();
          try {
            const userCredential = await auth.signInWithPopup(provider);
            db.collection("security_logs").add({
              type: "OAUTH_GOOGLE_SUCCESS",
              email: userCredential.user.email,
              uid: userCredential.user.uid,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          } catch (err) {
            if (authErrorMsg) {
              authErrorMsg.textContent = err.message || "Google authentication failed.";
              authErrorMsg.style.display = 'block';
            }
            db.collection("security_logs").add({
              type: "OAUTH_GOOGLE_FAILED",
              error: err.message,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          }
        });
      }

      // GitHub Login button
      const githubBtn = document.getElementById('github-login-btn');
      if (githubBtn) {
        githubBtn.addEventListener('click', async () => {
          if (authErrorMsg) authErrorMsg.style.display = 'none';
          const provider = new firebase.auth.GithubAuthProvider();
          try {
            const userCredential = await auth.signInWithPopup(provider);
            db.collection("security_logs").add({
              type: "OAUTH_GITHUB_SUCCESS",
              email: userCredential.user.email,
              uid: userCredential.user.uid,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          } catch (err) {
            if (authErrorMsg) {
              authErrorMsg.textContent = err.message || "GitHub authentication failed.";
              authErrorMsg.style.display = 'block';
            }
            db.collection("security_logs").add({
              type: "OAUTH_GITHUB_FAILED",
              error: err.message,
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          }
        });
      }

      // Logout
      if (logoutBtn) {
        logoutBtn.addEventListener('click', () => {
          auth.signOut();
        });
      }

      // Real-time vulnerabilities listener
      function startSyncListener() {
        db.collection("vulnerabilities").onSnapshot((snapshot) => {
          currentFindings = [];
          snapshot.forEach(doc => {
            currentFindings.push(doc.data());
          });
          currentFindings.sort((a, b) => b.createdAtMs - a.createdAtMs);
          renderDashboard();
        }, (error) => {
          console.error("Firestore sync failed:", error);
          if (findingsList) {
            findingsList.innerHTML = `<div class="loading-placeholder" style="color:var(--red);">Tactical Link Sync Error: ${error.message}</div>`;
          }
          if (error.code === 'permission-denied') {
            db.collection("security_logs").add({
              type: "SECURITY_VIOLATION_FIRESTORE",
              error: error.message,
              uid: auth.currentUser ? auth.currentUser.uid : "unauthenticated",
              timestamp: Date.now(),
              userAgent: navigator.userAgent
            }).catch(e => console.error(e));
          }
        });
      }

      // Vault Unlock Handler
      if (vaultUnlockForm) {
        vaultUnlockForm.addEventListener('submit', async (e) => {
          e.preventDefault();
          if (vaultUnlockError) vaultUnlockError.style.display = 'none';
          const vaultKey = vaultUnlockKeyIn.value;
          const user = auth.currentUser;
          if (!user) return;

          try {
            const userDocRef = db.collection("users").doc(user.uid);
            const docSnap = await userDocRef.get();
            if (docSnap.exists) {
              const profile = docSnap.data();
              if (profile.vaultKeyHash) {
                const { authHashHex, encKeyHex } = await deriveKeysPBKDF2(vaultKey, profile.saltHex);
                if (authHashHex === profile.vaultKeyHash) {
                  sessionStorage.setItem("vault_enc_key", encKeyHex);
                  vaultUnlockKeyIn.value = '';
                  renderVault();
                  addConsoleLog("Tactical Credential Safe successfully decrypted and unlocked.", "success");
                  logOperatorActivity("VAULT_UNLOCK", "Decrypted and unlocked the tactical credential safe.");
                } else {
                  if (vaultUnlockError) {
                    vaultUnlockError.textContent = "Access Denied: Invalid Decryption Key.";
                    vaultUnlockError.style.display = 'block';
                  }
                }
              } else {
                const saltBytes = crypto.getRandomValues(new Uint8Array(16));
                const saltHex = bytesToHex(saltBytes);
                const { authHashHex, encKeyHex } = await deriveKeysPBKDF2(vaultKey, saltHex);
                
                await userDocRef.update({
                  saltHex: saltHex,
                  vaultKeyHash: authHashHex
                });
                
                sessionStorage.setItem("vault_enc_key", encKeyHex);
                vaultUnlockKeyIn.value = '';
                renderVault();
                addConsoleLog("Tactical Credential Safe initialized and unlocked.", "success");
                logOperatorActivity("VAULT_INIT", "Initialized and unlocked new tactical credential safe.");
              }
            }
          } catch (err) {
            if (vaultUnlockError) {
              vaultUnlockError.textContent = "Decryption module error: " + err.message;
              vaultUnlockError.style.display = 'block';
            }
          }
        });
      }

      // Vault Add Form
      if (vaultForm) {
        vaultForm.addEventListener('submit', async (e) => {
          e.preventDefault();
          const user = vaultUserIn.value.trim();
          const pass = vaultPassIn.value.trim();
          const type = vaultTypeIn.value;
          const target = vaultTargetIn.value.trim() || 'General Node';
          
          const encKeyHex = sessionStorage.getItem("vault_enc_key");
          if (!encKeyHex) return;
          
          try {
            const encryptedPass = await encryptAesGcm(pass, encKeyHex);
            vaultCredentials.push({ user, pass: encryptedPass, type, target, isEncrypted: true });
            
            vaultUserIn.value = '';
            vaultPassIn.value = '';
            if (vaultTargetIn) vaultTargetIn.value = '';
            
            renderVault();
            addConsoleLog(`Added encrypted credentials for user: ${user} to safe vault`, 'success');
          } catch (err) {
            console.error("Encryption failed:", err);
          }
        });
      }

      // Severity Filter Event
      if (severityFilter) {
        severityFilter.addEventListener('change', renderDashboard);
      }
      
      // Search input event
      if (searchInput) {
        searchInput.addEventListener('input', renderDashboard);
      }

      // Render Dashboard List & Stats
      function renderDashboard() {
        if (!findingsList) return;
        
        const filterVal = severityFilter ? severityFilter.value : 'All';
        const searchVal = searchInput ? searchInput.value.toLowerCase().trim() : '';
        
        let filtered = currentFindings;
        if (filterVal !== 'All') {
          filtered = filtered.filter(f => severities[f.severityIndex] === filterVal);
        }
        if (searchVal) {
          filtered = filtered.filter(f => 
            f.title.toLowerCase().includes(searchVal) || 
            f.projectName.toLowerCase().includes(searchVal) ||
            (f.cveId && f.cveId.toLowerCase().includes(searchVal))
          );
        }
        
        // Update statistics
        let total = currentFindings.length;
        let critical = currentFindings.filter(f => f.severityIndex === 0).length;
        let open = currentFindings.filter(f => f.statusIndex === 0 || f.statusIndex === 1).length;
        let remediated = currentFindings.filter(f => f.statusIndex === 2).length;
        
        const statTotal = document.getElementById('stat-total-findings');
        const statCrit = document.getElementById('stat-critical-findings');
        const statOpen = document.getElementById('stat-open-findings');
        const statRem = document.getElementById('stat-remediated-findings');
        
        if (statTotal) statTotal.textContent = total;
        if (statCrit) statCrit.textContent = critical;
        if (statOpen) statOpen.textContent = open;
        if (statRem) statRem.textContent = remediated;
        
        if (filtered.length === 0) {
          findingsList.innerHTML = '<div class="loading-placeholder">No active findings matched filters</div>';
          return;
        }
        
        findingsList.innerHTML = '';
        filtered.forEach(f => {
          const item = document.createElement('div');
          item.className = `finding-item ${selectedFindingId === f.id ? 'active' : ''}`;
          
          const sevLabel = severities[f.severityIndex] || 'Info';
          const sevClass = severityClasses[f.severityIndex] || 'badge-low';
          const statLabel = statuses[f.statusIndex] || 'Open';
          const statClass = statusClasses[f.statusIndex] || 'badge-low';
          
          item.innerHTML = `
            <div class="finding-item-header">
              <span class="finding-item-cve">${escapeHtml(f.cveId || 'TACTICAL ENTRY')}</span>
              <span class="badge ${sevClass}">${escapeHtml(sevLabel)}</span>
            </div>
            <div class="finding-item-title">${escapeHtml(f.title)}</div>
            <div class="finding-item-project">📂 ${escapeHtml(f.projectName)}</div>
            <div class="finding-item-meta">
              <span class="badge badge-status ${statClass}">${escapeHtml(statLabel)}</span>
              <span style="font-size:11px;color:var(--dim);font-family:var(--mono);">Updated ${new Date(f.updatedAtMs).toLocaleDateString()}</span>
            </div>
          `;
          
          item.addEventListener('click', () => {
            selectedFindingId = f.id;
            document.querySelectorAll('.finding-item').forEach(el => el.classList.remove('active'));
            item.classList.add('active');
            renderFindingDetails(f);
          });
          
          findingsList.appendChild(item);
        });
        
        if (selectedFindingId) {
          const updatedSelected = currentFindings.find(f => f.id === selectedFindingId);
          if (updatedSelected) renderFindingDetails(updatedSelected);
        }
      }

      // Render Finding details pane
      function renderFindingDetails(f) {
        if (!detailsContent || !detailsEmpty) return;
        
        detailsEmpty.style.display = 'none';
        detailsContent.style.display = 'flex';
        
        const sevLabel = severities[f.severityIndex] || 'Info';
        const sevClass = severityClasses[f.severityIndex] || 'badge-low';
        
        let statusOptionsHtml = "";
        statuses.forEach((statusText, index) => {
          statusOptionsHtml += `<option value="${index}" ${f.statusIndex === index ? 'selected' : ''}>${escapeHtml(statusText)}</option>`;
        });
        
        let pocHtml = "";
        if (f.pocUrl) {
          pocHtml = `
            <div class="details-section">
              <h5>PROOF OF CONCEPT (POC LINK)</h5>
              <a href="${escapeHtml(f.pocUrl)}" target="_blank" class="poc-link-anchor" style="color:var(--green); font-family:var(--mono); font-size:12px; text-decoration:none;">🔗 ${escapeHtml(f.pocUrl)}</a>
            </div>
          `;
        }
        
        let remediationHtml = "";
        if (f.remediationPlan) {
          remediationHtml = `
            <div class="details-section">
              <h5>TACTICAL REMEDIATION PLAN</h5>
              <p>${escapeHtml(f.remediationPlan)}</p>
            </div>
          `;
        }
        
        let commentsHtml = "";
        const comments = f.commentsJson || [];
        comments.forEach(c => {
          commentsHtml += `
            <div class="comment-item">
              <div class="comment-header">
                <span class="comment-author">${escapeHtml(c.author)} <span style="color:var(--red); font-size:10px; font-family:var(--mono);">[${escapeHtml(c.role || 'Operator')}]</span></span>
                <span class="comment-date">${new Date(c.createdAt).toLocaleString()}</span>
              </div>
              <div class="comment-text">${escapeHtml(c.text)}</div>
            </div>
          `;
        });
        
        detailsContent.innerHTML = `
          <div class="details-header">
            <div class="details-cve">${escapeHtml(f.cveId || 'CVE-PENDING')}</div>
            <div class="details-title">${escapeHtml(f.title)}</div>
            <div class="details-meta-grid">
              <div class="details-meta-item">
                <span class="label">Project / Target</span>
                <span class="value">📂 ${escapeHtml(f.projectName)}</span>
              </div>
              <div class="details-meta-item">
                <span class="label">Severity</span>
                <span class="value"><span class="badge ${sevClass}">${escapeHtml(sevLabel)}</span></span>
              </div>
              <div class="details-meta-item">
                <span class="label">Tactical Status</span>
                <span class="value">
                  <select id="detail-status-selector" style="background:var(--bg2); color:var(--text); border:0.5px solid var(--border); padding:3px 8px; border-radius:4px; font-size:12px;">
                    ${statusOptionsHtml}
                  </select>
                </span>
              </div>
            </div>
          </div>
          <div class="details-body">
            <div class="details-section">
              <h5>VULNERABILITY DESCRIPTION</h5>
              <p>${escapeHtml(f.description)}</p>
            </div>
            ${f.reproductionSteps ? `
              <div class="details-section">
                <h5>REPRODUCTION STEPS</h5>
                <p>${escapeHtml(f.reproductionSteps)}</p>
              </div>
            ` : ''}
            ${pocHtml}
            ${remediationHtml}
            
            <div class="details-section">
              <h5>TACTICAL TIMELINE LOGS & COMMENTS</h5>
              <div class="comments-container" id="details-comments-list">
                ${comments.length === 0 ? '<div style="font-size:12px;color:var(--dim);font-style:italic;">No logs recorded.</div>' : commentsHtml}
              </div>
              <form class="add-comment-form" id="detail-add-comment-form">
                <input type="text" id="comment-input" required placeholder="Add log notes or comment..." autocomplete="off">
                <button type="submit" class="comment-submit-btn">SEND</button>
              </form>
            </div>
          </div>
        `;
        
        const statusSelect = document.getElementById('detail-status-selector');
        if (statusSelect) {
          statusSelect.addEventListener('change', async () => {
            const newStatus = parseInt(statusSelect.value);
            try {
              await db.collection("vulnerabilities").doc(f.id).update({
                statusIndex: newStatus,
                updatedAtMs: Date.now()
              });
            } catch (err) {
              alert("Failed to update status in Firestore: " + err.message);
            }
          });
        }
        
        const commentForm = document.getElementById('detail-add-comment-form');
        if (commentForm) {
          commentForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const commentInput = document.getElementById('comment-input');
            const text = commentInput.value.trim();
            if (!text) return;
            
            const newComment = {
              id: Math.random().toString(36).substring(2, 11),
              author: auth.currentUser.email.split('@')[0],
              text: text,
              createdAt: new Date().toISOString(),
              role: "Operator"
            };
            
            try {
              const currentComments = f.commentsJson || [];
              await db.collection("vulnerabilities").doc(f.id).update({
                commentsJson: firebase.firestore.FieldValue.arrayUnion(newComment),
                updatedAtMs: Date.now()
              });
              commentInput.value = '';
            } catch (err) {
              alert("Failed to record comment: " + err.message);
            }
          });
        }
      }

      // --- RECON TOOL LOGIC (Mock) ---
      const scanBtn = document.getElementById('recon-scan-btn');
      const scanIpInput = document.getElementById('recon-ip');
      const scanPortsInput = document.getElementById('recon-ports');
      const scanProgressContainer = document.getElementById('recon-progress-container');
      const scanProgressText = document.getElementById('recon-progress-text');
      const scanResultsTable = document.querySelector('#recon-results-table tbody');

      let scanActive = false;

      if (scanBtn) {
        scanBtn.addEventListener('click', () => {
          if (scanActive) return;
          
          const target = scanIpInput ? scanIpInput.value.trim() : '127.0.0.1';
          const portsStr = scanPortsInput ? scanPortsInput.value.trim() : '80, 443';
          
          if (!target) {
            alert('Please enter a target IP or Domain');
            return;
          }
          
          scanActive = true;
          scanBtn.disabled = true;
          scanBtn.textContent = 'SCANNING...';
          if (scanProgressContainer) scanProgressContainer.style.display = 'block';
          if (scanResultsTable) scanResultsTable.innerHTML = '';
          
          addConsoleLog(`Reconnaissance routine initialized for target: ${target}`, 'info');
          
          let step = 0;
          const scanSteps = [
            { text: 'Resolving domain DNS records...', port: null },
            { text: 'Starting SYN stealth scan on targeted ports...', port: null },
            { text: 'TCP Port 80 found open. Banner grabbing...', port: 80, service: 'http', banner: 'nginx/1.24.0 (Ubuntu)', vuln: 'None' },
            { text: 'TCP Port 443 found open. Negotiating SSL/TLS...', port: 443, service: 'https', banner: 'nginx/1.24.0', vuln: 'Heartbleed (CVE-2014-0160) - Vulnerable' },
            { text: 'TCP Port 22 found open. Version detection...', port: 22, service: 'ssh', banner: 'OpenSSH_8.9p1 Ubuntu-3ubuntu0.1', vuln: 'None' },
            { text: 'Analyzing operating system fingerprints...', port: null },
            { text: 'Compiling recon telemetry report...', port: null }
          ];
          
          const interval = setInterval(() => {
            if (step >= scanSteps.length) {
              clearInterval(interval);
              if (scanProgressContainer) scanProgressContainer.style.display = 'none';
              scanBtn.disabled = false;
              scanBtn.textContent = 'INITIALIZE RECON';
              scanActive = false;
              addConsoleLog(`Port scan completed for target ${target}`, 'success');
              return;
            }
            
            const current = scanSteps[step];
            if (scanProgressText) scanProgressText.textContent = current.text;
            
            if (current.port !== null && scanResultsTable) {
              const row = document.createElement('tr');
              row.style.borderBottom = '1px solid rgba(255,255,255,0.02)';
              row.innerHTML = `
                <td class="port-num" style="padding: 10px 12px; font-weight: bold;">${current.port}/tcp</td>
                <td style="padding: 10px 12px;">${escapeHtml(current.service)}</td>
                <td style="padding: 10px 12px; color: var(--muted);">${escapeHtml(current.banner)}</td>
                <td style="padding: 10px 12px;"><span class="badge badge-med">OPEN</span></td>
                <td style="padding: 10px 12px; font-weight: bold; color: ${current.vuln !== 'None' ? 'var(--red)' : 'var(--dim)'};">${escapeHtml(current.vuln)}</td>
              `;
              scanResultsTable.appendChild(row);
              addConsoleLog(`Discovered open port ${current.port}/tcp (${current.service})`, 'success');
            }
            step++;
          }, 1200);
        });
      }

      // --- CVE DATABASE LOOKUP (Mock) ---
      const cveSearchInput = document.getElementById('cve-search-input');
      const cveResultsContainer = document.getElementById('cve-results-container');

      let searchLogTimeout;
      if (cveSearchInput) {
        cveSearchInput.addEventListener('input', () => {
          const query = cveSearchInput.value.toLowerCase().trim();
          if (!cveResultsContainer) return;
          
          clearTimeout(searchLogTimeout);
          if (query) {
            searchLogTimeout = setTimeout(() => {
              logOperatorActivity("CVE_SEARCH", `Searched CVE database for: "${query}"`);
            }, 1200);
          }
          
          if (!query) {
            cveResultsContainer.innerHTML = '<div style="font-family:var(--mono); color:var(--dim); font-size:12px; text-align:center; padding:20px;">No vulnerabilities matched search parameters</div>';
            return;
          }
          
          const mockCves = [
            { id: 'CVE-2024-3094', title: 'XZ Utils Backdoor', desc: 'Malicious code injection in XZ Utils versions 5.6.0 and 5.6.1 allows remote execution of arbitrary commands.', score: '10.0 Critical', type: 'Remote Code Execution' },
            { id: 'CVE-2023-38606', title: 'Apple iOS Kernel Vulnerability', desc: 'A state transition issue in Apple iOS kernel allows malicious apps to modify system state and execute privilege escalation.', score: '7.8 High', type: 'Privilege Escalation' },
            { id: 'CVE-2021-44228', title: 'Log4Shell (Apache Log4j)', desc: 'JNDI features used in configuration, log messages, and parameters do not protect against attacker controlled LDAP endpoints.', score: '10.0 Critical', type: 'Remote Code Execution' },
            { id: 'CVE-2020-0601', title: 'CryptoAPI Spoofing Vulnerability', desc: 'Windows CryptoAPI fails to properly validate Elliptic Curve Cryptography certificates, allowing attackers to spoof signatures.', score: '8.1 High', type: 'Spoofing / Bypass' }
          ];
          
          const matches = mockCves.filter(c => c.id.toLowerCase().includes(query) || c.title.toLowerCase().includes(query) || c.desc.toLowerCase().includes(query));
          if (matches.length === 0) {
            cveResultsContainer.innerHTML = '<div style="font-family:var(--mono); color:var(--dim); font-size:12px; text-align:center; padding:20px;">No vulnerabilities matched search parameters</div>';
            return;
          }
          
          cveResultsContainer.innerHTML = '';
          matches.forEach(c => {
            const item = document.createElement('div');
            item.className = 'cve-search-item';
            item.innerHTML = `
              <div style="display:flex; justify-content:space-between; margin-bottom:6px;">
                <span style="font-family:var(--mono); font-weight:bold; color:var(--red);">${escapeHtml(c.id)}</span>
                <span class="badge badge-high">${escapeHtml(c.score)}</span>
              </div>
              <div style="font-weight:bold; color:var(--text); margin-bottom:4px;">${escapeHtml(c.title)}</div>
              <div style="font-size:11.5px; color:var(--muted); line-height:1.4; margin-bottom:6px;">${escapeHtml(c.desc)}</div>
              <div style="font-size:11px; font-family:var(--mono); color:var(--dim);">Category: ${escapeHtml(c.type)}</div>
            `;
            cveResultsContainer.appendChild(item);
          });
        });
      }

      // --- C2 TELEMETRY (Mock) ---
      const c2BeaconItems = document.querySelectorAll('.c2-beacon-item');
      const c2ActiveBeaconSpan = document.getElementById('c2-active-beacon');
      const c2TerminalBody = document.getElementById('c2-terminal-body');
      const c2TerminalForm = document.getElementById('c2-terminal-form');
      const c2CmdInput = document.getElementById('c2-cmd-input');

      let activeBeaconId = 'BEACON-402-A';

      c2BeaconItems.forEach(item => {
        item.addEventListener('click', () => {
          c2BeaconItems.forEach(i => i.classList.remove('active'));
          item.classList.add('active');
          activeBeaconId = item.getAttribute('data-id');
          if (c2ActiveBeaconSpan) c2ActiveBeaconSpan.textContent = activeBeaconId;
          addConsoleLog(`C2 shell telemetry channel switched to: ${activeBeaconId}`, 'info');
          if (c2TerminalBody) {
            c2TerminalBody.innerHTML = `<div style="font-family:var(--mono); color:var(--dim); font-size:11.5px;">*** Secure shell channel session opened for agent ${activeBeaconId} ***</div>`;
          }
        });
      });

      if (c2TerminalForm) {
        c2TerminalForm.addEventListener('submit', (e) => {
          e.preventDefault();
          const cmd = c2CmdInput ? c2CmdInput.value.trim() : '';
          if (!cmd || !c2TerminalBody) return;
          
          const line = document.createElement('div');
          line.style.fontFamily = 'var(--mono)';
          line.style.fontSize = '12px';
          line.innerHTML = `<span style="color:var(--green); font-weight:bold;">operator@redops-c2:~$</span> ${escapeHtml(cmd)}`;
          c2TerminalBody.appendChild(line);
          if (c2CmdInput) c2CmdInput.value = '';
          
          // Mock execution
          setTimeout(() => {
            const response = document.createElement('div');
            response.style.fontFamily = 'var(--mono)';
            response.style.fontSize = '12px';
            response.style.color = 'var(--dim)';
            response.style.paddingLeft = '14px';
            
            let out = '';
            if (cmd === 'help') {
              out = 'RedOps C2 available controls:\n  sysinfo   - Get target system detailed metrics\n  ps        - List running execution processes\n  shell     - Run a shell execution command\n  terminate - Kill remote agent connection';
            } else if (cmd === 'sysinfo') {
              out = 'OS: Linux RedOps-Target 5.15.0-88-generic x86_64\nUptime: 14 days, 3 hours, 12 minutes\nPrivileges: uid=0(root) gid=0(root) groups=0(root)';
            } else if (cmd === 'ps') {
              out = 'PID   PPID  CMD\n1     0     /sbin/init\n842   1     /usr/sbin/sshd -D\n1042  842   sshd: operator [priv]\n1102  1042  -bash';
            } else {
              out = `Command "${cmd}" not recognized. Type "help" for a list of valid controls.`;
            }
            
            response.innerHTML = out.replace(/\n/g, '<br>');
            c2TerminalBody.appendChild(response);
            c2TerminalBody.scrollTop = c2TerminalBody.scrollHeight;
          }, 300);
        });
      }

      // --- MITRE MATRIX GRID RENDERING ---
      const mitreGrid = document.getElementById('mitre-matrix-grid');
      const mitreTechniques = [
        { category: 'Reconnaissance', technique: 'Active Scanning', code: 'T1595', status: 'Completed' },
        { category: 'Initial Access', technique: 'Phishing', code: 'T1566', status: 'Completed' },
        { category: 'Execution', technique: 'Command & Script Shell', code: 'T1059', status: 'Completed' },
        { category: 'Persistence', technique: 'Registry Run Keys', code: 'T1547', status: 'Completed' },
        { category: 'Privilege Escalation', technique: 'Process Injection', code: 'T1055', status: 'In Progress' },
        { category: 'Credential Access', technique: 'Credential Dumping', code: 'T1003', status: 'In Progress' },
        { category: 'Command & Control', technique: 'Application Layer Protocol', code: 'T1071', status: 'Completed' }
      ];

      if (mitreGrid) {
        mitreGrid.innerHTML = '';
        const categories = [...new Set(mitreTechniques.map(t => t.category))];
        categories.forEach(cat => {
          const col = document.createElement('div');
          col.className = 'mitre-column';
          col.innerHTML = `<div class="mitre-column-title">${escapeHtml(cat)}</div>`;
          
          const techs = mitreTechniques.filter(t => t.category === cat);
          techs.forEach(t => {
            const mItem = document.createElement('div');
            mItem.className = `mitre-item ${t.status === 'Completed' ? 'completed' : 'in-progress'}`;
            mItem.innerHTML = `
              <div style="font-weight:bold; font-size:11.5px; color:var(--text);">${escapeHtml(t.technique)}</div>
              <div style="display:flex; justify-content:space-between; font-size:10px; color:var(--dim); margin-top:4px;">
                <span>${escapeHtml(t.code)}</span>
                <span>${escapeHtml(t.status)}</span>
              </div>
            `;
            col.appendChild(mItem);
          });
          mitreGrid.appendChild(col);
        });
      }

      // --- REPORT GENERATOR ENGINE ---
      const reportFindingsSelection = document.getElementById('report-findings-selection');
      const printableReportSheet = document.getElementById('printable-report-sheet');
      const reportTitleInput = document.getElementById('report-title-input');
      const reportClientInput = document.getElementById('report-client-input');
      const exportPdfBtn = document.getElementById('export-pdf-btn');

      if (reportFindingsSelection) {
        reportFindingsSelection.innerHTML = '';
        currentFindings.forEach(f => {
          const label = document.createElement('label');
          label.style.display = 'flex';
          label.style.alignItems = 'center';
          label.style.gap = '8px';
          label.style.padding = '8px';
          label.style.background = 'var(--bg2)';
          label.style.border = '0.5px solid var(--border)';
          label.style.borderRadius = '4px';
          label.style.cursor = 'pointer';
          label.style.fontSize = '12px';
          label.style.color = 'var(--text)';
          
          label.innerHTML = `
            <input type="checkbox" value="${f.id}" style="accent-color:var(--red);">
            <span style="font-family:var(--mono); color:var(--red); font-size:11px;">[${escapeHtml(f.cveId || 'CVE-PENDING')}]</span>
            <span>${escapeHtml(f.title)}</span>
          `;
          
          label.querySelector('input').addEventListener('change', () => {
            rebuildReport();
          });
          
          reportFindingsSelection.appendChild(label);
        });
      }

      if (reportTitleInput) reportTitleInput.addEventListener('input', rebuildReport);
      if (reportClientInput) reportClientInput.addEventListener('input', rebuildReport);

      function rebuildReport() {
        if (!printableReportSheet) return;
        
        const title = reportTitleInput ? reportTitleInput.value.trim() : 'RedOps Telemetry Report';
        const client = reportClientInput ? reportClientInput.value.trim() : 'Internal Auditing';
        
        const selectedIds = [];
        if (reportFindingsSelection) {
          reportFindingsSelection.querySelectorAll('input:checked').forEach(input => {
            selectedIds.push(input.value);
          });
        }
        
        const checkedFindings = currentFindings.filter(f => selectedIds.includes(f.id));
        
        let findingsReportHtml = "";
        if (checkedFindings.length === 0) {
          findingsReportHtml = '<div style="text-align:center; padding:40px; color:var(--dim); font-style:italic;">No findings selected for telemetry report.</div>';
        } else {
          checkedFindings.forEach(f => {
            const sevLabel = severities[f.severityIndex] || 'Info';
            const sevClass = severityClasses[f.severityIndex] || 'badge-low';
            findingsReportHtml += `
              <div style="border: 1px solid var(--border); border-radius: 8px; padding: 18px; margin-bottom: 20px; background: var(--bg2);">
                <div style="display:flex; justify-content:space-between; border-bottom: 1px solid var(--border); padding-bottom: 10px; margin-bottom: 12px;">
                  <span style="font-family:var(--mono); font-weight:bold; color:var(--red); font-size:13px;">${escapeHtml(f.cveId || 'TACTICAL ENTRY')}</span>
                  <span class="badge ${sevClass}">${escapeHtml(sevLabel)}</span>
                </div>
                <h4 style="color:var(--text); font-size:15px; margin:0 0 10px 0;">${escapeHtml(f.title)}</h4>
                <p style="font-size:12.5px; color:var(--muted); line-height:1.5;">${escapeHtml(f.description)}</p>
                ${f.remediationPlan ? `
                  <div style="margin-top:12px; padding:10px; background:rgba(93,202,165,0.04); border-left:3px solid var(--green); font-size:12px;">
                    <strong style="color:var(--green); display:block; margin-bottom:4px;">REMEDIATION</strong>
                    <span style="color:var(--muted); line-height:1.4;">${escapeHtml(f.remediationPlan)}</span>
                  </div>
                ` : ''}
              </div>
            `;
          });
        }
        
        printableReportSheet.innerHTML = `
          <div style="border-bottom: 2px solid var(--red); padding-bottom: 15px; margin-bottom: 25px; text-align: center;">
            <h2 style="font-family:var(--mono); color:var(--red); font-size:22px; margin:0 0 8px 0; letter-spacing:1.5px;">REDOPS SECURITY TELEMETRY REPORT</h2>
            <div style="font-size:12px; color:var(--dim); font-family:var(--mono);">Target: ${escapeHtml(client)} | Compiled: ${new Date().toLocaleDateString()}</div>
          </div>
          <div style="margin-bottom: 25px;">
            <h3 style="color:var(--text); font-size:16px; margin:0 0 8px 0; border-bottom: 1px solid var(--border); padding-bottom: 6px;">${escapeHtml(title)}</h3>
            <p style="font-size:12.5px; color:var(--muted); line-height:1.5;">This secure tactical telemetry report outlines the vulnerabilities, configurations, and network reconnaissance intelligence captured during the active Red Team engagement.</p>
          </div>
          <div>
            ${findingsReportHtml}
          </div>
        `;
      }

      if (exportPdfBtn) {
        exportPdfBtn.addEventListener('click', () => {
          window.print();
          logOperatorActivity("REPORT_EXPORT", "Exported tactical PDF report sheet.");
        });
      }

      // --- ADMIN PANEL ACTION LISTENERS & LOGIC ---
      if (document.getElementById('admin-back-btn')) {
        document.getElementById('admin-back-btn').addEventListener('click', () => {
          isAdminUplinkRequested = false;
          if (adminScreen) adminScreen.style.display = 'none';
          if (dashboardScreen) dashboardScreen.style.display = 'flex';
          if (window.location.hash) window.location.hash = '';
          window.history.pushState({}, '', '/');
        });
      }

      if (document.getElementById('admin-logout-btn')) {
        document.getElementById('admin-logout-btn').addEventListener('click', () => {
          auth.signOut();
        });
      }

      // Render Admin operators directory table
      function renderAdminUsersTable(users, filterText = '') {
        const tableBody = document.getElementById('admin-users-table-body');
        if (!tableBody) return;
        tableBody.innerHTML = '';
        
        const filtered = users.filter(u => {
          const email = (u.email || '').toLowerCase();
          return email.includes(filterText.toLowerCase());
        });
        
        if (filtered.length === 0) {
          tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding: 20px; color: var(--muted); font-family: var(--mono); border-bottom: 1px solid rgba(255,255,255,0.04);">NO OPERATORS MATCHING QUERY</td></tr>`;
          return;
        }
        
        filtered.forEach(u => {
          const signupDate = u.createdAt ? new Date(u.createdAt).toLocaleString() : 'Legacy Account';
          const lastLogin = u.lastLogin ? new Date(u.lastLogin).toLocaleString() : 'Never';
          const platform = u.platform || 'Web';
          const isBanned = !!u.disabled;
          
          const row = document.createElement('tr');
          row.className = 'admin-user-row';
          row.innerHTML = `
            <td style="padding: 12px 10px; font-family: var(--mono); color: ${isBanned ? 'var(--red)' : '#FFF'};">${u.email} ${isBanned ? '<span style="font-size:9px; background:rgba(224,85,85,0.15); border:1px solid var(--red); border-radius:3px; padding:1px 4px; margin-left:6px; color:var(--red);">REVOKED</span>' : ''}</td>
            <td style="padding: 12px 10px; color: var(--muted);">${signupDate}</td>
            <td style="padding: 12px 10px; color: var(--muted);">${lastLogin}</td>
            <td style="padding: 12px 10px;">
              <span style="font-size:10px; font-family:var(--mono); padding: 3px 6px; border-radius:4px; background: ${platform === 'App' ? 'rgba(0,102,255,0.15)' : 'rgba(255,255,255,0.06)'}; border: 1px solid ${platform === 'App' ? 'rgba(0,102,255,0.3)' : 'rgba(255,255,255,0.1)'}; color: ${platform === 'App' ? '#66B2FF' : 'var(--text)'};">
                ${platform.toUpperCase()}
              </span>
            </td>
            <td style="padding: 12px 10px; text-align: right;">
              <button class="toggle-ban-btn ${isBanned ? 'admin-unban-btn' : 'admin-ban-btn'}" data-uid="${u.uid}" data-banned="${isBanned}">
                ${isBanned ? '🔓 ACTIVATE' : '🔒 REVOKE'}
              </button>
            </td>
          `;
          tableBody.appendChild(row);
        });
        
        // Bind Ban/Unban toggle triggers
        document.querySelectorAll('.toggle-ban-btn').forEach(btn => {
          btn.addEventListener('click', async (e) => {
            const uid = e.target.getAttribute('data-uid');
            const wasBanned = e.target.getAttribute('data-banned') === 'true';
            const action = wasBanned ? 'restore' : 'revoke';
            
            if (confirm(`Confirm tactical link ${action} for Operator UID: ${uid}?`)) {
              try {
                await db.collection("users").doc(uid).update({
                  disabled: !wasBanned
                });
                
                // Log audit log
                await db.collection("security_logs").add({
                  type: wasBanned ? "ADMIN_USER_RESTORE" : "ADMIN_USER_REVOKE",
                  targetUid: uid,
                  operatorEmail: auth.currentUser.email,
                  timestamp: Date.now()
                });
                
                // Force logout if banning yourself
                if (uid === auth.currentUser.uid) {
                  window.location.reload();
                  return;
                }
                
                // Reload telemetry stats
                loadAdminTelemetry(db);
              } catch (err) {
                alert("Action failed: " + err.message);
              }
            }
          });
        });
      }

      function setupUsersSearch(users) {
        const searchInput = document.getElementById('admin-search-users');
        if (!searchInput) return;
        searchInput.oninput = (e) => {
          renderAdminUsersTable(users, e.target.value);
        };
      }

      // Generate responsive acquisition chart
      function generateAcquisitionChart(users) {
        const now = new Date();
        const dayBuckets = {};
        
        for (let i = 6; i >= 0; i--) {
          const d = new Date(now);
          d.setDate(now.getDate() - i);
          const dateStr = d.toISOString().split('T')[0];
          dayBuckets[dateStr] = 0;
        }
        
        users.forEach(u => {
          if (u.createdAt) {
            const dateStr = new Date(u.createdAt).toISOString().split('T')[0];
            if (dayBuckets[dateStr] !== undefined) {
              dayBuckets[dateStr]++;
            }
          }
        });
        
        const values = Object.values(dayBuckets);
        const keys = Object.keys(dayBuckets).map(k => {
          const [_, m, d] = k.split('-');
          return `${m}/${d}`;
        });
        
        const maxVal = Math.max(...values, 1);
        const width = 500;
        const height = 120;
        const points = [];
        
        values.forEach((val, idx) => {
          const x = (idx / 6) * width;
          const y = height - (val / maxVal) * (height - 20) - 10;
          points.push(`${x},${y}`);
        });
        
        const pathEl = document.getElementById('admin-chart-path');
        if (pathEl) {
          pathEl.setAttribute('d', `M ${points.join(' L ')}`);
        }
        
        const labelsEl = document.getElementById('admin-chart-labels');
        if (labelsEl) {
          labelsEl.innerHTML = keys.map(k => `<span>${k}</span>`).join('');
        }
        
        const pointsContainer = document.getElementById('admin-chart-points');
        if (pointsContainer) {
          pointsContainer.innerHTML = points.map((p, idx) => {
            const [x, y] = p.split(',');
            return `<circle cx="${x}" cy="${y}" r="4" fill="#E05555" stroke="#FFF" stroke-width="1" />`;
          }).join('');
        }
      }

      // Load Security Access Audit Logs
      function loadSecurityLogs(db) {
        const logsTableBody = document.getElementById('admin-logs-table-body');
        if (!logsTableBody) return;
        
        db.collection("security_logs").orderBy("timestamp", "desc").limit(20).get().then((snapshot) => {
          logsTableBody.innerHTML = '';
          if (snapshot.empty) {
            logsTableBody.innerHTML = `<tr><td colspan="4" style="text-align:center; padding: 15px; color: var(--muted); font-family: var(--mono); border-bottom: 1px solid rgba(255,255,255,0.04);">NO SYSTEM ACCESS LOGS RECORDED</td></tr>`;
            return;
          }
          snapshot.forEach(doc => {
            const log = doc.data();
            let ts = 'Unknown';
            if (log.timestamp) {
              ts = log.timestamp.seconds ? new Date(log.timestamp.seconds * 1000).toLocaleString() : new Date(log.timestamp).toLocaleString();
            }
            
            const identity = log.email || log.operatorEmail || log.targetUid || 'System';
            const statusColor = (log.type.includes('FAIL') || log.type.includes('UNAUTHORIZED') || log.type.includes('REVOKE')) ? 'var(--red)' : '#00FF66';
            const statusLabel = (log.type.includes('FAIL') || log.type.includes('UNAUTHORIZED') || log.type.includes('REVOKE')) ? 'ALERT' : 'OK';
            
            const row = document.createElement('tr');
            row.style.borderBottom = '1px solid rgba(255, 255, 255, 0.04)';
            row.innerHTML = `
              <td style="padding: 10px; font-family: var(--mono); color: var(--muted);">${ts}</td>
              <td style="padding: 10px; font-family: var(--mono); color: #FFF; font-weight:bold;">${log.type}</td>
              <td style="padding: 10px; font-family: var(--mono); color: var(--text);">${identity}</td>
              <td style="padding: 10px; text-align: right;">
                <span style="font-family: var(--mono); color: ${statusColor}; font-size: 10px; font-weight:bold;">${statusLabel}</span>
              </td>
            `;
            logsTableBody.appendChild(row);
          });
        }).catch(e => console.error("Error loading security logs:", e));
      }

      // Log operator activities
      function logOperatorActivity(actionType, details) {
        if (typeof firebase !== 'undefined' && auth && auth.currentUser) {
          db.collection("activity_logs").add({
            operatorEmail: auth.currentUser.email,
            operatorUid: auth.currentUser.uid,
            actionType: actionType,
            details: details,
            timestamp: Date.now()
          }).catch(e => console.warn("Failed to log activity:", e));
        }
      }

      // Fetch and display operator activity logs
      function loadActivityLogs(db) {
        const tbody = document.getElementById('admin-activity-table-body');
        if (!tbody) return;
        db.collection("activity_logs").orderBy("timestamp", "desc").limit(20).get().then((snapshot) => {
          tbody.innerHTML = "";
          if (snapshot.empty) {
            tbody.innerHTML = '<tr><td colspan="4" style="text-align:center; padding: 15px; color: var(--muted); font-family: var(--mono); border-bottom: 1px solid rgba(255,255,255,0.04);">NO RECENT OPERATOR ACTIVITY DETECTED</td></tr>';
            return;
          }
          snapshot.forEach((doc) => {
            const log = doc.data();
            let timeStr = "Unknown";
            if (log.timestamp) {
              timeStr = new Date(log.timestamp).toLocaleString();
            }
            const tr = document.createElement("tr");
            tr.style.borderBottom = "1px solid rgba(255, 255, 255, 0.04)";
            tr.innerHTML = `
              <td style="padding: 10px; font-family: var(--mono); color: var(--muted);">${timeStr}</td>
              <td style="padding: 10px; font-family: var(--mono); color: #FFF;">${log.operatorEmail}</td>
              <td style="padding: 10px; font-family: var(--mono);"><span style="color: #66B2FF; font-weight: bold;">${log.actionType}</span></td>
              <td style="padding: 10px; font-family: var(--mono); text-align: right; color: var(--text);">${escapeHtml(log.details)}</td>
            `;
            tbody.appendChild(tr);
          });
        }).catch(e => console.error("Error loading activity logs:", e));
      }

      // Fetch and compute full admin statistics
      function loadAdminTelemetry(db) {
        // Reset Ad-Blocker/Offline Warning
        const connectionWarning = document.getElementById('admin-connection-warning');
        if (connectionWarning) connectionWarning.style.display = 'none';

        db.collection("users").get().then((snapshot) => {
          const users = [];
          let webCount = 0;
          let appCount = 0;
          let vaultsCount = 0;
          
          snapshot.forEach((doc) => {
            const u = doc.data();
            users.push(u);
            if (u.platform === 'App') appCount++;
            else webCount++;
            if (u.vaultKeyHash) vaultsCount++;
          });
          
          if (document.getElementById('admin-stat-users')) document.getElementById('admin-stat-users').textContent = users.length;
          if (document.getElementById('admin-stat-web-count')) document.getElementById('admin-stat-web-count').textContent = webCount;
          if (document.getElementById('admin-stat-app-count')) document.getElementById('admin-stat-app-count').textContent = appCount;
          if (document.getElementById('admin-stat-credentials')) document.getElementById('admin-stat-credentials').textContent = vaultsCount;
          
          renderAdminUsersTable(users);
          setupUsersSearch(users);
          generateAcquisitionChart(users);
        }).catch(e => {
          console.error("Error loading admin users:", e);
          const connectionWarning = document.getElementById('admin-connection-warning');
          if (connectionWarning) connectionWarning.style.display = 'flex';
        });

        db.collection("vulnerabilities").get().then((snapshot) => {
          if (document.getElementById('admin-stat-vulns')) document.getElementById('admin-stat-vulns').textContent = snapshot.size;
          
          const operatorCounts = {};
          snapshot.forEach((doc) => {
            const opUid = doc.data().operatorUid;
            if (opUid) {
              operatorCounts[opUid] = (operatorCounts[opUid] || 0) + 1;
            }
          });
          
          let maxCount = 0;
          let activeOp = 'None';
          for (const [op, count] of Object.entries(operatorCounts)) {
            if (count > maxCount) {
              maxCount = count;
              activeOp = op;
            }
          }
          
          if (document.getElementById('admin-stat-active-operator')) {
            document.getElementById('admin-stat-active-operator').textContent = activeOp !== 'None' ? `${activeOp.substring(0, 8)}... (${maxCount} findings)` : 'None';
          }
        }).catch(e => console.error("Error loading admin findings:", e));

        loadSecurityLogs(db);
        loadActivityLogs(db);

        // Double check FireStore connectivity to raise Ad-blocker banner if blocked
        db.collection("users").limit(1).get().catch(err => {
          if (err.message && (err.message.includes("offline") || err.message.includes("does not exist") || err.code === "unavailable")) {
            const connectionWarning = document.getElementById('admin-connection-warning');
            if (connectionWarning) connectionWarning.style.display = 'flex';
          }
        });
      }

      // Check URL route at script startup
      if (isAdminUplinkRequested) {
        openOverlay();
      }

      // Dynamic Hash Router (SPA-like routing)
      window.addEventListener('hashchange', () => {
        isAdminUplinkRequested = (
          window.location.pathname.includes('hq-terminal-omega') || 
          window.location.hash.includes('hq-terminal-omega') ||
          window.location.pathname.includes('hq_terminal_omega') || 
          window.location.hash.includes('hq_terminal_omega')
        );

        if (window.location.hash.includes('logout')) {
          sessionStorage.clear();
          if (auth) {
            auth.signOut().then(() => {
              window.location.hash = '';
              window.location.reload();
            });
          } else {
            window.location.hash = '';
            window.location.reload();
          }
          return;
        }

        if (isAdminUplinkRequested) {
          openOverlay();
          if (auth && auth.currentUser) {
            auth.currentUser.getIdTokenResult(true).then((idTokenResult) => {
              if (idTokenResult.claims.admin) {
                if (authScreen) authScreen.style.display = 'none';
                if (dashboardScreen) dashboardScreen.style.display = 'none';
                if (adminScreen) adminScreen.style.display = 'flex';
                loadAdminTelemetry(db);
              } else {
                alert("ACCESS DENIED: Administrative credentials required.");
                window.location.href = '/';
              }
            }).catch(() => {
              window.location.href = '/';
            });
          } else {
            if (authScreen) authScreen.style.display = 'flex';
            if (dashboardScreen) dashboardScreen.style.display = 'none';
            if (adminScreen) adminScreen.style.display = 'none';
          }
        } else {
          // Normal route
          const overlayActive = overlay && overlay.classList.contains('active');
          if (overlayActive) {
            if (auth && auth.currentUser) {
              if (authScreen) authScreen.style.display = 'none';
              if (dashboardScreen) dashboardScreen.style.display = 'flex';
              if (adminScreen) adminScreen.style.display = 'none';
            } else {
              if (authScreen) authScreen.style.display = 'flex';
              if (dashboardScreen) dashboardScreen.style.display = 'none';
              if (adminScreen) adminScreen.style.display = 'none';
            }
          }
        }
      });

      rebuildReport();

    } catch (err) {
      console.error("Firebase SDK init failure: " + err.message);
    }
  } else {
    console.warn("Firebase SDK was not loaded. Web client running in mock/demo mode.");
    const authErrorMsg = document.getElementById('auth-error-msg');
    if (authErrorMsg) {
      authErrorMsg.textContent = "WARNING: Offline local mode active. Database synchronization is disabled.";
      authErrorMsg.style.display = 'block';
    }
  }
});
