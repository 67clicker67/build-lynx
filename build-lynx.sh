#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
#                 LYNX BROWSER - BUILD
# ==========================================================

APP="LynxBrowser"
ARCH="x86_64"

ROOT="$PWD"
WORK="$ROOT/lynx-build"
OUT="$ROOT/${APP}-Linux-${ARCH}.tar.gz"
INSTALL_DIR="$WORK/$APP"

LOGO="$ROOT/lynx-logo.png"

echo "========================================="
echo "        LYNX BROWSER - BUILD"
echo "========================================="
echo

# ==========================================================
# DEPENDÊNCIAS
# ==========================================================

for cmd in curl tar base64 zip sed grep find; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Erro: dependência não encontrada: $cmd"
        exit 1
    fi
done

# ==========================================================
# LIMPEZA
# ==========================================================

rm -rf "$WORK"

mkdir -p \
    "$INSTALL_DIR/browser" \
    "$INSTALL_DIR/profile" \
    "$INSTALL_DIR/config"

# ==========================================================
# LOGO
# ==========================================================

if [ ! -f "$LOGO" ]; then
    echo "Baixando logo do Lynx..."

    curl -fL \
        "https://raw.githubusercontent.com/Pax0102/img/main/1.png" \
        -o "$LOGO"
fi

if [ ! -s "$LOGO" ]; then
    echo "Erro: não foi possível obter a logo."
    exit 1
fi

echo "Logo: $LOGO"

LOGO_B64="$(base64 -w 0 "$LOGO")"

cp "$LOGO" "$INSTALL_DIR/config/lynx-logo.png"

# ==========================================================
# HOME PAGE
# ==========================================================

echo "Criando página inicial..."

cat > "$INSTALL_DIR/config/home.html" <<HOME_EOF
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

@media(prefers-reduced-motion:reduce) {

    *,
    *::before,
    *::after {

        animation-duration: .001ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: .001ms !important;
    }
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

    transition: background .08s linear;
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

    width: min(620px, 86vw);

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

    opacity: .9;
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

    width: min(620px, 86vw);
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
                <span class="shortcut-icon">🔎</span>
                DuckDuckGo
            </div>

            <div
                class="shortcut"
                tabindex="0"
                onclick="abrir('https://www.youtube.com')"
            >
                <span class="shortcut-icon">▶</span>
                YouTube
            </div>

            <div
                class="shortcut"
                tabindex="0"
                onclick="abrir('https://www.tiktok.com/')"
            >
                <span class="shortcut-icon">▶</span>
                TikTok
            </div>

            <div
                class="shortcut"
                tabindex="0"
                onclick="abrir('https://classroom.google.com/')"
            >
                <span class="shortcut-icon">⌘</span>
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
            RÁPIDO
            ·
            PRIVADO
            ·
            DIRETO
        </div>

    </div>

</div>

<script>

/* ==========================================================
   RELÓGIO
   ========================================================== */

function atualizarRelogio() {

    const agora = new Date();

    const opcoes = {

        timeZone: "America/Sao_Paulo",

        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",

        hour12: false
    };

    const hora =
        agora.toLocaleTimeString(
            "pt-BR",
            opcoes
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
   EFEITO DO MOUSE
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

            const xp =
                (
                    e.clientX /
                    window.innerWidth *
                    100
                ).toFixed(2);

            const yp =
                (
                    e.clientY /
                    window.innerHeight *
                    100
                ).toFixed(2);

            root.style.setProperty(
                "--mx",
                xp + "%"
            );

            root.style.setProperty(
                "--my",
                yp + "%"
            );
        }
    );
}


/* ==========================================================
   PESQUISA
   ========================================================== */

function pesquisar() {

    const campo =
        document.getElementById("search");

    const texto =
        campo.value.trim();

    if (!texto) {
        ret
