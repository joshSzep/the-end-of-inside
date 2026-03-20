#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
pdf_script="$script_dir/create-pdf.sh"
input_file="$repo_root/The End of Inside.md"
pdf_file="$repo_root/The End of Inside.pdf"
cover_file="$repo_root/cover.png"
output_dir="$repo_root/website"
output_file="$output_dir/index.html"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/the-end-of-inside-site.XXXXXX")"
chapter_md="$temp_dir/chapter-01.md"
chapter_html_raw="$temp_dir/chapter-01.raw.html"
chapter_html="$temp_dir/chapter-01.html"
template_html="$temp_dir/index.template.html"

cleanup() {
  rm -rf "$temp_dir"
}

trap cleanup EXIT

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Required command not found: $command_name" >&2
    exit 1
  fi
}

for command_name in awk pandoc sed; do
  require_command "$command_name"
done

for required_file in "$pdf_script" "$cover_file"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

bash "$pdf_script"

if [[ ! -f "$input_file" ]]; then
  echo "Generated manuscript not found: $input_file" >&2
  exit 1
fi

if [[ ! -f "$pdf_file" ]]; then
  echo "Generated PDF not found: $pdf_file" >&2
  exit 1
fi

awk '
BEGIN {
  capture = 0
}

$0 ~ /^### Chapter 01 - / {
  capture = 1
  sub(/^### /, "## ")
  print
  next
}

capture && $0 ~ /^### / {
  exit
}

capture {
  print
}
' "$input_file" > "$chapter_md"

if [[ ! -s "$chapter_md" ]]; then
  echo "Failed to extract Chapter 01 from $input_file" >&2
  exit 1
fi

pandoc "$chapter_md" \
  --from=markdown+raw_tex+raw_attribute \
  --to=html5 \
  --strip-comments \
  -o "$chapter_html_raw"

sed \
  -e 's#<p><em>\* \* \*</em></p>#<p class="scene-break" aria-hidden="true">* * *</p>#g' \
  "$chapter_html_raw" > "$chapter_html"

mkdir -p "$output_dir"
cp -f "$pdf_file" "$output_dir/"
cp -f "$cover_file" "$output_dir/"

cat > "$template_html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>The End of Inside</title>
    <meta
      name="description"
      content="A slightly unsettling launch site for The End of Inside: read Chapter One in full, download the PDF, and step into a world where connection no longer stops at the skin."
    >
    <meta name="theme-color" content="#0b090c">
    <meta property="og:title" content="The End of Inside">
    <meta
      property="og:description"
      content="Read the first chapter in full. Download the manuscript. Enter a world where emotional boundaries blur before anyone knows how to hold them."
    >
    <meta property="og:image" content="cover.png">
    <link rel="icon" href="cover.png">
    <style>
      :root {
        --bg: #0b090c;
        --bg-soft: #141015;
        --panel: rgba(17, 12, 15, 0.72);
        --panel-strong: rgba(19, 14, 17, 0.88);
        --line: rgba(238, 190, 141, 0.16);
        --line-strong: rgba(238, 190, 141, 0.3);
        --gold: #e7ba8b;
        --gold-deep: #c98f63;
        --gold-glow: rgba(239, 194, 144, 0.22);
        --mist: rgba(255, 207, 159, 0.09);
        --text: #f6e8d7;
        --muted: #dbc0a7;
        --shadow: rgba(0, 0, 0, 0.6);
        --pointer-x: 0;
        --pointer-y: 0;
      }

      * {
        box-sizing: border-box;
      }

      html {
        scroll-behavior: smooth;
      }

      body {
        margin: 0;
        min-height: 100svh;
        color: var(--text);
        background: var(--bg);
        font-family: "Iowan Old Style", "Baskerville", "Palatino Linotype", "Book Antiqua", serif;
        text-rendering: optimizeLegibility;
        -webkit-font-smoothing: antialiased;
        overflow-x: clip;
        padding-bottom: 3.5rem;
      }

      body::before,
      body::after {
        content: "";
        position: fixed;
        inset: 0;
        pointer-events: none;
      }

      body::before {
        inset: -8%;
        background:
          radial-gradient(circle at 50% 36%, rgba(255, 219, 171, 0.26), transparent 18%),
          radial-gradient(circle at 50% 55%, rgba(223, 152, 96, 0.12), transparent 28%),
          linear-gradient(180deg, rgba(8, 7, 9, 0.8), rgba(8, 7, 9, 0.97)),
          url("cover.png") center 14% / cover no-repeat;
        filter: blur(20px) saturate(0.72) brightness(0.38);
        transform: scale(1.08);
        z-index: -3;
      }

      body::after {
        background:
          radial-gradient(circle at 50% 32%, rgba(255, 217, 172, 0.06), transparent 20%),
          radial-gradient(circle at 10% 20%, rgba(194, 130, 88, 0.11), transparent 24%),
          radial-gradient(circle at 90% 18%, rgba(194, 130, 88, 0.08), transparent 22%),
          linear-gradient(180deg, rgba(9, 8, 10, 0.15), rgba(9, 8, 10, 0.66) 28%, rgba(9, 8, 10, 0.92));
        z-index: -2;
      }

      .noise,
      .mist-layer,
      .progress-line {
        position: fixed;
        inset: 0;
        pointer-events: none;
      }

      .noise {
        z-index: -1;
        opacity: 0.17;
        mix-blend-mode: soft-light;
        background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 160 160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='160' height='160' filter='url(%23n)' opacity='.8'/%3E%3C/svg%3E");
        background-size: 220px 220px;
        animation: grainShift 18s steps(8) infinite;
      }

      .mist-layer {
        z-index: -1;
        background:
          radial-gradient(circle at 50% 35%, rgba(255, 214, 165, 0.06), transparent 18%),
          radial-gradient(circle at 46% 56%, rgba(255, 214, 165, 0.05), transparent 24%),
          radial-gradient(circle at 52% 58%, rgba(255, 214, 165, 0.05), transparent 24%);
        animation: mistPulse 12s ease-in-out infinite alternate;
      }

      .progress-line {
        inset: 0 0 auto;
        height: 2px;
        z-index: 40;
        background: linear-gradient(90deg, rgba(255, 203, 148, 0.02), rgba(255, 203, 148, 0.08));
      }

      .progress-line span {
        display: block;
        width: 100%;
        height: 100%;
        transform-origin: 0 50%;
        transform: scaleX(0);
        background: linear-gradient(90deg, rgba(239, 194, 144, 0.36), rgba(239, 194, 144, 0.92));
        box-shadow: 0 0 16px rgba(239, 194, 144, 0.48);
      }

      a {
        color: inherit;
      }

      img {
        display: block;
        max-width: 100%;
      }

      .shell {
        width: min(1200px, calc(100vw - 2rem));
        margin: 0 auto;
      }

      .topbar {
        position: sticky;
        top: 0;
        z-index: 20;
        backdrop-filter: blur(18px);
        background: linear-gradient(180deg, rgba(10, 9, 12, 0.78), rgba(10, 9, 12, 0.42));
        border-bottom: 1px solid rgba(238, 190, 141, 0.08);
      }

      .topbar-inner {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        padding: 0.95rem 0;
      }

      .brand {
        text-decoration: none;
        text-transform: uppercase;
        letter-spacing: 0.22em;
        font-size: 0.72rem;
        color: var(--muted);
      }

      .top-links {
        display: flex;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
        justify-content: flex-end;
      }

      .top-links a {
        text-decoration: none;
        font-size: 0.84rem;
        color: rgba(246, 232, 215, 0.8);
        position: relative;
      }

      .top-links a::after {
        content: "";
        position: absolute;
        left: 0;
        right: 0;
        bottom: -0.35rem;
        height: 1px;
        background: linear-gradient(90deg, transparent, rgba(239, 194, 144, 0.9), transparent);
        transform: scaleX(0.2);
        opacity: 0;
        transition: transform 240ms ease, opacity 240ms ease;
      }

      .top-links a:hover::after,
      .top-links a:focus-visible::after {
        transform: scaleX(1);
        opacity: 1;
      }

      main {
        position: relative;
      }

      .hero {
        display: grid;
        grid-template-columns: minmax(0, 0.95fr) minmax(320px, 0.85fr);
        gap: clamp(2rem, 4vw, 4.5rem);
        align-items: center;
        min-height: calc(100svh - 72px);
        padding: clamp(3.5rem, 7vw, 6rem) 0 clamp(2rem, 6vw, 4rem);
      }

      .eyebrow {
        margin: 0 0 1rem;
        text-transform: uppercase;
        letter-spacing: 0.24em;
        font-size: 0.76rem;
        color: rgba(231, 186, 139, 0.82);
      }

      .hero-copy h1 {
        margin: 0;
        font-weight: 400;
        line-height: 0.83;
        text-transform: uppercase;
        letter-spacing: 0.03em;
        color: #f0c092;
        text-shadow: 0 0 24px rgba(233, 174, 116, 0.1);
      }

      .hero-copy h1 span,
      .hero-copy h1 strong {
        display: block;
      }

      .hero-copy h1 span {
        font-size: clamp(2.5rem, 6vw, 4.4rem);
      }

      .hero-copy h1 strong {
        font-size: clamp(4.9rem, 12vw, 8.9rem);
        font-weight: 400;
      }

      .hero-copy p {
        max-width: 36rem;
        font-size: clamp(1.02rem, 0.6vw + 0.96rem, 1.18rem);
        line-height: 1.75;
        color: rgba(246, 232, 215, 0.84);
      }

      .hero-copy .lede {
        margin: 1.75rem 0 0;
        font-size: clamp(1.12rem, 0.95vw + 1rem, 1.5rem);
        color: rgba(248, 232, 217, 0.94);
      }

      .hero-copy .hook {
        margin-top: 1rem;
      }

      .hero-quote {
        margin: 1.5rem 0 0;
        padding-left: 1.25rem;
        border-left: 1px solid rgba(239, 194, 144, 0.3);
        color: rgba(231, 186, 139, 0.95);
        max-width: 34rem;
      }

      .cta-row,
      .micro-links {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        gap: 0.85rem;
      }

      .cta-row {
        margin-top: 2rem;
      }

      .micro-links {
        margin-top: 1rem;
        gap: 1rem 1.25rem;
      }

      .button {
        position: relative;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        padding: 0.95rem 1.35rem;
        border-radius: 999px;
        text-decoration: none;
        font-size: 0.94rem;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        overflow: hidden;
        border: 1px solid transparent;
        transition: transform 220ms ease, border-color 220ms ease, background 220ms ease, color 220ms ease;
      }

      .button::before {
        content: "";
        position: absolute;
        inset: 0;
        transform: translateX(-120%);
        background: linear-gradient(120deg, transparent 20%, rgba(255, 255, 255, 0.25) 50%, transparent 80%);
        transition: transform 420ms ease;
      }

      .button:hover,
      .button:focus-visible {
        transform: translateY(-1px);
      }

      .button:hover::before,
      .button:focus-visible::before {
        transform: translateX(120%);
      }

      .button-primary {
        color: #140f12;
        background: linear-gradient(135deg, #f5c598, #d99b6a 55%, #be7d57);
        box-shadow: 0 14px 32px rgba(195, 127, 75, 0.28);
      }

      .button-secondary {
        color: var(--text);
        background: rgba(255, 255, 255, 0.025);
        border-color: rgba(239, 194, 144, 0.26);
        backdrop-filter: blur(10px);
      }

      .micro-links a {
        font-size: 0.9rem;
        color: rgba(246, 232, 215, 0.72);
        text-decoration: none;
      }

      .micro-links a:hover,
      .micro-links a:focus-visible {
        color: var(--gold);
      }

      .hero-visual {
        position: relative;
        min-height: clamp(520px, 72vw, 840px);
        border-radius: 2.2rem;
        overflow: hidden;
        background:
          linear-gradient(180deg, rgba(17, 13, 16, 0.2), rgba(17, 13, 16, 0.7)),
          radial-gradient(circle at 50% 34%, rgba(255, 221, 183, 0.16), transparent 22%),
          rgba(14, 10, 13, 0.58);
        border: 1px solid rgba(239, 194, 144, 0.14);
        box-shadow: 0 40px 120px rgba(0, 0, 0, 0.55), inset 0 0 80px rgba(255, 214, 165, 0.04);
        isolation: isolate;
        transform:
          translate3d(calc(var(--pointer-x) * 8px), calc(var(--pointer-y) * 8px), 0)
          scale(1.003);
      }

      .hero-visual::before,
      .hero-visual::after {
        content: "";
        position: absolute;
        inset: 0;
        background: url("cover.png") center center / cover no-repeat;
        opacity: 0.24;
        filter: blur(14px) saturate(0.6);
        transform: scale(1.08);
      }

      .hero-visual::after {
        opacity: 0.2;
        mix-blend-mode: screen;
        filter: blur(32px) saturate(0.8);
        animation: imageDrift 14s ease-in-out infinite alternate;
      }

      .ghost {
        position: absolute;
        inset: 10% 14% 10%;
        background: url("cover.png") center center / contain no-repeat;
        opacity: 0.22;
        mix-blend-mode: screen;
        filter: blur(26px) saturate(0.7);
      }

      .ghost-left {
        transform: translateX(-8%) scale(1.01);
        animation: ghostLeft 11s ease-in-out infinite alternate;
      }

      .ghost-right {
        transform: translateX(8%) scale(1.03);
        animation: ghostRight 13s ease-in-out infinite alternate;
      }

      .seam {
        position: absolute;
        top: 7%;
        bottom: 8%;
        left: 50%;
        width: clamp(4px, 0.55vw, 7px);
        transform: translateX(-50%);
        background: linear-gradient(180deg, transparent, rgba(255, 223, 185, 0.78) 12%, rgba(250, 202, 146, 0.98) 50%, rgba(255, 223, 185, 0.78) 88%, transparent);
        box-shadow: 0 0 20px rgba(255, 212, 164, 0.6), 0 0 60px rgba(245, 177, 111, 0.42), 0 0 120px rgba(245, 177, 111, 0.18);
        opacity: 0.94;
        animation: seamPulse 6.8s ease-in-out infinite;
      }

      .halo,
      .halo::before,
      .halo::after {
        position: absolute;
        inset: auto;
        border-radius: 999px;
        pointer-events: none;
        content: "";
      }

      .halo {
        width: clamp(180px, 34vw, 320px);
        height: clamp(180px, 34vw, 320px);
        left: 50%;
        top: 47%;
        transform: translate(-50%, -50%);
        background: radial-gradient(circle, rgba(253, 224, 189, 0.18), rgba(253, 224, 189, 0.02) 55%, transparent 72%);
        filter: blur(4px);
        animation: haloPulse 8s ease-in-out infinite alternate;
      }

      .halo::before {
        inset: -14%;
        background: radial-gradient(circle, rgba(253, 224, 189, 0.1), transparent 68%);
        filter: blur(18px);
      }

      .halo::after {
        inset: 14%;
        background: radial-gradient(circle, rgba(255, 214, 165, 0.12), transparent 72%);
        filter: blur(10px);
      }

      .cover-frame {
        position: absolute;
        inset: 11% 12% 10%;
        display: grid;
        place-items: center;
        z-index: 2;
      }

      .cover-frame::before {
        content: "";
        position: absolute;
        inset: 7% 12% 6%;
        border-radius: 1.8rem;
        background: linear-gradient(180deg, rgba(255, 229, 192, 0.08), rgba(255, 229, 192, 0));
        border: 1px solid rgba(239, 194, 144, 0.16);
        backdrop-filter: blur(10px);
        box-shadow: inset 0 0 60px rgba(255, 216, 171, 0.04), 0 30px 100px rgba(0, 0, 0, 0.4);
      }

      .cover-frame img {
        position: relative;
        width: min(100%, 29rem);
        border-radius: 1rem;
        box-shadow: 0 24px 80px rgba(0, 0, 0, 0.5);
        animation: coverFloat 7.5s ease-in-out infinite;
      }

      .caption-chip {
        position: absolute;
        left: 1.25rem;
        right: 1.25rem;
        bottom: 1.25rem;
        z-index: 3;
        padding: 1rem 1.1rem;
        border-radius: 1.2rem;
        background: linear-gradient(180deg, rgba(15, 11, 14, 0.58), rgba(15, 11, 14, 0.9));
        border: 1px solid rgba(239, 194, 144, 0.14);
        backdrop-filter: blur(14px);
        font-size: 0.96rem;
        line-height: 1.6;
        color: rgba(246, 232, 215, 0.8);
      }

      .intro-cards {
        display: grid;
        gap: 1rem;
      }

      .intro-cards {
        grid-template-columns: repeat(3, minmax(0, 1fr));
        margin-top: clamp(1rem, 2vw, 2rem);
      }

      .card {
        position: relative;
        padding: 1.35rem;
        border-radius: 1.4rem;
        background: linear-gradient(180deg, rgba(17, 12, 15, 0.7), rgba(17, 12, 15, 0.9));
        border: 1px solid rgba(239, 194, 144, 0.11);
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        overflow: hidden;
      }

      .card::before {
        content: "";
        position: absolute;
        inset: 0;
        background: radial-gradient(circle at 50% 0%, rgba(255, 226, 193, 0.08), transparent 46%);
        opacity: 0.8;
        pointer-events: none;
      }

      .card h2,
      .card h3 {
        margin: 0 0 0.6rem;
        font-weight: 400;
        color: var(--text);
        font-size: clamp(1.2rem, 1vw + 1rem, 1.5rem);
      }

      .card p,
      .chapter-intro p,
      .afterword p,
      footer p {
        margin: 0;
        color: rgba(246, 232, 215, 0.74);
        line-height: 1.7;
      }

      .quote-band,
      .chapter-card,
      .afterword,
      footer {
        background: linear-gradient(180deg, rgba(17, 12, 15, 0.58), rgba(17, 12, 15, 0.88));
        border: 1px solid rgba(239, 194, 144, 0.12);
        backdrop-filter: blur(14px);
        box-shadow: 0 30px 100px rgba(0, 0, 0, 0.35);
      }

      .quote-band {
        margin-top: 1.3rem;
        padding: clamp(1.5rem, 3vw, 2.2rem);
        border-radius: 1.8rem;
        position: relative;
        overflow: hidden;
      }

      .quote-band::before {
        content: "";
        position: absolute;
        inset: 0;
        background: linear-gradient(90deg, transparent, rgba(239, 194, 144, 0.12), transparent);
        transform: translateX(-100%);
        animation: sweep 10s ease-in-out infinite;
      }

      .quote-band blockquote {
        position: relative;
        margin: 0;
        font-size: clamp(1.4rem, 1.8vw + 1rem, 2rem);
        line-height: 1.45;
        color: rgba(245, 228, 214, 0.92);
      }

      .quote-band cite {
        display: block;
        margin-top: 0.9rem;
        font-style: normal;
        text-transform: uppercase;
        letter-spacing: 0.18em;
        font-size: 0.72rem;
        color: rgba(231, 186, 139, 0.7);
      }

      .chapter-intro h2,
      .afterword h2 {
        margin: 0 0 0.55rem;
        font-weight: 400;
        font-size: clamp(1.8rem, 2vw + 1rem, 3rem);
        color: var(--text);
      }

      .chapter-section {
        padding-top: clamp(4rem, 7vw, 7rem);
      }

      .chapter-intro {
        max-width: 44rem;
        margin: 0 auto 1.6rem;
        text-align: center;
      }

      .chapter-card {
        position: relative;
        border-radius: 2rem;
        overflow: hidden;
      }

      .chapter-card::before,
      .chapter-card::after {
        content: "";
        position: absolute;
        inset: auto;
        pointer-events: none;
      }

      .chapter-card::before {
        top: -10%;
        left: 50%;
        width: min(34vw, 320px);
        height: min(34vw, 320px);
        transform: translateX(-50%);
        border-radius: 999px;
        background: radial-gradient(circle, rgba(255, 222, 187, 0.12), transparent 70%);
        filter: blur(18px);
      }

      .chapter-card::after {
        top: 0;
        bottom: 0;
        left: 50%;
        width: 1px;
        transform: translateX(-50%);
        background: linear-gradient(180deg, transparent, rgba(239, 194, 144, 0.25), transparent);
        opacity: 0.55;
      }

      .chapter-body {
        position: relative;
        padding: clamp(1.5rem, 4vw, 3.2rem) clamp(1.15rem, 3vw, 3rem);
      }

      .chapter-body > h2 {
        margin: 0 0 1.6rem;
        text-align: center;
        text-transform: uppercase;
        letter-spacing: 0.16em;
        font-size: clamp(1.8rem, 2vw + 1rem, 3rem);
        font-weight: 400;
        color: #efc195;
      }

      .chapter-body > p,
      .chapter-body li {
        width: min(100%, 44rem);
        margin-left: auto;
        margin-right: auto;
        font-size: clamp(1.02rem, 0.36vw + 1rem, 1.18rem);
        line-height: 1.92;
        color: rgba(247, 235, 222, 0.86);
      }

      .chapter-body > p + p {
        margin-top: 1.12rem;
      }

      .chapter-body > p:first-of-type::first-letter {
        float: left;
        padding-right: 0.12em;
        line-height: 0.83;
        font-size: 4.9rem;
        color: #f2c89d;
      }

      .chapter-body .scene-break {
        margin: 2.4rem auto;
        text-align: center;
        letter-spacing: 0.55em;
        color: rgba(231, 186, 139, 0.6);
      }

      .chapter-body em {
        color: rgba(241, 207, 174, 0.94);
      }

      .afterword {
        max-width: 58rem;
        margin: 1.7rem auto 0;
        padding: clamp(1.4rem, 3vw, 2.2rem);
        border-radius: 1.8rem;
      }

      footer {
        margin: clamp(2rem, 5vw, 4rem) 0 2rem;
        padding: 1.3rem 1.4rem;
        border-radius: 1.4rem;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 1rem;
        flex-wrap: wrap;
      }

      footer nav {
        display: flex;
        gap: 1rem;
        flex-wrap: wrap;
      }

      footer a {
        text-decoration: none;
        color: rgba(246, 232, 215, 0.78);
      }

      footer a:hover,
      footer a:focus-visible {
        color: var(--gold);
      }

      [data-reveal] {
        opacity: 0;
        transform: translateY(22px);
        transition: opacity 700ms ease, transform 700ms cubic-bezier(0.22, 1, 0.36, 1);
      }

      body.is-ready [data-reveal].is-visible {
        opacity: 1;
        transform: none;
      }

      @keyframes grainShift {
        0% { transform: translate3d(0, 0, 0); }
        25% { transform: translate3d(-2%, 2%, 0); }
        50% { transform: translate3d(2%, -1%, 0); }
        75% { transform: translate3d(1%, 2%, 0); }
        100% { transform: translate3d(0, 0, 0); }
      }

      @keyframes mistPulse {
        from { opacity: 0.7; transform: scale(1); }
        to { opacity: 1; transform: scale(1.04); }
      }

      @keyframes seamPulse {
        0%, 100% {
          opacity: 0.8;
          filter: saturate(0.95);
        }
        50% {
          opacity: 1;
          filter: saturate(1.12);
        }
      }

      @keyframes haloPulse {
        from { opacity: 0.75; transform: translate(-50%, -50%) scale(0.98); }
        to { opacity: 1; transform: translate(-50%, -50%) scale(1.05); }
      }

      @keyframes coverFloat {
        0%, 100% { transform: translateY(0) scale(1); }
        50% { transform: translateY(-10px) scale(1.008); }
      }

      @keyframes imageDrift {
        from { transform: scale(1.08) translateX(-1.5%); }
        to { transform: scale(1.11) translateX(1.5%); }
      }

      @keyframes ghostLeft {
        from { transform: translateX(-10%) scale(1.01); opacity: 0.18; }
        to { transform: translateX(-5%) scale(1.04); opacity: 0.26; }
      }

      @keyframes ghostRight {
        from { transform: translateX(10%) scale(1.04); opacity: 0.15; }
        to { transform: translateX(5%) scale(1.07); opacity: 0.24; }
      }

      @keyframes sweep {
        0% { transform: translateX(-120%); }
        18%, 100% { transform: translateX(120%); }
      }

      @media (max-width: 980px) {
        .hero,
        .afterword {
          grid-template-columns: 1fr;
        }

        .hero {
          min-height: auto;
          padding-top: 2.6rem;
        }

        .hero-visual {
          order: -1;
          min-height: 68svh;
        }

        .intro-cards {
          grid-template-columns: 1fr;
        }
      }

      @media (max-width: 720px) {
        body {
          padding-bottom: 4rem;
        }

        .shell {
          width: min(100vw - 1rem, 1200px);
        }

        .topbar-inner {
          align-items: flex-start;
        }

        .top-links {
          gap: 0.8rem;
        }

        .hero-copy h1 span {
          letter-spacing: 0.06em;
        }

        .hero-copy h1 strong {
          letter-spacing: 0.02em;
        }

        .cover-frame {
          inset: 10% 7% 12%;
        }

        .caption-chip {
          left: 0.9rem;
          right: 0.9rem;
          bottom: 0.9rem;
        }

        .chapter-body {
          padding: 1.2rem 1rem 2rem;
        }

        .chapter-body > p:first-of-type::first-letter {
          font-size: 3.8rem;
        }

      }

      @media (prefers-reduced-motion: reduce) {
        html {
          scroll-behavior: auto;
        }

        *,
        *::before,
        *::after {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          transition-duration: 0.01ms !important;
        }

        [data-reveal] {
          opacity: 1;
          transform: none;
        }
      }
    </style>
  </head>
  <body>
    <div class="mist-layer" aria-hidden="true"></div>
    <div class="noise" aria-hidden="true"></div>
    <div class="progress-line" aria-hidden="true"><span></span></div>

    <header class="topbar" data-reveal>
      <div class="shell topbar-inner">
        <a class="brand" href="#top">The End of Inside</a>
        <nav class="top-links" aria-label="Primary">
          <a href="#chapter-one">Chapter One</a>
          <a href="The%20End%20of%20Inside.pdf" download="The End of Inside.pdf">PDF</a>
          <a href="cover.png" download="cover.png">Cover</a>
          <a href="https://github.com/joshSzep/the-end-of-inside" target="_blank" rel="noreferrer">Source</a>
          <a href="https://the-end-of-inside.joshszep.com" target="_blank" rel="noreferrer">Launch site</a>
        </nav>
      </div>
    </header>

    <main id="top">
      <section class="shell hero">
        <div class="hero-copy" data-reveal>
          <p class="eyebrow">A novel by Joshua Szepietowski</p>
          <h1>
            <span>The End Of</span>
            <strong>Inside</strong>
          </h1>
          <p class="lede">
            A world built on shared feeling meets the one woman who cannot keep connection from lingering after the room is over.
          </p>
          <p class="hook">
            This launch page gives you the first chapter in full, then dares you to keep going: into beauty, consent, collapse, responsibility, and the ache of learning how not to erase the people you love by loving them too easily.
          </p>
          <p class="hero-quote">
            “If there was a part of her that belonged only to her, morning never asked after it.”
          </p>
          <div class="cta-row">
            <a class="button button-primary" href="The%20End%20of%20Inside.pdf" download="The End of Inside.pdf">Download the PDF</a>
            <a class="button button-secondary" href="#chapter-one">Read Chapter One</a>
          </div>
          <div class="micro-links">
            <a href="cover.png" download="cover.png">Download cover art</a>
            <a href="https://github.com/joshSzep/the-end-of-inside" target="_blank" rel="noreferrer">Read the source</a>
            <a href="https://the-end-of-inside.joshszep.com" target="_blank" rel="noreferrer">Visit the live launch site</a>
          </div>
        </div>

        <div class="hero-visual" data-reveal aria-hidden="true">
          <div class="ghost ghost-left"></div>
          <div class="ghost ghost-right"></div>
          <div class="halo"></div>
          <div class="seam"></div>
          <div class="cover-frame">
            <img src="cover.png" alt="Cover art for The End of Inside">
          </div>
          <div class="caption-chip">
            Slightly wrong closeness. Warmth that doesn't release. A threshold bright enough to feel like mercy until it becomes consequence.
          </div>
        </div>
      </section>

      <section class="shell intro-cards">
        <article class="card" data-reveal>
          <h2>Connection That Lingers</h2>
          <p>
            Rei lives in a city where emotion moves like weather. Around her, relief does not always fade when it should.
          </p>
        </article>
        <article class="card" data-reveal>
          <h2>No Private Room</h2>
          <p>
            Separation is not freedom here. It is panic, estrangement, and the sudden violence of being left only with yourself.
          </p>
        </article>
        <article class="card" data-reveal>
          <h2>Read Before The Edge Hardens</h2>
          <p>
            The opening is below in full. The manuscript goes on into fracture, skill, grief, and the cost of ethical intimacy.
          </p>
        </article>
      </section>

      <section class="shell quote-band" data-reveal>
        <blockquote>
          Some worlds ask whether intimacy is safe. This one asks what happens when intimacy is ordinary, beautiful, and still capable of harm.
        </blockquote>
        <cite>Download the full manuscript if the first chapter gets under your skin.</cite>
      </section>

      <section class="shell chapter-section" id="chapter-one">
        <div class="chapter-intro" data-reveal>
          <p class="eyebrow">Begin Here</p>
          <h2>No Edges</h2>
          <p>
            The first chapter appears below in full. Stay with it long enough to feel how ordinary shared interior life is before the damage starts to show.
          </p>
        </div>

        <article class="chapter-card" data-reveal>
          <div class="chapter-body">
__CHAPTER_HTML__
          </div>
        </article>

        <section class="afterword" data-reveal>
          <div>
            <p class="eyebrow">When The Opening Holds</p>
            <h2>Take the rest before the room closes.</h2>
            <p>
              The PDF continues past public warmth into Yui, fracture, the ethics of access, and Rei's painful education in how to stay open without collapsing the people who turn toward her.
            </p>
            <div class="cta-row">
              <a class="button button-primary" href="The%20End%20of%20Inside.pdf" download="The End of Inside.pdf">Download the full PDF</a>
              <a class="button button-secondary" href="https://github.com/joshSzep/the-end-of-inside" target="_blank" rel="noreferrer">Open the source</a>
            </div>
          </div>
        </section>
      </section>

      <footer class="shell" data-reveal>
        <p>&copy; <span data-year></span> Joshua Szepietowski. Built from the current manuscript.</p>
        <nav aria-label="Footer">
          <a href="The%20End%20of%20Inside.pdf" download="The End of Inside.pdf">PDF</a>
          <a href="cover.png" download="cover.png">Cover</a>
          <a href="https://github.com/joshSzep/the-end-of-inside" target="_blank" rel="noreferrer">Source</a>
          <a href="https://the-end-of-inside.joshszep.com" target="_blank" rel="noreferrer">Launch site</a>
        </nav>
      </footer>
    </main>

    <script>
      (() => {
        const root = document.documentElement;
        const progress = document.querySelector('.progress-line span');
        const revealTargets = document.querySelectorAll('[data-reveal]');
        const updateProgress = () => {
          const scrollable = document.documentElement.scrollHeight - window.innerHeight;
          const ratio = scrollable > 0 ? Math.min(window.scrollY / scrollable, 1) : 0;
          if (progress) {
            progress.style.transform = `scaleX(${ratio})`;
          }
        };

        const observer = new IntersectionObserver(
          entries => {
            entries.forEach(entry => {
              if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                observer.unobserve(entry.target);
              }
            });
          },
          {
            threshold: 0,
            rootMargin: '0px 0px -6% 0px'
          }
        );

        revealTargets.forEach(target => observer.observe(target));

        const yearNode = document.querySelector('[data-year]');
        if (yearNode) {
          yearNode.textContent = new Date().getFullYear();
        }

        updateProgress();
        window.addEventListener('scroll', updateProgress, { passive: true });
        window.addEventListener('resize', updateProgress);

        if (window.matchMedia('(pointer: fine)').matches) {
          let targetX = 0;
          let targetY = 0;
          let currentX = 0;
          let currentY = 0;

          window.addEventListener('pointermove', event => {
            targetX = event.clientX / window.innerWidth - 0.5;
            targetY = event.clientY / window.innerHeight - 0.5;
          }, { passive: true });

          const drift = () => {
            currentX += (targetX - currentX) * 0.08;
            currentY += (targetY - currentY) * 0.08;
            root.style.setProperty('--pointer-x', currentX.toFixed(4));
            root.style.setProperty('--pointer-y', currentY.toFixed(4));
            window.requestAnimationFrame(drift);
          };

          window.requestAnimationFrame(drift);
        }

        window.requestAnimationFrame(() => {
          document.body.classList.add('is-ready');
          revealTargets.forEach(target => {
            if (target.getBoundingClientRect().top < window.innerHeight * 0.9) {
              target.classList.add('is-visible');
            }
          });
        });
      })();
    </script>
  </body>
</html>
EOF

awk -v chapter_file="$chapter_html" '
$0 == "__CHAPTER_HTML__" {
  while ((getline line < chapter_file) > 0) {
    print line
  }
  close(chapter_file)
  next
}

{
  print
}
' "$template_html" > "$output_file"

echo "Created $output_file"
echo "Copied assets to $output_dir"