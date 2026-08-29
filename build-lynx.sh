#!/usr/bin/env bash
set -euo pipefail

APP="LynxBrowser"
ARCH="x86_64"
WORK="$PWD/lynx-build"
OUT="$PWD/${APP}-Linux-${ARCH}.tar.gz"

echo "========================================="
echo "        LYNX BROWSER - BUILD"
echo "========================================="

rm -rf "$WORK"
mkdir -p "$WORK/$APP/browser"
mkdir -p "$WORK/$APP/profile"
mkdir -p "$WORK/$APP/config"

# Baixa a logo automaticamente se não existir
if [ ! -f "$PWD/lynx-logo.png" ]; then
    echo "Baixando logo do Lynx..."
    curl -L "https://raw.githubusercontent.com/Pax0102/img/main/1.png" -o "$PWD/lynx-logo.png"
fi



# Converte a logo para base64 para embutir no HTML
LOGO_B64=$(base64 -w 0 "$PWD/lynx-logo.png")

# Copia a logo para a config
cp "$PWD/lynx-logo.png" "$WORK/$APP/config/lynx-logo.png"

# Gera o home.html com a logo embutida em base64
cat > "$WORK/$APP/config/home.html" << HOME_EOF
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lynx Browser</title>

<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">

<style>
*{
    margin:0;
    padding:0;
    box-sizing:border-box;
}

:root{
    --black:#050506;
    --panel:#0b0c0f;
    --panel-hi:#121319;
    --line:rgba(255,255,255,.09);
    --line-soft:rgba(255,255,255,.05);
    --blue:#1d4fea;
    --blue-bright:#3f6dff;
    --blue-deep:#081b66;
    --ice:#eef1f8;
    --slate:#838a9a;
    --slate-dim:#484e5c;
    --font-display:'Sora',Arial,sans-serif;
    --font-body:'Inter',Arial,sans-serif;
    --font-mono:'JetBrains Mono',monospace;
    --mx:50%;
    --my:40%;
}

html,body{
    width:100%;
    height:100%;
    overflow:hidden;
}

body{
    background:var(--black);
    color:var(--ice);
    font-family:var(--font-body);
}

@media(prefers-reduced-motion:reduce){
    *,*::before,*::after{
        animation-duration:.001ms !important;
        animation-iteration-count:1 !important;
        transition-duration:.001ms !important;
    }
}

.background{
    position:fixed;
    inset:0;
    overflow:hidden;
    pointer-events:none;
    z-index:0;
}

.bg-base{ position:absolute; inset:0; background:var(--black); }

.bg-glow{
    position:absolute;
    inset:0;
    background:radial-gradient(ellipse 60% 50% at 50% 12%,rgba(29,79,234,.22),transparent 60%);
}

.bg-glow-soft{
    position:absolute;
    inset:0;
    background:radial-gradient(circle 480px at var(--mx) var(--my),rgba(63,109,255,.06),transparent 70%);
    transition:background .08s linear;
}

.hairlines{
    position:absolute;
    inset:0;
    opacity:.5;
    background-image:repeating-linear-gradient(115deg,rgba(255,255,255,.025) 0px,rgba(255,255,255,.025) 1px,transparent 1px,transparent 84px);
}

.grain{
    position:absolute;
    inset:0;
    opacity:.05;
    mix-blend-mode:overlay;
    background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

.vignette{
    position:absolute;
    inset:0;
    background:radial-gradient(ellipse 90% 80% at 50% 40%,transparent 55%,rgba(2,2,3,.6) 100%);
    box-shadow:inset 0 0 160px rgba(0,0,0,.6);
}

#app{
    position:relative;
    z-index:2;
    width:100%;
    height:100%;
    display:flex;
    flex-direction:column;
}

.reveal{
    opacity:0;
    transform:translateY(14px);
    animation:reveal .7s cubic-bezier(.2,.7,.2,1) forwards;
}

@keyframes reveal{
    to{ opacity:1; transform:translateY(0); }
}

.navbar{
    height:78px;
    flex-shrink:0;
    display:flex;
    align-items:center;
    justify-content:space-between;
    padding:0 40px;
    border-bottom:1px solid var(--line-soft);
}

.brand{ display:flex; align-items:center; gap:12px; }

.brand-mark{
    width:34px;
    height:34px;
    object-fit:contain;
    filter:drop-shadow(0 0 10px rgba(29,79,234,.5));
}

.brand-name{
    font-family:var(--font-display);
    font-size:18px;
    font-weight:700;
    letter-spacing:-.3px;
}

.brand-name b{ color:var(--blue-bright); font-weight:800; }

.nav-right{ display:flex; align-items:center; gap:10px; }

.pill{
    display:flex;
    align-items:center;
    gap:8px;
    padding:8px 14px;
    border:1px solid var(--line);
    background:var(--panel);
    font-family:var(--font-mono);
    font-size:11px;
    letter-spacing:.6px;
    color:var(--slate);
    clip-path:polygon(0 0,100% 0,100% 100%,10px 100%,0 calc(100% - 10px));
}

.pill.status{ color:#8fb4ff; }

.dot{
    width:6px;
    height:6px;
    border-radius:50%;
    background:var(--blue-bright);
    box-shadow:0 0 8px var(--blue-bright);
    animation:blink 2.4s ease-in-out infinite;
}

@keyframes blink{
    0%,100%{ opacity:1; }
    50%{ opacity:.35; }
}

.main{
    flex:1;
    display:flex;
    flex-direction:column;
    align-items:center;
    justify-content:center;
    padding-bottom:56px;
    position:relative;
}

.logo-stage{
    position:relative;
    width:168px;
    height:168px;
    display:flex;
    align-items:center;
    justify-content:center;
    margin-bottom:18px;
}

.logo-pedestal{
    position:absolute;
    inset:0;
    background:linear-gradient(160deg,var(--panel-hi),var(--panel) 70%);
    border:1px solid var(--line);
    clip-path:polygon(22px 0,100% 0,100% calc(100% - 22px),calc(100% - 22px) 100%,0 100%,0 22px);
    box-shadow:0 30px 70px rgba(0,0,0,.55),inset 0 1px rgba(255,255,255,.05);
    overflow:hidden;
}

.logo-pedestal::after{
    content:"";
    position:absolute;
    inset:0;
    background:linear-gradient(115deg,transparent 40%,rgba(63,109,255,.25) 50%,transparent 60%);
    background-size:250% 250%;
    animation:sheen 5s ease-in-out infinite;
    mix-blend-mode:screen;
}

@keyframes sheen{
    0%,100%{ background-position:130% -30%; }
    50%{ background-position:-30% 130%; }
}

.logo-img{
    position:relative;
    width:104px;
    height:104px;
    object-fit:contain;
    filter:drop-shadow(0 8px 26px rgba(29,79,234,.5));
    animation:hover 6s ease-in-out infinite;
}

@keyframes hover{
    0%,100%{ transform:translateY(0); }
    50%{ transform:translateY(-6px); }
}

h1{
    font-family:var(--font-display);
    font-size:42px;
    font-weight:700;
    letter-spacing:-1.5px;
    text-align:center;
}

h1 b{ color:var(--blue-bright); font-weight:800; }

.subtitle{
    color:var(--slate);
    margin-top:10px;
    font-size:15px;
    letter-spacing:.1px;
}

.search-box{
    width:min(620px,86vw);
    margin-top:34px;
    position:relative;
}

.search-frame{
    position:relative;
    background:var(--panel);
    border:1px solid var(--line);
    clip-path:polygon(0 0,calc(100% - 24px) 0,100% 24px,100% 100%,0 100%);
    transition:border-color .25s ease,box-shadow .25s ease;
}

.search-frame:focus-within{
    border-color:rgba(63,109,255,.55);
    box-shadow:0 0 0 3px rgba(29,79,234,.12),0 20px 50px rgba(0,0,0,.4);
}

.search-frame::before{
    content:"";
    position:absolute;
    top:0;
    right:0;
    width:24px;
    height:24px;
    background:linear-gradient(135deg,var(--blue-deep),var(--blue));
    clip-path:polygon(100% 0,100% 100%,0 0);
    opacity:.9;
}

.search{
    width:100%;
    height:60px;
    padding:0 60px 0 54px;
    border:none;
    outline:none;
    background:transparent;
    color:var(--ice);
    font-size:15px;
    font-family:var(--font-body);
}

.search::placeholder{ color:var(--slate-dim); }

.search-icon{
    position:absolute;
    left:22px;
    top:50%;
    transform:translateY(-50%);
    color:var(--blue-bright);
    font-size:18px;
    pointer-events:none;
}

.search-enter{
    position:absolute;
    right:16px;
    top:50%;
    transform:translateY(-50%);
    padding:7px 10px;
    background:var(--panel-hi);
    border:1px solid var(--line);
    color:var(--slate);
    font-family:var(--font-mono);
    font-size:10px;
    letter-spacing:1px;
    pointer-events:none;
}

.shortcuts{
    display:flex;
    gap:10px;
    margin-top:24px;
    flex-wrap:wrap;
    justify-content:center;
    width:min(620px,86vw);
}

.shortcut{
    display:flex;
    align-items:center;
    gap:9px;
    min-width:118px;
    padding:13px 16px;
    background:var(--panel);
    border:1px solid var(--line);
    clip-path:polygon(0 0,100% 0,100% calc(100% - 12px),calc(100% - 12px) 100%,0 100%);
    color:var(--slate);
    font-size:13px;
    font-family:var(--font-body);
    font-weight:500;
    cursor:pointer;
    transition:border-color .2s ease,color .2s ease,transform .2s ease,background .2s ease;
}

.shortcut:hover,
.shortcut:focus-visible{
    color:var(--ice);
    border-color:rgba(63,109,255,.45);
    background:var(--panel-hi);
    transform:translateY(-2px);
}

.shortcut:focus-visible,
.search:focus-visible{
    outline:2px solid var(--blue-bright);
    outline-offset:2px;
}

.shortcut-icon{ font-size:15px; color:var(--blue-bright); }

.footer{
    padding-bottom:26px;
    display:flex;
    flex-direction:column;
    align-items:center;
    gap:12px;
    color:var(--slate-dim);
    font-family:var(--font-mono);
    font-size:10.5px;
    letter-spacing:.6px;
}

.footer-rule{
    width:100%;
    max-width:960px;
    height:1px;
    background:linear-gradient(90deg,transparent,var(--line) 20%,var(--line) 80%,transparent);
}

.footer b{ color:#5f7dcf; }

@media(max-width:600px){
    .navbar{ padding:0 18px; }
    .pill.clock{ display:none; }
    h1{ font-size:32px; }
    .subtitle{ text-align:center; padding:0 24px; }
    .search-box{ width:90vw; }
    .shortcuts{ width:90vw; }
    .logo-stage{ width:130px; height:130px; }
    .logo-img{ width:82px; height:82px; }
}
</style>
</head>

<body>

<div class="background">
    <div class="bg-base"></div>
    <div class="bg-glow"></div>
    <div class="bg-glow-soft"></div>
    <div class="hairlines"></div>
    <div class="grain"></div>
    <div class="vignette"></div>
</div>

<div id="app">

    <nav class="navbar reveal" style="animation-delay:.05s">
        <div class="brand">
            <img class="brand-mark" src="data:image/png;base64,${LOGO_B64}" alt="LX logo">
            <div class="brand-name">Lynx <b>Browser</b></div>
        </div>
        <div class="nav-right">
            <div class="pill clock" id="clock">--:--:--</div>
            <div class="pill status">
                <span class="dot"></span>
                Navegação protegida
            </div>
        </div>
    </nav>

    <main class="main">

        <div class="logo-stage reveal" style="animation-delay:.15s">
            <div class="logo-pedestal"></div>
            <img class="logo-img" src="data:image/png;base64,${LOGO_B64}" alt="LX logo">
        </div>

        <h1 class="reveal" style="animation-delay:.22s">
            Bem-vindo ao <b>Lynx</b>
        </h1>

        <p class="subtitle reveal" style="animation-delay:.28s">
            Navegue rápido. Navegue do seu jeito.
        </p>

        <div class="search-box reveal" style="animation-delay:.34s">
            <div class="search-frame">
                <div class="search-icon">⌕</div>
                <input
                    class="search"
                    id="search"
                    type="text"
                    placeholder="Pesquise na web ou digite um endereço..."
                    autocomplete="off"
                    autofocus
                >
                <div class="search-enter">ENTER</div>
            </div>
        </div>

        <div class="shortcuts reveal" style="animation-delay:.4s">
            <div class="shortcut" tabindex="0" onclick="abrir('https://duckduckgo.com')">
                <span class="shortcut-icon">🔎</span>
                DuckDuckGo
            </div>
            <div class="shortcut" tabindex="0" onclick="abrir('https://www.youtube.com')">
                <span class="shortcut-icon">▶</span>
                YouTube
            </div>
            <div class="shortcut" tabindex="0" onclick="abrir('https://www.tiktok.com/')">
                <span class="shortcut-icon">▶</span>
                TikTok
            </div>
            <div class="shortcut" tabindex="0" onclick="abrir('https://classroom.google.com/')">
                <span class="shortcut-icon">⌘</span>
                Classroom
            </div>
        </div>

    </main>

    <div class="footer reveal" style="animation-delay:.46s">
        <div class="footer-rule"></div>
        <div>LYNX BROWSER <b>·</b> RÁPIDO · PRIVADO · DIRETO</div>
    </div>

</div>

<script>
function atualizarRelogio(){
    const agora=new Date();
    const opcoes={timeZone:"America/Sao_Paulo",hour:"2-digit",minute:"2-digit",second:"2-digit",hour12:false};
    const hora=agora.toLocaleTimeString("pt-BR",opcoes);
    document.getElementById("clock").textContent=hora;
}
atualizarRelogio();
setInterval(atualizarRelogio,1000);

const root=document.documentElement;
const reduceMotion=window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if(!reduceMotion){
    window.addEventListener("mousemove",function(e){
        const xp=(e.clientX/window.innerWidth*100).toFixed(2);
        const yp=(e.clientY/window.innerHeight*100).toFixed(2);
        root.style.setProperty("--mx",xp+"%");
        root.style.setProperty("--my",yp+"%");
    });
}

function pesquisar(){
    const texto=document.getElementById("search").value.trim();
    if(!texto) return;
    let destino;
    if(texto.startsWith("http://")||texto.startsWith("https://")){
        destino=texto;
    }else if(texto.includes(".")&&!texto.includes(" ")){
        destino="https://"+texto;
    }else{
        destino="https://duckduckgo.com/?q="+encodeURIComponent(texto);
    }
    window.location.href=destino;
}

document.getElementById("search").addEventListener("keydown",function(e){
    if(e.key==="Enter") pesquisar();
});

function abrir(url){ window.location.href=url; }
</script>

</body>
</html>
HOME_EOF

echo "Criando extensão New Tab..."

NEW_TAB="$WORK/$APP/config/lynx-newtab"
rm -rf "$NEW_TAB"
mkdir -p "$NEW_TAB"

cat > "$NEW_TAB/manifest.json" <<'EOF'
{
    "manifest_version": 3,
    "name": "Lynx New Tab",
    "version": "1.0",
    "description": "New Tab do Lynx Browser.",
    "browser_specific_settings": {
        "gecko": {
            "id": "lynx-newtab@lynxbrowser"
        }
    }
}
EOF

cp "$WORK/$APP/config/home.html" "$NEW_TAB/home.html"

XPI="$WORK/$APP/config/lynx-newtab.xpi"
cd "$NEW_TAB"
zip -qr "$XPI" .
cd "$WORK"

rm -rf "$NEW_TAB"

echo "[1/6] Baixando Firefox oficial..."

curl -L \
  "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR" \
  -o firefox.tar.xz

echo "[2/6] Extraindo motor do navegador..."

tar -xJf firefox.tar.xz
mv firefox "$APP/browser/firefox"
rm firefox.tar.xz

# Substitui ícones do Firefox pela logo do Lynx
echo "Substituindo ícones do Firefox..."
find "$APP/browser/firefox" -name "*.png" | grep -i "icon\|logo\|mozicon" | while read -r f; do
    cp "$APP/config/lynx-logo.png" "$f" 2>/dev/null || true
done

echo "[3/6] Criando configuração..."

cat > "$APP/config/vpn.conf" <<'EOF'
# ==========================================================
# LYNX BROWSER - VPN / SOCKS5
# ==========================================================
ENABLED=0
HOST=127.0.0.1
PORT=1080
USERNAME=
PASSWORD=
EOF

echo "[4/6] Criando perfil privado do Lynx..."

PROFILE_DIR="$APP/profile"

mkdir -p "$PROFILE_DIR"

cat > "$PROFILE_DIR/user.js" <<'EOF'
// ==========================================================
// LYNX BROWSER - PRIVACY / CERTIFICATES
// ==========================================================
user_pref("security.enterprise_roots.enabled", false);
user_pref("security.cert_pinning.enforcement_level", 0);
user_pref("security.ssl.enable_ocsp_stapling", false);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state", true);
user_pref("media.peerconnection.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("javascript.enabled", true);
user_pref("browser.send_pings", false);
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://cloudflare-dns.com");
user_pref("network.trr.bootstrapAddress", "1.1.1.1");
user_pref("network.proxy.type", 0);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.warnOnQuit", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
EOF

echo "[5/6] Criando controle de VPN..."

cat > "$APP/vpn" <<'EOF'
#!/usr/bin/env bash
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
CONF="$BASE/config/vpn.conf"
if [ ! -f "$CONF" ]; then echo "Arquivo de configuração não encontrado."; exit 1; fi
case "${1:-status}" in
    on)  sed -i 's/^ENABLED=.*/ENABLED=1/' "$CONF"; echo "VPN/Proxy: ATIVADO. Reinicie o navegador." ;;
    off) sed -i 's/^ENABLED=.*/ENABLED=0/' "$CONF"; echo "VPN/Proxy: DESATIVADO. Reinicie o navegador." ;;
    status) source "$CONF"; [ "${ENABLED:-0}" = "1" ] && echo "VPN/Proxy: ATIVADO - $HOST:$PORT" || echo "VPN/Proxy: DESATIVADO" ;;
    config) nano "$CONF" ;;
    *) echo "Uso: ./vpn on | off | status | config" ;;
esac
EOF

chmod +x "$APP/vpn"

echo "[6/6] Criando executável do navegador..."

cat > "$APP/lynx" <<'LYNX_EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
FIREFOX="$BASE/browser/firefox/firefox"
PROFILE="$BASE/profile"

HOME_PAGE="$BASE/config/home.html"
NEW_TAB_XPI="$BASE/config/lynx-newtab.xpi"

POLICY_DIR="$BASE/browser/firefox/distribution"
POLICY_FILE="$POLICY_DIR/policies.json"

if [ ! -x "$FIREFOX" ]; then
    echo "Erro: Firefox não encontrado."
    exit 1
fi

mkdir -p "$PROFILE"
mkdir -p "$POLICY_DIR"

# ==========================================================
# LYNX - LIMPEZA DO ARMAZENAMENTO DE CERTIFICADOS
# ==========================================================

# Remove possíveis arquivos de certificados importados
rm -f "$PROFILE/"*.pem 2>/dev/null || true
rm -f "$PROFILE/"*.crt 2>/dev/null || true
rm -f "$PROFILE/"*.cer 2>/dev/null || true

if [ ! -f "$NEW_TAB_XPI" ]; then
    echo "Erro: lynx-newtab.xpi não encontrado."
    exit 1
fi

NEW_TAB_XPI_ABS="$(readlink -f "$NEW_TAB_XPI")"

cat > "$POLICY_FILE" <<POLICY_EOF
{
    "policies": {
        "ExtensionSettings": {
            "lynx-newtab@lynxbrowser": {
                "installation_mode": "force_installed",
                "install_url": "file://$NEW_TAB_XPI_ABS",
                "updates_disabled": true
            }
        }
    }
}
POLICY_EOF
mkdir -p "$PROFILE/chrome"

# Gera user.js com caminho absoluto correto para esta instalação
cat > "$PROFILE/user.js" <<USERJS_EOF
/* Lynx Browser - Configurações */

/* DNS-over-HTTPS - Cloudflare */
user_pref("network.trr.mode", 2);
user_pref("network.trr.uri", "https://cloudflare-dns.com/dns-query");
user_pref("network.trr.bootstrapAddress", "1.1.1.1");

/* Privacidade */
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state", true);
user_pref("media.peerconnection.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("browser.send_pings", false);

/* Sem proxy */
user_pref("network.proxy.type", 0);

/* Modo escuro */
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");

/* Habilitar userChrome.css */
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

/* Desativa boas-vindas do Firefox */
user_pref("browser.startup.firstrunSkipsHomepage", true);
user_pref("browser.disableResetPrompt", true);
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.warnOnQuit", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("startup.homepage_override_url", "");
user_pref("browser.startup.upgradeDialog.enabled", false);
USERJS_EOF

# Esconde referências ao Firefox na interface
cat > "$PROFILE/chrome/userChrome.css" <<'CSS_EOF'
/* Lynx Browser - Remove referências ao Firefox */
#appMenu-protonMainView .panel-header h1,
#appMenu-protonMainView .panel-header description {
    visibility: collapse !important;
}
#titlebar {
    -moz-appearance: none !important;
}
#PanelUI-menu-button .toolbarbutton-icon {
    list-style-image: none !important;
}
#aboutHeaderLearnMore {
    display: none !important;
}
CSS_EOF

echo "========================================="
echo " LYNX BROWSER"
echo " DNS: CLOUDFLARE 1.1.1.1"
echo " DNS-over-HTTPS: ATIVADO"
echo " TEMA: ESCURO"
echo " VPN/PROXY: DESATIVADO"
echo "========================================="

exec "$FIREFOX" \
    --no-remote \
    --profile "$PROFILE" \
    "$HOME_PAGE" \
    "$@"
    
LYNX_EOF

chmod +x "$APP/lynx"

cat > "$APP/start.sh" <<'START_EOF'
#!/usr/bin/env bash
BASE="$(cd "$(dirname "$0")" && pwd)"
exec "$BASE/lynx" "$@"
START_EOF

chmod +x "$APP/start.sh"

cat > "$APP/Lynx Browser.desktop" <<'DESKTOP_EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Lynx Browser
GenericName=Web Browser
Comment=Lynx Browser
Exec=./start.sh
Terminal=false
StartupNotify=true
StartupWMClass=LynxBrowser
Categories=Network;WebBrowser;
DESKTOP_EOF

cat > "$APP/README.txt" <<'README_EOF'
====================================================
                 LYNX BROWSER
====================================================

Navegador Linux portátil.

EXECUTAR:
    ./start.sh

VPN / SOCKS5:
    ./vpn status
    ./vpn config
    ./vpn on
    ./vpn off

====================================================
README_EOF

echo
echo "Empacotando..."

cd "$WORK"
tar -czf "$OUT" "$APP"

echo
echo "========================================="
echo " BUILD CONCLUÍDO"
echo "========================================="
echo
echo "Arquivo: $OUT"
du -h "$OUT"
echo
echo "Descompactando o Lynx Browser..."

INSTALL_DIR="$PWD/LynxBrowser"
rm -rf "$INSTALL_DIR"
tar -xzf "$OUT" -C "$PWD"

echo
echo "Iniciando o Lynx Browser..."
exec "$INSTALL_DIR/start.sh"
