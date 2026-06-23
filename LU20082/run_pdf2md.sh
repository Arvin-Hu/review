#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────
# run_pdf2md.sh — Batch convert PDFs in this directory to Markdown
#                 using the pdf2md tool (MinerU cloud API).
#
# Usage:
#   bash run_pdf2md.sh              # Process all PDFs
#   bash run_pdf2md.sh --dry-run    # Preview what would be processed
#   bash run_pdf2md.sh --force      # Force re-process all files
#   bash run_pdf2md.sh --reset-failed  # Retry failed files
#
# Output will be placed in: ./LU20082_md/
# ──────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDF2MD_DIR="/home/yyh/workspace/code/pdf2md"
INPUT_DIR="$SCRIPT_DIR"
OUTPUT_DIR="${INPUT_DIR}_md"
VENV_DIR="$PDF2MD_DIR/.venv"

echo "============================================================"
echo "  pdf2md — Batch PDF-to-Markdown via MinerU Cloud API"
echo "============================================================"
echo ""
echo "  Input directory:  $INPUT_DIR"
echo "  Output directory: $OUTPUT_DIR"
echo "  pdf2md path:      $PDF2MD_DIR"
echo ""

# ── 1. Set up Python virtual environment ────────────────────────
if [ -d "$VENV_DIR" ]; then
    echo "[1/3] Activating existing virtual environment..."
else
    echo "[1/3] Creating virtual environment at $VENV_DIR ..."
    /usr/bin/python3 -m venv "$VENV_DIR"
    echo "[1/3] Installing pdf2md and dependencies..."
    source "$VENV_DIR/bin/activate"
    pip install --quiet -e "$PDF2MD_DIR"
    echo "[1/3] Installation complete."
fi

source "$VENV_DIR/bin/activate"

# ── 2. Verify setup ─────────────────────────────────────────────
echo "[2/3] Verifying setup..."
python3 -c "import pdf2md; print(f'  pdf2md version: {pdf2md.__version__}')"

# Count PDF files in input directory (non-recursive)
PDF_COUNT=$(find "$INPUT_DIR" -maxdepth 1 -name "*.pdf" -o -name "*.PDF" 2>/dev/null | wc -l)
echo "  PDF files found in input directory: $PDF_COUNT"

if [ "$PDF_COUNT" -eq 0 ]; then
    echo ""
    echo "Warning: No PDF files found in $INPUT_DIR"
    echo "The tool will still scan recursively in case PDFs are in subdirectories."
fi
echo ""

# ── 3. Run pdf2md ───────────────────────────────────────────────
echo "[3/3] Running pdf2md..."
echo ""

# Pass through any additional arguments (e.g. --dry-run, --force, --reset-failed)
cd "$PDF2MD_DIR"
python3 -m pdf2md --input-dir "$INPUT_DIR" "$@"

EXIT_CODE=$?
echo ""
echo "============================================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo "  SUCCESS — All PDFs processed successfully."
else
    echo "  DONE with errors (exit code: $EXIT_CODE)."
    echo "  Some files may have failed — check the output above."
    echo "  You can retry failed files with: bash $0 --reset-failed"
fi
echo "  Output saved to: $OUTPUT_DIR"
echo "============================================================"

exit $EXIT_CODE
