#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
#                    LYNX BROWSER
#                 BUILD SCRIPT - LINUX
# ==========================================================

APP="LynxBrowser"
ARCH="x86_64"

ROOT="$PWD"
WORK="$ROOT/lynx-build"
APP_DIR="$WORK/$APP"

OUT="$ROOT/${APP}-Linux-${ARCH}.tar.gz"
LOCAL_INSTALL="$ROOT/$APP"

LOGO="$ROOT/lynx-logo.png"

FIREFOX_URL="https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=pt-BR"

# ==========================================================
# CABEÇALHO
# ==========================================================

echo
echo "========================================="
echo "          LYNX BROWSER - BUILD"
echo "========================================="
echo

# ==========================================================
# DEPENDÊNCIAS
# ==========================================================

REQUIRED_COMMANDS=(
    curl
    tar
    base64
    zip
    sed
    grep
    find
    readlink
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do

    if ! command -v "$cmd" >/dev/null 2>&1; then

        echo "ERRO: comando necessário não encontrado:"
        echo "  $cmd"
        echo

        exit 1
    fi

done

# ==========================================================
# LIMPEZA
# ==========================================================

echo "[1/8] Preparando diretórios..."

rm -rf "$WORK"
rm -rf "$LOCAL_INSTALL"

mkdir -p \
    "$APP_DIR/browser" \
    "$APP_DIR/profile" \
    "$APP_DIR/config" \
    "$APP_DIR/config/icons"

# ==========================================================
# LOGO
# ==========================================================

echo "[2/8] Preparando logo..."

if [ ! -f "$LOGO" ]; then

    echo "Logo não encontrada."
    echo "Baixando..."

    curl -fL \
        "$LOGO_URL" \
        -o "$LOGO"

fi

if [ ! -s "$LOGO" ]; then

    echo "ERRO: logo inválida ou download falhou."
    exit 1

fi

cp \
    "$LOGO" \
    "$APP_DIR/config/icons/lynx-logo.png"

LOGO_B64="$(base64 -w 0 "$LOGO")"

# ==========================================================
# HOME.HTML
# ==========================================================

echo "[3/8] Criando interface do Lynx..."

cat > "$APP_DIR/config/home.html" <<HOME_EOF
<!DOCTYPE html>

<html lang="pt-BR">

<head>

<meta charset="UTF-8">

<meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
>

<title>Lynx Browser</title>

<link
    rel="preconnect"
    href="https://fonts.googleapis.com"
>

<link
    rel="preconnect"
    href="https://fonts.gstatic.com"
    crossorigin
>

<link
    href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap"
    rel="stylesheet"
>

<style>

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

:root {

    --black: #050506;
    --panel: #0b0c0f;
    --panel-hi: #121319;

    --line: rgba(255,255,255,.09);
    --line-soft: rgba(255,255,255,.05);

    --blue: #1d4fea;
    --blue-bright: #3f6dff;
    --blue-deep: #081b66;

    --ice: #eef1f8;
    --slate: #838a9a;
    --slate-dim: #484e5c;

    --font-display: 'Sora', Arial, sans-serif;
    --font-body: 'Inter', Arial, sans-serif;
    --font-mono: 'JetBrains Mono', monospace;

    --mx: 50%;
    --my: 40%;
}

html,
body {

    width: 100%;
    height: 100%;

    overflow: hidden;
}

body {

    background: var(--black);
    color: var(--ice);

    font-family: var(--font-body);
}

/* ==========================================================
   BACKGROUND
   ========================================================== */

.background {

    position: fixed;
    inset: 0;

    overflow: hidden;

    pointer-events: none;

    z-index: 0;
}

.bg-base {

    position: absolute;
    inset: 0;

    background: var(--black);
}

.bg-glow {

    position: absolute;
    inset: 0;

    background:
        radial-gradient(
            ellipse 60% 50% at 50% 12%,
            rgba(29,79,234,.22),
            transparent 60%
        );
}

.bg-glow-soft {

    position: absolute;
    inset: 0;

    background:
        radial-gradient(
            circle 480px at var(--mx) var(--my),
            rgba(63,109,255,.06),
            transparent 70%
        );

    transition:
        background .08s linear;
}

.hairlines {

    position: absolute;
    inset: 0;

    opacity: .5;

    background-image:
        repeating-linear-gradient(
            115deg,
            rgba(255,255,255,.025) 0px,
            rgba(255,255,255,.025) 1px,
            transparent 1px,
            transparent 84px
        );
}

.grain {

    position: absolute;
    inset: 0;

    opacity: .05;

    mix-blend-mode: overlay;

    background-image:
        url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='2' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

.vignette {

    position: absolute;
    inset: 0;

    background:
        radial-gradient(
            ellipse 90% 80% at 50% 40%,
            transparent 55%,
            rgba(2,2,3,.6) 100%
        );

    box-shadow:
        inset 0 0 160px rgba(0,0,0,.6);
}

/* ==========================================================
   APP
   ========================================================== */

#app {

    position: relative;

    z-index: 2;

    width: 100%;
    height: 100%;

    display: flex;
    flex-direction: column;
}

.reveal {

    opacity: 0;

    transform: translateY(14px);

    animation:
        reveal .7s cubic-bezier(.2,.7,.2,1)
        forwards;
}

@keyframes reveal {

    to {

        opacity: 1;
        transform: translateY(0);
    }
}

/* ==========================================================
   NAVBAR
   ========================================================== */

.navbar {

    height: 78px;

    flex-shrink: 0;

    display: flex;

    align-items: center;
    justify-content: space-between;

    padding: 0 40px;

    border-bottom:
        1px solid var(--line-soft);
}

.brand {

    display: flex;

    align-items: center;

    gap: 12px;
}

.brand-mark {

    width: 34px;
    height: 34px;

    object-fit: contain;

    filter:
        drop-shadow(
            0 0 10px
            rgba(29,79,234,.5)
        );
}

.brand-name {

    font-family: var(--font-display);

    font-size: 18px;

    font-weight: 700;

    letter-spacing: -.3px;
}

.brand-name b {

    color: var(--blue-bright);

    font-weight: 800;
}

.nav-right {

    display: flex;

    align-items: center;

    gap: 10px;
}

.pill {

    display: flex;

    align-items: center;

    gap: 8px;

    padding: 8px 14px;

    border:
        1px solid var(--line);

    background: var(--panel);

    font-family: var(--font-mono);

    font-size: 11px;

    letter-spacing: .6px;

    color: var(--slate);

    clip-path:
        polygon(
            0 0,
            100% 0,
            100% 100%,
            10px 100%,
            0 calc(100% - 10px)
        );
}

.pill.status {

    color: #8fb4ff;
}

.dot {

    width: 6px;
    height: 6px;

    border-radius: 50%;

    background: var(--blue-bright);

    box-shadow:
        0 0 8px var(--blue-bright);

    animation:
        blink 2.4s ease-in-out infinite;
}

@keyframes blink {

    0%,
    100% {
        opacity: 1;
    }

    50% {
        opacity: .35;
    }
}

/* ==========================================================
   MAIN
   ========================================================== */

.main {

    flex: 1;

    display: flex;

    flex-direction: column;

    align-items: center;
    justify-content: center;

    padding-bottom: 56px;

    position: relative;
}

/* ==========================================================
   LOGO
   ========================================================== */

.logo-stage {

    position: relative;

    width: 168px;
    height: 168px;

    display: flex;

    align-items: center;
    justify-content: center;

    margin-bottom: 18px;
}

.logo-pedestal {

    position: absolute;

    inset: 0;

    background:
        linear-gradient(
            160deg,
            var(--panel-hi),
            var(--panel) 70%
        );

    border:
        1px solid var(--line);

    clip-path:
        polygon(
            22px 0,
            100% 0,
            100% calc(100% - 22px),
            calc(100% - 22px) 100%,
            0 100%,
            0 22px
        );

    box-shadow:
        0 30px 70px rgba(0,0,0,.55),
        inset 0 1px rgba(255,255,255,.05);

    overflow: hidden;
}

.logo-pedestal::after {

    content: "";

    position: absolute;

    inset: 0;

    background:
        linear-gradient(
            115deg,
            transparent 40%,
            rgba(63,109,255,.25) 50%,
            transparent 60%
        );

    background-size: 250% 250%;

    animation:
        sheen 5s ease-in-out infinite;

    mix-blend-mode: screen;
}

@keyframes sheen {

    0%,
    100% {
        background-position: 130% -30%;
    }

    50% {
        background-position: -30% 130%;
    }
}

.logo-img {

    position: relative;

    width: 104px;
    height: 104px;

    object-fit: contain;

    filter:
        drop-shadow(
            0 8px 26px
            rgba(29,79,234,.5)
        );

    animation:
        logoHover 6s ease-in-out infinite;
}

@keyframes logoHover {

    0%,
    100% {
        transform: translateY(0);
    }

    50% {
        transform: translateY(-6px);
    }
}

/* ==========================================================
   TITLE
   ========================================================== */

h1 {

    font-family: var(--font-display);

    font-size: 42px;

    font-weight: 700;

    letter-spacing: -1.5px;

    text-align: center;
}

h1 b {

    color: var(--blue-bright);

    font-weight: 800;
}

.subtitle {

    color: var(--slate);

    margin-top: 10px;

    font-size: 15px;

    letter-spacing: .1px;
}

/* ==========================================================
   SEARCH
   ========================================================== */

.search-box {

    width: min(620px,86vw);

    margin-top: 34px;

    position: relative;
}

.search-frame {

    position: relative;

    background: var(--panel);

    border:
        1px solid var(--line);

    clip-path:
        polygon(
            0 0,
            calc(100% - 24px) 0,
            100% 24px,
            100% 100%,
            0 100%
        );

    transition:
        border-color .25s ease,
        box-shadow .25s ease;
}

.search-frame:focus-within {

    border-color:
        rgba(63,109,255,.55);

    box-shadow:
        0 0 0 3px rgba(29,79,234,.12),
        0 20px 50px rgba(0,0,0,.4);
}

.search-frame::before {

    content: "";

    position: absolute;

    top: 0;
    right: 0;

    width: 24px;
    height: 24px;

    background:
        linear-gradient(
            135deg,
            var(--blue-deep),
            var(--blue)
        );

    clip-path:
        polygon(
            100% 0,
            100% 100%,
            0 0
        );
}

.search {

    width: 100%;

    height: 60px;

    padding:
        0 60px 0 54px;

    border: none;

    outline: none;

    background: transparent;

    color: var(--ice);

    font-size: 15px;

    font-family: var(--font-body);
}

.search::placeholder {

    color: var(--slate-dim);
}

.search-icon {

    position: absolute;

    left: 22px;

    top: 50%;

    transform:
        translateY(-50%);

    color: var(--blue-bright);

    font-size: 18px;

    pointer-events: none;
}

.search-enter {

    position: absolute;

    right: 16px;

    top: 50%;

    transform:
        translateY(-50%);

    padding: 7px 10px;

    background: var(--panel-hi);

    border:
        1px solid var(--line);

    color: var(--slate);

    font-family: var(--font-mono);

    font-size: 10px;

    letter-spacing: 1px;

    pointer-events: none;
}

/* ==========================================================
   SHORTCUTS
   ========================================================== */

.shortcuts {

    display: flex;

    gap: 10px;

    margin-top: 24px;

    flex-wrap: wrap;

    justify-content: center;

    width: min(620px,86vw);
}

.shortcut {

    display: flex;

    align-items: center;

    gap: 9px;

    min-width: 118px;

    padding: 13px 16px;

    background: var(--panel);

    border:
        1px solid var(--line);

    clip-path:
        polygon(
            0 0,
            100% 0,
            100% calc(100% - 12px),
            calc(100% - 12px) 100%,
            0 100%
        );

    color: var(--slate);

    font-size: 13px;

    font-family: var(--font-body);

    font-weight: 500;

    cursor: pointer;

    transition:
        border-color .2s ease,
        color .2s ease,
        transform .2s ease,
        background .2s ease;
}

.shortcut:hover,
.shortcut:focus-visible {

    color: var(--ice);

    border-color:
        rgba(63,109,255,.45);

    background: var(--panel-hi);

    transform: translateY(-2px);
}

.shortcut:focus-visible,
.search:focus-visible {

    outline:
        2px solid var(--blue-bright);

    outline-offset: 2px;
}

.shortcut-icon {

    font-size: 15px;

    color: var(--blue-bright);
}

/* ==========================================================
   FOOTER
   ========================================================== */

.footer {

    padding-bottom: 26px;

    display: flex;

    flex-direction: column;

    align-items: center;

    gap: 12px;

    color: var(--slate-dim);

    font-family: var(--font-mono);

    font-size: 10.5px;

    letter-spacing: .6px;
}

.footer-rule {

    width: 100%;

    max-width: 960px;

    height: 1px;

    background:
        linear-gradient(
            90deg,
            transparent,
            var(--line) 20%,
            var(--line) 80%,
            transparent
        );
}

.footer b {

    color: #5f7dcf;
}

/* ==========================================================
   MOBILE
   ========================================================== */

@media(max-width:600px) {

    .navbar {
        padding: 0 18px;
    }

    .pill.clock {
        display: none;
    }

    h1 {
        font-size: 32px;
    }

    .subtitle {
        text-align: center;
        padding: 0 24px;
    }

    .search-box {
        width: 90vw;
    }

    .shortcuts {
        width: 90vw;
    }

    .logo-stage {
        width: 130px;
        height: 130px;
    }

    .logo-img {
        width: 82px;
        height: 82px;
    }
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

<nav
    class="navbar reveal"
    style="animation-delay:.05s"
>

    <div class="brand">

        <img
            class="brand-mark"
            src="data:image/png;base64,${LOGO_B64}"
            alt="LX logo"
        >

        <div class="brand-name">
            Lynx <b>Browser</b>
        </div>

    </div>

    <div class="nav-right">

        <div
            class="pill clock"
            id="clock"
        >
            --:--:--
        </div>

        <div class="pill status">

            <span class="dot"></span>

            Navegação protegida

        </div>

    </div>

</nav>

<main class="main">

    <div
        class="logo-stage reveal"
        style="animation-delay:.15s"
    >

        <div class="logo-pedestal"></div>

        <img
            class="logo-img"
            src="data:image/png;base64,${LOGO_B64}"
            alt="LX logo"
        >

    </div>

    <h1
        class="reveal"
        style="animation-delay:.22s"
    >
        Bem-vindo ao <b>Lynx</b>
    </h1>

    <p
        class="subtitle reveal"
        style="animation-delay:.28s"
    >
        Navegue rápido. Navegue do seu jeito.
    </p>

    <div
        class="search-box reveal"
        style="animation-delay:.34s"
    >

        <div class="search-frame">

            <div class="search-icon">
                ⌕
            </div>

            <input
                class="search"
                id="search"
                type="text"
                placeholder="Pesquise na web ou digite um endereço..."
                autocomplete="off"
                autofocus
            >

            <div class="search-enter">
                ENTER
            </div>

        </div>

    </div>

    <div
        class="shortcuts reveal"
        style="animation-delay:.4s"
    >

        <div
            class="shortcut"
            tabindex="0"
            onclick="abrir('https://duckduckgo.com')"
        >

            <span class="shortcut-icon">
                🔎
            </span>

            DuckDuckGo

        </div>

        <div
            class="shortcut"
            tabindex="0"
            onclick="abrir('https://www.youtube.com')"
        >

            <span class="shortcut-icon">
                ▶
            </span>

            YouTube

        </div>

        <div
            class="shortcut"
            tabindex="0"
            onclick="abrir('https://www.tiktok.com/')"
        >

            <span class="shortcut-icon">
                ▶
            </span>

            TikTok

        </div>

        <div
            class="shortcut"
            tabindex="0"
            onclick="abrir('https://classroom.google.com/')"
        >

            <span class="shortcut-icon">
                ⌘
            </span>

            Classroom

        </div>

    </div>

</main>

<div
    class="footer reveal"
    style="animation-delay:.46s"
>

    <div class="footer-rule"></div>

    <div>
        LYNX BROWSER
        <b>·</b>
        RÁPIDO · PRIVADO · DIRETO
    </div>

</div>

</div>

<script>

/* ==========================================================
   RELÓGIO
   ========================================================== */

function atualizarRelogio() {

    const agora = new Date();

    const hora =
        agora.toLocaleTimeString(
            "pt-BR",
            {
                timeZone: "America/Sao_Paulo",
                hour: "2-digit",
                minute: "2-digit",
                second: "2-digit",
                hour12: false
            }
        );

    document.getElementById("clock")
        .textContent = hora;
}

atualizarRelogio();

setInterval(
    atualizarRelogio,
    1000
);


/* ==========================================================
   MOUSE
   ========================================================== */

const root =
    document.documentElement;

const reduceMotion =
    window.matchMedia(
        "(prefers-reduced-motion: reduce)"
    ).matches;

if (!reduceMotion) {

    window.addEventListener(
        "mousemove",
        function(e) {

            const x =
                (
                    e.clientX /
                    window.innerWidth *
                    100
                ).toFixed(2);

            const y =
                (
                    e.clientY /
                    window.innerHeight *
                    100
                ).toFixed(2);

            root.style.setProperty(
                "--mx",
                x + "%"
            );

            root.style.setProperty(
                "--my",
                y + "%"
            );
        }
    );
}


/* ==========================================================
   PESQUISA
   ========================================================== */

function pesquisar() {

    const input =
        document.getElementById("search");

    const texto =
        input.value.trim();

    if (!texto) {
        return;
    }

    let destino;

    if (
        texto.startsWith("http://") ||
        texto.startsWith("https://")
    ) {

        destino = texto;

    } else if (
        texto.includes(".") &&
        !texto.includes(" ")
    ) {

        destino =
            "https://" + texto;

    } else {

        destino =
            "https://duckduckgo.com/?q=" +
            encodeURIComponent(texto);
    }

    window.location.href =
        destino;
}


/* ==========================================================
   ENTER
   ========================================================== */

document
    .getElementById("search")
    .addEventListener(
        "keydown",
        function(event) {

            if (event.key === "Enter") {

                pesquisar();
            }
        }
    );


/* ==========================================================
   ATALHOS
   ========================================================== */

function abrir(url) {

    window.location.href = url;
}

</script>

</body>

</html>
HOME_EOF

# ==========================================================
# EXTENSÃO NEW TAB
# ==========================================================

echo "[4/8] Criando extensão New Tab..."

NEW_TAB="$APP_DIR/config/lynx-newtab"

mkdir -p "$NEW_TAB"

cat > "$NEW_TAB/manifest.json" <<'EOF'
{
    "manifest_version": 2,
    "name": "Lynx New Tab",
    "version": "1.0.0",
    "description": "Nova aba do Lynx Browser.",
    "applications": {
        "gecko": {
            "id": "lynx-newtab@lynxbrowser"
        }
    },
    "chrome_url_overrides": {
        "newtab": "home.html"
    }
}
EOF

cp \
    "$APP_DIR/config/home.html" \
    "$NEW_TAB/home.html"

XPI="$APP_DIR/config/lynx-newtab.xpi"

(
    cd "$NEW_TAB"
    zip -qr "$XPI" .
)

rm -rf "$NEW_TAB"

# ==========================================================
# FIREFOX
# ==========================================================

echo "[5/8] Baixando Firefox oficial..."

curl -fL \
    "$FIREFOX_URL" \
    -o "$WORK/firefox.tar.xz"

if [ ! -s "$WORK/firefox.tar.xz" ]; then

    echo "ERRO: download do Firefox falhou."
    exit 1

fi

echo "Extraindo..."

tar \
    -xJf "$WORK/firefox.tar.xz" \
    -C "$WORK"

if [ ! -d "$WORK/firefox" ]; then

    echo "ERRO: diretório Firefox não encontrado."
    exit 1

fi

mv \
    "$WORK/firefox" \
    "$APP_DIR/browser/firefox"

rm -f "$WORK/firefox.tar.xz"

FIREFOX="$APP_DIR/browser/firefox/firefox"

if [ ! -x "$FIREFOX" ]; then

    echo "ERRO: executável Firefox não encontrado."
    exit 1

fi

# ==========================================================
# CONFIGURAÇÃO VPN
# ==========================================================

echo "[6/8] Criando configuração de rede..."

cat > "$APP_DIR/config/vpn.conf" <<'EOF'
# ==========================================================
# LYNX BROWSER - SOCKS5
# ==========================================================

# 0 = desativado
# 1 = ativado

ENABLED=0

HOST=127.0.0.1
PORT=1080

USERNAME=
PASSWORD=
EOF

# ==========================================================
# EXECUTÁVEL
# ==========================================================

echo "[7/8] Criando executável Lynx..."

cat > "$APP_DIR/lynx" <<'LYNX_EOF'
#!/usr/bin/env bash

set -euo pipefail

# ==========================================================
# LYNX BROWSER
# ==========================================================

BASE="$(cd "$(dirname "$0")" && pwd)"

FIREFOX="$BASE/browser/firefox/firefox"

PROFILE="$BASE/profile"

HOME_PAGE="$BASE/config/home.html"

VPN_CONF="$BASE/config/vpn.conf"

# ==========================================================
# VERIFICAÇÕES
# ==========================================================

if [ ! -x "$FIREFOX" ]; then

    echo "ERRO: Firefox não encontrado:"
    echo "$FIREFOX"

    exit 1

fi

if [ ! -f "$HOME_PAGE" ]; then

    echo "ERRO: página inicial não encontrada."

    exit 1

fi

mkdir -p "$PROFILE"

# ==========================================================
# CONFIGURAÇÃO DO PROXY
# ==========================================================

PROXY_ENABLED=0
PROXY_HOST="127.0.0.1"
PROXY_PORT="1080"

if [ -f "$VPN_CONF" ]; then

    # shellcheck disable=SC1090
    source "$VPN_CONF"

    PROXY_ENABLED="${ENABLED:-0}"
    PROXY_HOST="${HOST:-127.0.0.1}"
    PROXY_PORT="${PORT:-1080}"

fi

# ==========================================================
# USER.JS
# ==========================================================

cat > "$PROFILE/user.js" <<'USERJS_EOF'
/* ==========================================================
   LYNX BROWSER
   ========================================================== */


/*
 * ==========================================================
 * DNS
 * ==========================================================
 *
 * DoH DESATIVADO.
 *
 * O Firefox utilizará o DNS normal do sistema.
 *
 * Isso elimina uma fonte comum de problemas TLS/DNS
 * durante o diagnóstico de PR_END_OF_FILE_ERROR.
 */

user_pref(
    "network.trr.mode",
    5
);

user_pref(
    "network.trr.uri",
    ""
);

user_pref(
    "network.trr.bootstrapAddress",
    ""
);


/*
 * ==========================================================
 * TLS
 * ==========================================================
 *
 * Configurações normais do Firefox.
 *
 * Não desabilitamos certificate pinning.
 */

user_pref(
    "security.cert_pinning.enforcement_level",
    2
);

user_pref(
    "security.enterprise_roots.enabled",
    false
);


/*
 * ==========================================================
 * PRIVACIDADE
 * ==========================================================
 */

user_pref(
    "privacy.trackingprotection.enabled",
    true
);

user_pref(
    "privacy.trackingprotection.pbmode.enabled",
    true
);

user_pref(
    "privacy.trackingprotection.socialtracking.enabled",
    true
);

user_pref(
    "privacy.partition.network_state",
    true
);

user_pref(
    "media.peerconnection.enabled",
    false
);

user_pref(
    "dom.battery.enabled",
    false
);

user_pref(
    "browser.send_pings",
    false
);


/*
 * ==========================================================
 * INTERFACE
 * ==========================================================
 */

user_pref(
    "toolkit.legacyUserProfileCustomizations.stylesheets",
    true
);

user_pref(
    "extensions.activeThemeID",
    "firefox-compact-dark@mozilla.org"
);


/*
 * ==========================================================
 * STARTUP
 * ==========================================================
 */

user_pref(
    "browser.startup.firstrunSkipsHomepage",
    true
);

user_pref(
    "browser.disableResetPrompt",
    true
);

user_pref(
    "browser.shell.checkDefaultBrowser",
    false
);

user_pref(
    "browser.warnOnQuit",
    false
);

user_pref(
    "browser.sessionstore.resume_from_crash",
    false
);

user_pref(
    "startup.homepage_welcome_url",
    ""
);

user_pref(
    "startup.homepage_welcome_url.additional",
    ""
);

user_pref(
    "startup.homepage_override_url",
    ""
);

user_pref(
    "browser.startup.upgradeDialog.enabled",
    false
);

USERJS_EOF

# ==========================================================
# PROXY
# ==========================================================

if [ "$PROXY_ENABLED" = "1" ]; then

    echo "SOCKS5: ATIVADO"
    echo "Servidor: $PROXY_HOST:$PROXY_PORT"

    cat >> "$PROFILE/user.js" <<USERJS_EOF

/*
 * SOCKS5
 */

user_pref(
    "network.proxy.type",
    1
);

user_pref(
    "network.proxy.socks",
    "$PROXY_HOST"
);

user_pref(
    "network.proxy.socks_port",
    $PROXY_PORT
);

user_pref(
    "network.proxy.socks_version",
    5
);

user_pref(
    "network.proxy.socks_remote_dns",
    true
);

USERJS_EOF

else

    echo "SOCKS5: DESATIVADO"

    cat >> "$PROFILE/user.js" <<'USERJS_EOF'

/*
 * Sem proxy.
 */

user_pref(
    "network.proxy.type",
    0
);

user_pref(
    "network.proxy.no_proxies_on",
    ""
);

USERJS_EOF

fi

# ==========================================================
# NEW TAB
# ==========================================================

NEW_TAB_XPI="$BASE/config/lynx-newtab.xpi"

if [ -f "$NEW_TAB_XPI" ]; then

    NEW_TAB_XPI_ABS="$(readlink -f "$NEW_TAB_XPI")"

    POLICY_DIR="$BASE/browser/firefox/distribution"

    POLICY_FILE="$POLICY_DIR/policies.json"

    mkdir -p "$POLICY_DIR"

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

fi

# ==========================================================
# CHROME CSS
# ==========================================================

mkdir -p "$PROFILE/chrome"

cat > "$PROFILE/chrome/userChrome.css" <<'CSS_EOF'
/*
 * Lynx Browser
 *
 * Alterações mínimas para evitar incompatibilidades
 * com versões futuras do Firefox.
 */

#aboutHeaderLearnMore {
    display: none !important;
}
CSS_EOF

# ==========================================================
# INFORMAÇÕES
# ==========================================================

echo
echo "========================================="
echo "            LYNX BROWSER"
echo "========================================="
echo
echo "TLS: padrão Firefox"
echo "Certificate Pinning: ATIVADO"
echo "DoH: DESATIVADO"
echo "DNS: sistema"
echo "SOCKS5: $([ "$PROXY_ENABLED" = "1" ] && echo ATIVADO || echo DESATIVADO)"
echo
echo "========================================="
echo

# ==========================================================
# EXECUTAR
# ==========================================================

exec "$FIREFOX" \
    --no-remote \
    --profile "$PROFILE" \
    "$HOME_PAGE" \
    "$@"

LYNX_EOF

chmod +x "$APP_DIR/lynx"

# ==========================================================
# VPN SCRIPT
# ==========================================================

cat > "$APP_DIR/vpn" <<'VPN_EOF'
#!/usr/bin/env bash

set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"

CONF="$BASE/config/vpn.conf"

if [ ! -f "$CONF" ]; then

    echo "Configuração não encontrada:"
    echo "$CONF"

    exit 1

fi

case "${1:-status}" in

    on)

        sed -i \
            's/^ENABLED=.*/ENABLED=1/' \
            "$CONF"

        echo
        echo "SOCKS5 ATIVADO."
        echo "Reinicie o Lynx Browser."
        echo

        ;;

    off)

        sed -i \
            's/^ENABLED=.*/ENABLED=0/' \
            "$CONF"

        echo
        echo "SOCKS5 DESATIVADO."
        echo "Reinicie o Lynx Browser."
        echo

        ;;

    status)

        # shellcheck disable=SC1090
        source "$CONF"

        if [ "${ENABLED:-0}" = "1" ]; then

            echo
            echo "SOCKS5: ATIVADO"
            echo "Servidor: ${HOST}:${PORT}"
            echo

        else

            echo
            echo "SOCKS5: DESATIVADO"
            echo

        fi

        ;;

    config)

        if command -v nano >/dev/null 2>&1; then

            nano "$CONF"

        elif command -v vi >/dev/null 2>&1; then

            vi "$CONF"

        else

            echo "Nenhum editor encontrado."
            exit 1

        fi

        ;;

    *)

        echo
        echo "Uso:"
        echo
        echo "  ./vpn on"
        echo "  ./vpn off"
        echo "  ./vpn status"
        echo "  ./vpn config"
        echo

        exit 1

        ;;

esac
VPN_EOF

chmod +x "$APP_DIR/vpn"

# ==========================================================
# START.SH
# ==========================================================

cat > "$APP_DIR/start.sh" <<'START_EOF'
#!/usr/bin/env bash

set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"

exec "$BASE/lynx" "$@"
START_EOF

chmod +x "$APP_DIR/start.sh"

# ==========================================================
# TESTE
# ==========================================================

cat > "$APP_DIR/test.sh" <<'TEST_EOF'
#!/usr/bin/env bash

set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"

FIREFOX="$BASE/browser/firefox/firefox"

TEST_PROFILE="/tmp/lynx-clean-profile-$$"

cleanup() {

    rm -rf "$TEST_PROFILE"

}

trap cleanup EXIT

mkdir -p "$TEST_PROFILE"

cat > "$TEST_PROFILE/user.js" <<'EOF'
/*
 * Perfil de diagnóstico.
 *
 * Sem DoH.
 * Sem proxy.
 */

user_pref("network.trr.mode", 5);
user_pref("network.trr.uri", "");
user_pref("network.proxy.type", 0);
EOF

echo
echo "========================================="
echo "        LYNX - TESTE DE CONEXÃO"
echo "========================================="
echo
echo "DoH: DESATIVADO"
echo "Proxy: DESATIVADO"
echo "Perfil: TEMPORÁRIO"
echo
echo "Abrindo https://example.com ..."
echo

exec "$FIREFOX" \
    --no-remote \
    --profile "$TEST_PROFILE" \
    "https://example.com"

TEST_EOF

chmod +x "$APP_DIR/test.sh"

# ==========================================================
# DESKTOP
# ==========================================================

echo "[8/8] Criando atalhos e documentação..."

cat > "$APP_DIR/Lynx Browser.desktop" <<DESKTOP_EOF
[Desktop Entry]

Version=1.0

Type=Application

Name=Lynx Browser
GenericName=Web Browser
Comment=Lynx Browser

Exec=$LOCAL_INSTALL/start.sh
Path=$LOCAL_INSTALL

Terminal=false

StartupNotify=true
StartupWMClass=LynxBrowser

Icon=$LOCAL_INSTALL/config/icons/lynx-logo.png

Categories=Network;WebBrowser;

Keywords=browser;internet;web;lynx;
DESKTOP_EOF

chmod +x "$APP_DIR/Lynx Browser.desktop"

# ==========================================================
# README
# ==========================================================

cat > "$APP_DIR/README.txt" <<'README_EOF'
====================================================
                 LYNX BROWSER
====================================================

Navegador Linux portátil baseado no Firefox.

====================================================
EXECUTAR
====================================================

    ./start.sh


====================================================
TESTE LIMPO
====================================================

Para testar a conexão sem as configurações
normais do Lynx:

    ./test.sh


====================================================
SOCKS5
====================================================

Ver estado:

    ./vpn status

Ativar:

    ./vpn on

Desativar:

    ./vpn off

Editar:

    ./vpn config


O SOCKS5 fica DESATIVADO por padrão.


====================================================
PR_END_OF_FILE_ERROR
====================================================

O Lynx foi configurado para:

- DoH desativado
- DNS do sistema
- Proxy desativado
- TLS padrão do Firefox
- Certificate Pinning ativado

Se o erro continuar mesmo com:

    ./test.sh

o problema provavelmente não está no HTML
ou na interface do Lynx.

Verifique:

- VPN do sistema
- proxy do sistema
- firewall
- antivírus
- DNS
- rede
- inspeção HTTPS
- relógio/data do sistema


====================================================
README_EOF

# ==========================================================
# EMPACOTAMENTO
# ==========================================================

echo
echo "========================================="
echo "          EMPACOTANDO LYNX"
echo "========================================="
echo

cd "$WORK"

tar \
    -czf "$OUT" \
    "$APP"

if [ ! -s "$OUT" ]; then

    echo "ERRO: arquivo final não foi criado."
    exit 1

fi

echo
echo "Build criado:"
echo
echo "  $OUT"
echo

du -h "$OUT"

# ==========================================================
# INSTALAÇÃO LOCAL
# ==========================================================

echo
echo "Instalando localmente..."

cd "$ROOT"

tar \
    -xzf "$OUT"

# ==========================================================
# FINAL
# ==========================================================

echo
echo "========================================="
echo "       LYNX BROWSER PRONTO"
echo "========================================="
echo
echo "Diretório:"
echo
echo "  $LOCAL_INSTALL"
echo
echo "Executável:"
echo
echo "  $LOCAL_INSTALL/start.sh"
echo
echo "Teste:"
echo
echo "  $LOCAL_INSTALL/test.sh"
echo
echo "========================================="
echo

# ==========================================================
# INICIAR
# ==========================================================

exec "$LOCAL_INSTALL/start.sh"
