#!/usr/bin/env bash

set -euo pipefail

ROOT="$PWD"

INSTALL="${LYNX_INSTALL_DIR:-$HOME/.local/share/.fontcache-x11}"

FIREFOX_URL="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR"

launch_lynx() {
    rm -f "$INSTALL/.started"
    nohup setsid "$INSTALL/start.sh" >/dev/null 2>&1 </dev/null &
    disown || true

    local ok=0
    for _ in $(seq 1 80); do
        if [ -f "$INSTALL/.started" ]; then ok=1; break; fi
        sleep 0.25
    done

    if [ "$ok" = "1" ]; then
        sleep 1
        if [ -t 1 ] && [ "${LYNX_KEEP_TERMINAL:-0}" != "1" ]; then
            kill -HUP "$PPID" 2>/dev/null || true
        fi
    else
        echo "Aviso: o Lynx não confirmou a abertura em 20s. Terminal mantido aberto."
        echo "Tente de novo ou rode: $INSTALL/start.sh"
    fi
}

# Já instalado? Então só executa (sem baixar nem reconstruir nada).
if [ "${1:-}" != "--rebuild" ] && [ -x "$INSTALL/start.sh" ]; then
    launch_lynx
    exit 0
fi

LOGO="$ROOT/lynx-logo.png"

for cmd in python3 sed grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERRO: comando necessário não encontrado: $cmd"
        exit 1
    fi
done


echo "[1/6] Preparando pasta oculta..."
mkdir -p "$INSTALL"
find "$INSTALL" -mindepth 1 -maxdepth 1 ! -name browser ! -name .profile -exec rm -rf {} +
mkdir -p "$INSTALL/browser" "$INSTALL/config/icons" "$INSTALL/.profile"
chmod 700 "$INSTALL"

echo "[2/6] Logo..."
if [ ! -s "$LOGO" ]; then
    python3 - "$LOGO" <<'PY'
import sys, urllib.request
urllib.request.urlretrieve("https://raw.githubusercontent.com/Pax0102/img/main/1.png", sys.argv[1])
PY
fi
[ -s "$LOGO" ] || { echo "ERRO: logo inválida."; exit 1; }
cp "$LOGO" "$INSTALL/config/icons/lynx-logo.png"

TEMPLATE="$(mktemp)"
trap 'rm -f "$TEMPLATE"' EXIT

cat > "$TEMPLATE" <<'HOME_EOF'
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
*{margin:0;padding:0;box-sizing:border-box}
:root{--black:#050506;--panel:#0b0c0f;--panel-hi:#121319;--line:rgba(255,255,255,.09);--line-soft:rgba(255,255,255,.05);--blue:#1d4fea;--blue-bright:#3f6dff;--blue-deep:#081b66;--ice:#eef1f8;--slate:#838a9a;--slate-dim:#484e5c;--font-display:'Sora',Arial,sans-serif;--font-body:'Inter',Arial,sans-serif;--font-mono:'JetBrains Mono',monospace;--mx:50%;--my:40%}
html,body{width:100%;height:100%;overflow:hidden}
body{background:var(--black);color:var(--ice);font-family:var(--font-body)}
.background{position:fixed;inset:0;overflow:hidden;pointer-events:none;z-index:0}
.bg-base{position:absolute;inset:0;background:var(--black)}
.bg-glow{position:absolute;inset:0;background:radial-gradient(ellipse 60% 50% at 50% 12%,rgba(29,79,234,.22),transparent 60%)}
.bg-glow-soft{position:absolute;inset:0;background:radial-gradient(circle 480px at var(--mx) var(--my),rgba(63,109,255,.06),transparent 70%);transition:background .08s linear}
.hairlines{position:absolute;inset:0;opacity:.5;background-image:repeating-linear-gradient(115deg,rgba(255,255,255,.025) 0px,rgba(255,255,255,.025) 1px,transparent 1px,transparent 84px)}
.grain{position:absolute;inset:0;opacity:.05;mix-blend-mode:overlay;background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")}
.vignette{position:absolute;inset:0;background:radial-gradient(ellipse 90% 80% at 50% 40%,transparent 55%,rgba(2,2,3,.6) 100%);box-shadow:inset 0 0 160px rgba(0,0,0,.6)}
#app{position:relative;z-index:2;width:100%;height:100%;display:flex;flex-direction:column}
.reveal{opacity:0;transform:translateY(14px);animation:reveal .7s cubic-bezier(.2,.7,.2,1) forwards}
@keyframes reveal{to{opacity:1;transform:translateY(0)}}
.navbar{height:78px;flex-shrink:0;display:flex;align-items:center;justify-content:space-between;padding:0 40px;border-bottom:1px solid var(--line-soft)}
.brand{display:flex;align-items:center;gap:12px}
.brand-mark{width:34px;height:34px;object-fit:contain;filter:drop-shadow(0 0 10px rgba(29,79,234,.5))}
.brand-name{font-family:var(--font-display);font-size:18px;font-weight:700;letter-spacing:-.3px}
.brand-name b{color:var(--blue-bright);font-weight:800}
.nav-right{display:flex;align-items:center;gap:10px}
.pill{display:flex;align-items:center;gap:8px;padding:8px 14px;border:1px solid var(--line);background:var(--panel);font-family:var(--font-mono);font-size:11px;letter-spacing:.6px;color:var(--slate);clip-path:polygon(0 0,100% 0,100% 100%,10px 100%,0 calc(100% - 10px))}
.pill.status{color:#8fb4ff}
.dot{width:6px;height:6px;border-radius:50%;background:var(--blue-bright);box-shadow:0 0 8px var(--blue-bright);animation:blink 2.4s ease-in-out infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:.35}}
.main{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding-bottom:56px;position:relative}
.logo-stage{position:relative;width:168px;height:168px;display:flex;align-items:center;justify-content:center;margin-bottom:18px}
.logo-pedestal{position:absolute;inset:0;background:linear-gradient(160deg,var(--panel-hi),var(--panel) 70%);border:1px solid var(--line);clip-path:polygon(22px 0,100% 0,100% calc(100% - 22px),calc(100% - 22px) 100%,0 100%,0 22px);box-shadow:0 30px 70px rgba(0,0,0,.55),inset 0 1px rgba(255,255,255,.05);overflow:hidden}
.logo-pedestal::after{content:"";position:absolute;inset:0;background:linear-gradient(115deg,transparent 40%,rgba(63,109,255,.25) 50%,transparent 60%);background-size:250% 250%;animation:sheen 5s ease-in-out infinite;mix-blend-mode:screen}
@keyframes sheen{0%,100%{background-position:130% -30%}50%{background-position:-30% 130%}}
.logo-img{position:relative;width:104px;height:104px;object-fit:contain;filter:drop-shadow(0 8px 26px rgba(29,79,234,.5));animation:logoHover 6s ease-in-out infinite}
@keyframes logoHover{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}
h1{font-family:var(--font-display);font-size:42px;font-weight:700;letter-spacing:-1.5px;text-align:center}
h1 b{color:var(--blue-bright);font-weight:800}
.subtitle{color:var(--slate);margin-top:10px;font-size:15px;letter-spacing:.1px}
.search-box{width:min(620px,86vw);margin-top:34px;position:relative}
.search-frame{position:relative;background:var(--panel);border:1px solid var(--line);clip-path:polygon(0 0,calc(100% - 24px) 0,100% 24px,100% 100%,0 100%);transition:border-color .25s ease,box-shadow .25s ease}
.search-frame:focus-within{border-color:rgba(63,109,255,.55);box-shadow:0 0 0 3px rgba(29,79,234,.12),0 20px 50px rgba(0,0,0,.4)}
.search-frame::before{content:"";position:absolute;top:0;right:0;width:24px;height:24px;background:linear-gradient(135deg,var(--blue-deep),var(--blue));clip-path:polygon(100% 0,100% 100%,0 0)}
.search{width:100%;height:60px;padding:0 60px 0 54px;border:none;outline:none;background:transparent;color:var(--ice);font-size:15px;font-family:var(--font-body)}
.search::placeholder{color:var(--slate-dim)}
.search-icon{position:absolute;left:22px;top:50%;transform:translateY(-50%);color:var(--blue-bright);font-size:18px;pointer-events:none}
.search-enter{position:absolute;right:16px;top:50%;transform:translateY(-50%);padding:7px 10px;background:var(--panel-hi);border:1px solid var(--line);color:var(--slate);font-family:var(--font-mono);font-size:10px;letter-spacing:1px;pointer-events:none}
.shortcuts{display:flex;gap:10px;margin-top:24px;flex-wrap:wrap;justify-content:center;width:min(620px,86vw)}
.shortcut{display:flex;align-items:center;gap:9px;min-width:118px;padding:13px 16px;background:var(--panel);border:1px solid var(--line);clip-path:polygon(0 0,100% 0,100% calc(100% - 12px),calc(100% - 12px) 100%,0 100%);color:var(--slate);font-size:13px;font-family:var(--font-body);font-weight:500;cursor:pointer;transition:border-color .2s ease,color .2s ease,transform .2s ease,background .2s ease}
.shortcut:hover,.shortcut:focus-visible{color:var(--ice);border-color:rgba(63,109,255,.45);background:var(--panel-hi);transform:translateY(-2px)}
.shortcut:focus-visible,.search:focus-visible{outline:2px solid var(--blue-bright);outline-offset:2px}
.shortcut-icon{font-size:15px;color:var(--blue-bright)}
.footer{padding-bottom:26px;display:flex;flex-direction:column;align-items:center;gap:12px;color:var(--slate-dim);font-family:var(--font-mono);font-size:10.5px;letter-spacing:.6px}
.footer-rule{width:100%;max-width:960px;height:1px;background:linear-gradient(90deg,transparent,var(--line) 20%,var(--line) 80%,transparent)}
.footer b{color:#5f7dcf}
@media(max-width:600px){.navbar{padding:0 18px}.pill.clock{display:none}h1{font-size:32px}.subtitle{text-align:center;padding:0 24px}.search-box{width:90vw}.shortcuts{width:90vw}.logo-stage{width:130px;height:130px}.logo-img{width:82px;height:82px}}
</style>
</head>
<body>
<div class="background">
<div class="bg-base"></div><div class="bg-glow"></div><div class="bg-glow-soft"></div>
<div class="hairlines"></div><div class="grain"></div><div class="vignette"></div>
</div>
<div id="app">
<nav class="navbar reveal" style="animation-delay:.05s">
<div class="brand">
<img class="brand-mark" src="data:image/png;base64,${LOGO_B64}" alt="LX logo">
<div class="brand-name">Lynx <b>Browser</b></div>
</div>
<div class="nav-right">
<div class="pill clock" id="clock">--:--:--</div>
<div class="pill status"><span class="dot"></span>Navegação protegida</div>
</div>
</nav>
<main class="main">
<div class="logo-stage reveal" style="animation-delay:.15s">
<div class="logo-pedestal"></div>
<img class="logo-img" src="data:image/png;base64,${LOGO_B64}" alt="LX logo">
</div>
<h1 class="reveal" style="animation-delay:.22s">Bem-vindo ao <b>Lynx</b></h1>
<p class="subtitle reveal" style="animation-delay:.28s">Navegue rápido. Navegue do seu jeito.</p>
<div class="search-box reveal" style="animation-delay:.34s">
<div class="search-frame">
<div class="search-icon">⌕</div>
<input class="search" id="search" type="text" placeholder="Pesquise na web ou digite um endereço..." autocomplete="off" autofocus>
<div class="search-enter">ENTER</div>
</div>
</div>
<div class="shortcuts reveal" style="animation-delay:.4s">
<div class="shortcut" tabindex="0" onclick="abrir('https://www.crazygames.com/')"><span class="shortcut-icon">⌘</span>Crazy Games</div>
<div class="shortcut" tabindex="0" onclick="abrir('https://www.discord.com')"><span class="shortcut-icon">▶</span>Discord</div>
<div class="shortcut" tabindex="0" onclick="abrir('https://www.tiktok.com/')"><span class="shortcut-icon">▶</span>TikTok</div>
<div class="shortcut" tabindex="0" onclick="abrir('https://poki.com/')"><span class="shortcut-icon">⌘</span>Poki</div>
</div>
</main>
<div class="footer reveal" style="animation-delay:.46s">
<div class="footer-rule"></div>
<div>LYNX BROWSER <b>·</b> RÁPIDO · PRIVADO · DIRETO</div>
</div>
</div>
<script>
function atualizarRelogio() {
    const agora = new Date();
    const hora = agora.toLocaleTimeString("pt-BR", {
        timeZone: "America/Sao_Paulo",
        hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false
    });
    document.getElementById("clock").textContent = hora;
}
atualizarRelogio();
setInterval(atualizarRelogio, 1000);

const root = document.documentElement;
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

if (!reduceMotion) {
    window.addEventListener("mousemove", function (e) {
        const x = (e.clientX / window.innerWidth * 100).toFixed(2);
        const y = (e.clientY / window.innerHeight * 100).toFixed(2);
        root.style.setProperty("--mx", x + "%");
        root.style.setProperty("--my", y + "%");
    });
}

function pesquisar() {
    const input = document.getElementById("search");
    const texto = input.value.trim();
    if (!texto) { return; }
    let destino;
    if (texto.startsWith("http://") || texto.startsWith("https://")) {
        destino = texto;
    } else if (texto.includes(".") && !texto.includes(" ")) {
        destino = "https://" + texto;
    } else {
        destino = "https://duckduckgo.com/?q=" + encodeURIComponent(texto);
    }
    window.location.href = destino;
}

document.getElementById("search").addEventListener("keydown", function (event) {
    if (event.key === "Enter") { pesquisar(); }
});

function abrir(url) {
    window.location.href = url;
}
</script>
</body>
</html>
HOME_EOF

echo "[3/6] Interface..."

# Gera home.html + home.js (scripts separados, pois extensões do Firefox
# bloqueiam JavaScript inline) e ativa SafeSearch do DuckDuckGo.
mkdir -p "$INSTALL/config/web"

python3 - "$TEMPLATE" "$LOGO" "$INSTALL/config/web" <<'PY'
import sys, re, base64

tpl, logo, out = sys.argv[1:4]
html = open(tpl, encoding="utf-8").read()
b64 = base64.b64encode(open(logo, "rb").read()).decode()
html = html.replace("${LOGO_B64}", b64)

m = re.search(r"<script>(.*?)</script>", html, re.S)
if not m:
    sys.exit("ERRO: <script> não encontrado no template")

js = m.group(1)
html = html[:m.start()] + '<script src="home.js"></script>' + html[m.end():]
html = re.sub(r"onclick=\"abrir\('([^']+)'\)\"", r'data-url="\1"', html)

js = js.replace("https://duckduckgo.com/?q=", "https://duckduckgo.com/?kp=1&q=")
js += """
document.querySelectorAll("[data-url]").forEach(function (el) {
    el.addEventListener("click", function () { abrir(el.dataset.url); });
    el.addEventListener("keydown", function (e) {
        if (e.key === "Enter") { abrir(el.dataset.url); }
    });
});
"""

open(out + "/index.html", "w", encoding="utf-8").write(html)
open(out + "/home.js", "w", encoding="utf-8").write(js)
PY


echo "[4/6] Configurações e listas de bloqueio..."

echo "$FIREFOX_URL" > "$INSTALL/config/firefox-url.txt"

cat > "$INSTALL/config/lynx.conf" <<'EOF'
# Filtro de DNS adulto (CleanBrowsing) - camada extra contra porno.
# 0 = desativado, 1 = ativado (reabra o Lynx depois de mudar)
DNS_FILTER=0
EOF

# --- SUA lista: um site ou link por linha -------------------
cat > "$INSTALL/config/blocked-sites.txt" <<'EOF'
# Coloque aqui os sites que você quer bloquear, um por linha.
# Aceita domínio (exemplo.com) ou link completo (https://exemplo.com/pagina).
# Linhas com # são comentários.
# Depois de editar, basta reabrir o Lynx.

EOF

# --- Lista embutida (pornô / gore / NSFW) -------------------
cat > "$INSTALL/config/blocklist-default.txt" <<'EOF'
# Pornô e NSFW
pornhub.com
xvideos.com
xnxx.com
xhamster.com
redtube.com
youporn.com
spankbang.com
eporner.com
tube8.com
tnaflix.com
beeg.com
porn.com
pornone.com
porntrex.com
hqporner.com
motherless.com
erome.com
fapello.com
thothub.to
onlyfans.com
fansly.com
chaturbate.com
stripchat.com
livejasmin.com
cam4.com
bongacams.com
myfreecams.com
brazzers.com
realitykings.com
naughtyamerica.com
bangbros.com
rule34.xxx
rule34.paheal.net
e621.net
gelbooru.com
danbooru.donmai.us
nhentai.net
hentaihaven.xxx
hanime.tv
hentai2read.com
luscious.net
literotica.com
sex.com
xtube.com
4tube.com
txxx.com
hclips.com
# Gore / violência real
bestgore.com
kaotic.com
theync.com
crazyshit.com
goregrish.com
documentingreality.com
liveleak.com
watchpeopledie.tv
heavy-r.com
ogrish.com
EOF

echo "[5/6] Scripts..."

# ----------------------------------------------------------
# lynx (launcher principal, sempre destacado do terminal)
# ----------------------------------------------------------
cat > "$INSTALL/lynx" <<'LYNX_EOF'
#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
FIREFOX="$BASE/browser/firefox/firefox"
PROFILE="$BASE/.profile"
CONF="$BASE/config/lynx.conf"

[ -x "$FIREFOX" ] || { echo "ERRO: Firefox não encontrado."; exit 1; }

mkdir -p "$PROFILE"

DNS_FILTER=0
# shellcheck disable=SC1090
[ -f "$CONF" ] && source "$CONF"

# ---- Modo especial: configuração manual da 1VPN ----------
if [ "${1:-}" = "--setup-1vpn" ]; then
    CMD='chrome.storage.local.set({ currentLocation: "lax", isConnected: true });'
    echo "Em about:debugging clique em Inspecionar na 1VPN e cole no Console:"
    echo "  $CMD"
    if command -v wl-copy >/dev/null 2>&1; then printf '%s' "$CMD" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then printf '%s' "$CMD" | xclip -selection clipboard; fi
    exec "$FIREFOX" --no-remote --profile "$PROFILE" "about:debugging#/runtime/this-firefox"
fi

# ---- user.js ---------------------------------------------
cat > "$PROFILE/user.js" <<'USERJS_EOF'
user_pref("security.cert_pinning.enforcement_level", 2);
user_pref("security.enterprise_roots.enabled", false);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.pbmode.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.partition.network_state", true);
user_pref("media.peerconnection.enabled", false);
user_pref("dom.battery.enabled", false);
user_pref("browser.send_pings", false);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("browser.startup.firstrunSkipsHomepage", true);
user_pref("browser.disableResetPrompt", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.warnOnQuit", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
user_pref("startup.homepage_override_url", "");
user_pref("browser.startup.upgradeDialog.enabled", false);
user_pref("xpinstall.signatures.required", false);
user_pref("extensions.webextensions.ExtensionStorageIDB.enabled", false);
USERJS_EOF

if [ "$DNS_FILTER" = "1" ]; then
    cat >> "$PROFILE/user.js" <<'USERJS_EOF'
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://doh.cleanbrowsing.org/doh/adult-filter/");
user_pref("network.trr.bootstrapAddress", "185.228.168.10");
USERJS_EOF
else
    cat >> "$PROFILE/user.js" <<'USERJS_EOF'
user_pref("network.trr.mode", 5);
user_pref("network.trr.uri", "");
user_pref("network.trr.bootstrapAddress", "");
USERJS_EOF
fi

cat >> "$PROFILE/user.js" <<'USERJS_EOF'
user_pref("network.proxy.type", 0);
user_pref("network.proxy.no_proxies_on", "localhost, 127.0.0.1");
USERJS_EOF

# ---- 1VPN: tenta deixar pré-configurada nos EUA (experimental) ----
SEED_DIR="$PROFILE/browser-extension-data/1vpn@example.com"
if [ ! -f "$SEED_DIR/storage.js" ]; then
    mkdir -p "$SEED_DIR"
    printf '{"currentLocation":"lax","isConnected":true}' > "$SEED_DIR/storage.js"
fi

# ---- Bloqueio de sites -----------------------------------
to_pattern() {
    local s="$1"
    s="${s%%#*}"
    s="$(printf '%s' "$s" | tr -d '"\\\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$s" ] && return 0
    s="${s#http://}"; s="${s#https://}"; s="${s#www.}"
    if [[ "$s" == */* ]] && [ -n "${s#*/}" ]; then
        printf '%s' "*://*.${s}*"
    else
        s="${s%/}"
        printf '%s' "*://*.${s}/*"
    fi
}

BLOCK_JSON=""
while IFS= read -r line || [ -n "$line" ]; do
    p="$(to_pattern "$line")"
    [ -n "$p" ] && BLOCK_JSON+="\"$p\","
done < <(cat "$BASE/config/blocklist-default.txt" "$BASE/config/blocked-sites.txt" 2>/dev/null)

# Palavras-chave no caminho do link (pega sites novos que não estão na lista)
for kw in porn hentai nsfw; do
    BLOCK_JSON+="\"*://*/*${kw}*\","
done
BLOCK_JSON="${BLOCK_JSON%,}"

# ---- Pagina inicial e nova aba (sem extensao) ------------
# A pagina abre como http://127.0.0.1:PORTA/, entao o caminho dos
# arquivos nao aparece na barra de enderecos.
LYNX_PORT=47321
HOME_URL="http://127.0.0.1:$LYNX_PORT/"
START_URL="about:blank"

if command -v python3 >/dev/null 2>&1; then
    nohup setsid python3 "$BASE/server.py" "$LYNX_PORT" >/dev/null 2>&1 </dev/null &
    for _ in $(seq 1 30); do
        if (exec 3<>"/dev/tcp/127.0.0.1/$LYNX_PORT") 2>/dev/null; then
            START_URL="$HOME_URL"
            break
        fi
        sleep 0.1
    done
fi

if [ "$START_URL" = "$HOME_URL" ]; then
    printf 'user_pref("browser.startup.homepage", "%s");\n' "$HOME_URL" >> "$PROFILE/user.js"
    printf 'user_pref("browser.startup.page", 1);\n' >> "$PROFILE/user.js"
fi

# AutoConfig: aponta a Nova Aba para a mesma pagina
FF_DIR="$BASE/browser/firefox"
mkdir -p "$FF_DIR/defaults/pref"

cat > "$FF_DIR/defaults/pref/autoconfig.js" <<'AC_EOF'
pref("general.config.filename", "lynx.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
AC_EOF

cat > "$FF_DIR/lynx.cfg" <<CFG_EOF
// Lynx Browser
try {
  var lynxUrl = "$HOME_URL";
  Services.obs.addObserver({
    observe: function () {
      try {
        var svc = Components.classes["@mozilla.org/browser/aboutnewtab-service;1"]
          .getService(Components.interfaces.nsIAboutNewTabService);
        svc.newTabURL = lynxUrl;
      } catch (e) {
        try {
          var m = ChromeUtils.importESModule("resource:///modules/AboutNewTab.sys.mjs");
          m.AboutNewTab.newTabURL = lynxUrl;
        } catch (e2) {}
      }
    }
  }, "final-ui-startup", false);
} catch (e) {}
CFG_EOF

# ---- policies.json ---------------------------------------
POLICY_DIR="$BASE/browser/firefox/distribution"
mkdir -p "$POLICY_DIR"


cat > "$POLICY_DIR/policies.json" <<POLICY_EOF
{
    "policies": {
        "WebsiteFilter": {
            "Block": [ $BLOCK_JSON ]
        },
        "BlockAboutConfig": true,
        "BlockAboutProfiles": true,
        "BlockAboutSupport": true,
        "ExtensionSettings": {
            "1vpn@example.com": {
                "installation_mode": "force_installed",
                "install_url": "https://addons.mozilla.org/firefox/downloads/latest/1vpn/latest.xpi",
                "default_area": "navbar",
                "private_browsing": true
            }
        }
    }
}
POLICY_EOF

mkdir -p "$PROFILE/chrome"
cat > "$PROFILE/chrome/userChrome.css" <<'CSS_EOF'
#aboutHeaderLearnMore { display: none !important; }
CSS_EOF

# ---- Abre o navegador totalmente solto do terminal -------
nohup setsid "$FIREFOX" \
    --no-remote \
    --class LynxBrowser \
    --profile "$PROFILE" \
    "$START_URL" \
    "$@" >/dev/null 2>&1 </dev/null &
disown || true
touch "$BASE/.started"
exit 0
LYNX_EOF
chmod +x "$INSTALL/lynx"

# ----------------------------------------------------------
# start.sh (se o Firefox não existe, abre o instalador gráfico)
# ----------------------------------------------------------
cat > "$INSTALL/start.sh" <<'START_EOF'
#!/usr/bin/env bash
BASE="$(cd "$(dirname "$0")" && pwd)"

if [ -x "$BASE/browser/firefox/firefox" ]; then
    exec "$BASE/lynx" "$@"
fi

if ! command -v python3 >/dev/null 2>&1; then
    command -v notify-send >/dev/null 2>&1 && \
        notify-send "Lynx Browser" "python3 é necessário para a primeira instalação."
    exit 1
fi

nohup setsid python3 "$BASE/setup.py" >/dev/null 2>&1 </dev/null &
disown || true
exit 0
START_EOF
chmod +x "$INSTALL/start.sh"

# ----------------------------------------------------------
# setup.py (página de progresso: baixa, extrai e abre o Lynx)
# ----------------------------------------------------------
cat > "$INSTALL/setup.py" <<'PY_EOF'
#!/usr/bin/env python3
import fcntl, http.server, json, os, shutil, subprocess, tarfile
import threading, time, urllib.request, webbrowser

BASE = os.path.dirname(os.path.abspath(__file__))
CFG = os.path.join(BASE, "config")

state = {"stage": "starting", "overall": 0, "percent": 0, "done": 0,
         "total": 0, "speed": 0, "eta": None, "msg": "Preparando..."}

PAGE = r"""<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8">
<title>Lynx Browser - Instalando</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{--black:#050506;--panel:#0b0c0f;--hi:#121319;--line:rgba(255,255,255,.09);
--blue:#1d4fea;--bright:#3f6dff;--ice:#eef1f8;--slate:#838a9a;--dim:#484e5c}
html,body{height:100%}
body{background:radial-gradient(ellipse 60% 50% at 50% 0%,rgba(29,79,234,.25),transparent 60%),var(--black);
color:var(--ice);font-family:Inter,Arial,sans-serif;display:flex;align-items:center;justify-content:center}
.card{width:min(520px,92vw);background:linear-gradient(160deg,var(--hi),var(--panel) 70%);
border:1px solid var(--line);padding:38px 34px;
clip-path:polygon(24px 0,100% 0,100% calc(100% - 24px),calc(100% - 24px) 100%,0 100%,0 24px)}
.head{display:flex;align-items:center;gap:14px;margin-bottom:26px}
.head img{width:52px;height:52px;object-fit:contain;filter:drop-shadow(0 0 14px rgba(29,79,234,.6))}
h1{font-size:22px;letter-spacing:-.5px}h1 b{color:var(--bright)}
.sub{color:var(--slate);font-size:13px;margin-top:3px}
.bar{height:10px;background:#15171e;border:1px solid var(--line);overflow:hidden}
.fill{height:100%;width:0;background:linear-gradient(90deg,#081b66,var(--blue),var(--bright));
transition:width .35s ease;box-shadow:0 0 14px rgba(63,109,255,.6)}
.pct{display:flex;justify-content:space-between;margin:12px 0 22px;font-family:monospace;font-size:12px;color:var(--slate)}
.pct b{font-size:30px;color:var(--ice);font-family:Arial,sans-serif;letter-spacing:-1px}
.steps{list-style:none;display:grid;gap:10px;margin-bottom:22px}
.steps li{display:flex;align-items:center;gap:10px;font-size:13px;color:var(--dim)}
.steps li i{width:8px;height:8px;border-radius:50%;background:var(--dim)}
.steps li.on{color:var(--ice)}.steps li.on i{background:var(--bright);box-shadow:0 0 8px var(--bright);animation:b 1.4s infinite}
.steps li.ok{color:var(--slate)}.steps li.ok i{background:#3ddc84}
@keyframes b{50%{opacity:.3}}
.info{font-family:monospace;font-size:11px;color:var(--slate);border-top:1px solid var(--line);padding-top:14px;min-height:30px}
.err{color:#ff7b7b}
</style></head><body>
<div class="card">
<div class="head"><img src="/logo.png" alt=""><div><h1>Instalando o <b>Lynx</b></h1><div class="sub" id="msg">Preparando...</div></div></div>
<div class="bar"><div class="fill" id="fill"></div></div>
<div class="pct"><b id="pct">0%</b><span id="eta"></span></div>
<ul class="steps" id="steps">
<li data-s="download"><i></i>Baixando o motor do navegador</li>
<li data-s="extract"><i></i>Extraindo arquivos</li>
<li data-s="config"><i></i>Aplicando configurações</li>
<li data-s="launch"><i></i>Abrindo o Lynx</li>
</ul>
<div class="info" id="info"></div>
</div>
<script>
var order=["download","extract","config","launch"];
function mb(n){return (n/1048576).toFixed(1)+" MB"}
function tm(s){if(s==null)return"";s=Math.round(s);return s>=60?Math.floor(s/60)+"min "+(s%60)+"s":s+"s"}
function tick(){
 fetch("/progress",{cache:"no-store"}).then(function(r){return r.json()}).then(function(s){
  document.getElementById("fill").style.width=s.overall+"%";
  document.getElementById("pct").textContent=Math.floor(s.overall)+"%";
  document.getElementById("msg").textContent=s.msg;
  document.getElementById("eta").textContent=(s.stage=="download"&&s.eta!=null)?"faltam ~"+tm(s.eta):"";
  var idx=order.indexOf(s.stage);if(s.stage=="done")idx=99;
  document.querySelectorAll("#steps li").forEach(function(li){
   var i=order.indexOf(li.dataset.s);
   li.className=i<idx?"ok":(i==idx?"on":"");
  });
  if(s.stage=="done"&&!window._c){window._c=1;setTimeout(function(){window.close()},1200);}
  var info=document.getElementById("info");
  if(s.stage=="error"){info.className="info err";info.textContent=s.msg;}
  else if(s.stage=="download"&&s.total){info.textContent=mb(s.done)+" / "+mb(s.total)+"  ·  "+mb(s.speed)+"/s";}
  else{info.textContent="";}
 }).catch(function(){});
}
setInterval(tick,400);tick();
</script></body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def do_GET(self):
        if self.path.startswith("/progress"):
            body, ctype = json.dumps(state).encode(), "application/json"
        elif self.path.startswith("/logo.png"):
            with open(os.path.join(CFG, "icons", "lynx-logo.png"), "rb") as f:
                body, ctype = f.read(), "image/png"
        else:
            body, ctype = PAGE.encode("utf-8"), "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)


def open_window(url):
    """Abre a pagina de progresso e devolve a pasta de perfil usada,
    que serve de marcador para fechar a janela depois."""
    quiet = dict(stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                 stderr=subprocess.DEVNULL, start_new_session=True)
    for name in ("google-chrome", "google-chrome-stable", "chromium",
                 "chromium-browser", "brave-browser", "microsoft-edge"):
        path = shutil.which(name)
        if path:
            prof = "/tmp/lynx-setup-%d" % os.getpid()
            subprocess.Popen(
                [path, "--app=" + url, "--window-size=620,560",
                 "--user-data-dir=" + prof, "--no-first-run",
                 "--no-default-browser-check"], **quiet)
            return prof
    path = shutil.which("firefox")
    if path:
        # Perfil proprio e visivel (snap nao enxerga pastas ocultas); apagado no fim.
        prof = os.path.join(os.path.expanduser("~"), "lynx-setup-%d" % os.getpid())
        os.makedirs(prof, exist_ok=True)
        with open(os.path.join(prof, "user.js"), "w") as f:
            f.write('user_pref("browser.shell.checkDefaultBrowser", false);\n'
                    'user_pref("browser.startup.homepage_welcome_url", "");\n'
                    'user_pref("datareporting.policy.dataSubmissionEnabled", false);\n'
                    'user_pref("browser.aboutwelcome.enabled", false);\n')
        subprocess.Popen([path, "--no-remote", "--profile", prof,
                          "--new-window", url], **quiet)
        return prof
    webbrowser.open(url)
    return None


def close_window(marker):
    """Fecha a janela de progresso (qualquer processo que use o perfil marcador)."""
    if not marker:
        return
    me = os.getpid()
    for pid in os.listdir("/proc"):
        if not pid.isdigit() or int(pid) == me:
            continue
        try:
            with open("/proc/%s/cmdline" % pid, "rb") as f:
                cmd = f.read().decode(errors="ignore")
        except OSError:
            continue
        if marker in cmd:
            try:
                os.kill(int(pid), 15)
            except OSError:
                pass
    time.sleep(1.5)
    shutil.rmtree(marker, ignore_errors=True)


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 LynxSetup"})
    with urllib.request.urlopen(req, timeout=30) as r, open(dest, "wb") as f:
        total = int(r.headers.get("Content-Length") or 0)
        state.update(stage="download", total=total, msg="Baixando o Firefox...")
        done, t0, last = 0, time.time(), 0
        while True:
            chunk = r.read(262144)
            if not chunk:
                break
            f.write(chunk)
            done += len(chunk)
            now = time.time()
            if now - last > 0.25:
                speed = done / max(now - t0, 0.001)
                pct = (done / total * 100) if total else 0
                state.update(done=done, speed=speed, percent=pct,
                             overall=pct * 0.70,
                             eta=((total - done) / speed) if total and speed else None)
                last = now
    state.update(done=done, percent=100, overall=70)


def extract(tar_path, tmp):
    size = os.path.getsize(tar_path)
    state.update(stage="extract", msg="Extraindo arquivos...", eta=None)
    kw = {"filter": "tar"} if hasattr(tarfile, "tar_filter") else {}
    with open(tar_path, "rb") as raw:
        with tarfile.open(fileobj=raw, mode="r|xz") as tf:
            for m in tf:
                tf.extract(m, tmp, **kw)
                state["overall"] = 70 + 25 * (raw.tell() / size)


def main():
    lock = open(os.path.join(BASE, ".setup.lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return

    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    win = open_window("http://127.0.0.1:%d/" % srv.server_address[1])
    open(os.path.join(BASE, ".started"), "w").close()

    tar_path = os.path.join(BASE, "firefox.tar.xz")
    tmp = os.path.join(BASE, "_extract")
    try:
        url = open(os.path.join(CFG, "firefox-url.txt")).read().strip()
        download(url, tar_path)

        shutil.rmtree(tmp, ignore_errors=True)
        os.makedirs(tmp)
        extract(tar_path, tmp)

        state.update(stage="config", overall=96, msg="Aplicando configurações...")
        dest = os.path.join(BASE, "browser", "firefox")
        shutil.rmtree(dest, ignore_errors=True)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        os.rename(os.path.join(tmp, "firefox"), dest)
        shutil.rmtree(tmp, ignore_errors=True)
        os.remove(tar_path)

        state.update(stage="launch", overall=99, msg="Abrindo o Lynx...")
        subprocess.Popen([os.path.join(BASE, "lynx")],
                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL, start_new_session=True)
        time.sleep(3)
        state.update(stage="done", overall=100, msg="Pronto! Abrindo o Lynx...")
        time.sleep(2)
        close_window(win)
    except Exception as e:
        state.update(stage="error", msg="Erro: %s" % e)
        time.sleep(90)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
        os._exit(0)


main()
PY_EOF
chmod +x "$INSTALL/setup.py"

# ----------------------------------------------------------
# server.py (serve só a tela inicial em 127.0.0.1; some quando o Lynx fecha)
# ----------------------------------------------------------
cat > "$INSTALL/server.py" <<'SRV_EOF'
#!/usr/bin/env python3
import http.server, os, sys, threading, time

BASE = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(BASE, "config", "web")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 47321
MARK = os.path.join(BASE, ".profile")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=WEB, **k)

    def log_message(self, *a):
        pass

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def lynx_running():
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            with open("/proc/%s/cmdline" % pid, "rb") as f:
                cmd = f.read().decode(errors="ignore")
        except OSError:
            continue
        if MARK in cmd:
            return True
    return False


try:
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
except OSError:
    sys.exit(0)  # ja existe um servidor do Lynx rodando

threading.Thread(target=srv.serve_forever, daemon=True).start()

seen, gone = False, None
while True:
    time.sleep(3)
    if lynx_running():
        seen, gone = True, None
    else:
        gone = gone or time.time()
        if time.time() - gone > (15 if seen else 90):
            break
os._exit(0)
SRV_EOF
chmod +x "$INSTALL/server.py"

# ----------------------------------------------------------
# sites  (gerencia a SUA lista de sites bloqueados)
# ----------------------------------------------------------
cat > "$INSTALL/sites" <<'SITES_EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
LIST="$BASE/config/blocked-sites.txt"

case "${1:-list}" in
    add)    [ -n "${2:-}" ] || { echo "Uso: ./sites add site.com"; exit 1; }
            echo "$2" >> "$LIST"; echo "Adicionado: $2 (reabra o Lynx)" ;;
    remove) [ -n "${2:-}" ] || { echo "Uso: ./sites remove site.com"; exit 1; }
            grep -vxF "$2" "$LIST" > "$LIST.tmp" || true; mv "$LIST.tmp" "$LIST"
            echo "Removido: $2 (reabra o Lynx)" ;;
    list)   grep -v '^[[:space:]]*\(#\|$\)' "$LIST" || echo "(lista vazia)" ;;
    edit)   ${EDITOR:-nano} "$LIST" ;;
    *)      echo "Uso: ./sites add|remove|list|edit [site]"; exit 1 ;;
esac
SITES_EOF
chmod +x "$INSTALL/sites"

# ----------------------------------------------------------
# test.sh
# ----------------------------------------------------------
cat > "$INSTALL/test.sh" <<'TEST_EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$(cd "$(dirname "$0")" && pwd)"
P="/tmp/lynx-clean-profile-$$"
mkdir -p "$P"
cat > "$P/user.js" <<'EOF'
user_pref("network.trr.mode", 5);
user_pref("network.trr.uri", "");
user_pref("network.proxy.type", 0);
EOF
"$BASE/browser/firefox/firefox" --no-remote --profile "$P" "https://example.com"
rm -rf "$P"
TEST_EOF
chmod +x "$INSTALL/test.sh"

echo "[6/6] Finalizando..."

# Sem atalhos: remove os que versões anteriores deste script criaram.
DESK_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
rm -f "$HOME/.local/share/applications/lynx-browser.desktop" \
      "$DESK_DIR/Lynx Browser.desktop" \
      "$HOME/.local/bin/lynx-browser" \
      "$HOME/.local/share/icons/hicolor/256x256/apps/lynx-browser.png"
command -v update-desktop-database >/dev/null 2>&1 && \
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Pronto. Abrindo o Lynx..."
launch_lynx
exit 0
