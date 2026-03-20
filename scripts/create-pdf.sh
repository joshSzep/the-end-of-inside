#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
manuscript_script="$script_dir/create-manuscript.sh"
input_file="$repo_root/The End of Inside.md"
cover_file="$repo_root/cover.png"
output_file="$repo_root/The End of Inside.pdf"
temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/the-end-of-inside-pdf.XXXXXX")"
processed_md="$temp_dir/manuscript-for-pdf.md"
header_tex="$temp_dir/pdf-style.tex"

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

for command_name in pandoc pdflatex; do
  require_command "$command_name"
done

for required_file in "$manuscript_script" "$cover_file"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

bash "$manuscript_script"

if [[ ! -f "$input_file" ]]; then
  echo "Failed to generate manuscript: $input_file" >&2
  exit 1
fi

cat > "$header_tex" <<'EOF'
\usepackage[paperwidth=6in,paperheight=9in,inner=0.9in,outer=0.7in,top=0.8in,bottom=0.85in]{geometry}
\usepackage{mathpazo}
\usepackage{microtype}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{titlesec}
\usepackage{fancyhdr}
\usepackage{emptypage}
\usepackage{eso-pic}

\definecolor{Accent}{HTML}{B98B69}

\setlength{\parindent}{1.2em}
\setlength{\parskip}{0pt}
\setlength{\footskip}{0.45in}
\linespread{1.04}\selectfont
\setcounter{secnumdepth}{-1}
\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000
\emergencystretch=2em
\raggedbottom

\pagestyle{fancy}
\fancyhf{}
\fancyfoot[C]{\small\thepage}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0pt}

\fancypagestyle{plain}{
  \fancyhf{}
  \renewcommand{\headrulewidth}{0pt}
  \renewcommand{\footrulewidth}{0pt}
}

\titleformat{\chapter}[display]
  {\normalfont\centering}
  {}
  {0pt}
  {\vspace*{0.14\textheight}\Huge\scshape}
  [\vspace{1.1ex}{\color{Accent}\rule{0.18\textwidth}{0.5pt}}]

\titlespacing*{\chapter}{0pt}{0pt}{2.75\baselineskip}
EOF

cat > "$processed_md" <<EOF



\`\`\`{=latex}
\AddToShipoutPictureBG*{%
  \AtPageLowerLeft{\includegraphics[width=\paperwidth,height=\paperheight]{$cover_file}}%
}
\thispagestyle{empty}
\null
\clearpage
\`\`\`

EOF

awk '
function print_act_page(title, is_first_act) {
  print "```{=latex}"
  if (!is_first_act) {
    print "\\clearpage"
  }
  print "\\thispagestyle{empty}"
  print "\\vspace*{\\fill}"
  print "\\begin{center}"
  print "{\\Huge\\scshape " title "}"
  print "\\end{center}"
  print "\\vspace*{\\fill}"
  print "\\clearpage"
  if (is_first_act) {
    print "\\pagenumbering{arabic}"
    print "\\setcounter{page}{1}"
  }
  print "```"
  print ""
}

BEGIN {
  first_act = 1
}

NR == 1 && $0 ~ /^# / {
  next
}

NR == 2 && $0 == "" {
  next
}

NR == 3 && $0 == "A Novel by Joshua Szepietowski" {
  next
}

NR == 4 && $0 == "" {
  next
}

$0 ~ /^## / {
  print_act_page(substr($0, 4), first_act)
  first_act = 0
  next
}

$0 ~ /^### / {
  print "# " substr($0, 5)
  next
}

{
  print
}
' "$input_file" >> "$processed_md"

pandoc "$processed_md" \
  --from=markdown+raw_tex+raw_attribute \
  --standalone \
  --pdf-engine=pdflatex \
  --include-in-header="$header_tex" \
  --resource-path="$repo_root" \
  --top-level-division=chapter \
  --variable=documentclass:book \
  --variable=classoption:oneside \
  --variable=classoption:openany \
  --pdf-engine-opt=-interaction=nonstopmode \
  --pdf-engine-opt=-halt-on-error \
  -o "$output_file"

echo "Created $output_file"