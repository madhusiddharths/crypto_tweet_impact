# =============================================================================
# Makefile - common project tasks
# =============================================================================
# Usage:
#   make deps        Install R package dependencies
#   make report      Render the analysis to a self-contained HTML report
#   make dashboard   Launch the interactive Shiny dashboard
#   make reports-pdf Compile the LaTeX proposal + phase-2 report to PDF
#   make clean       Remove generated build artifacts
# =============================================================================

.PHONY: deps report dashboard reports-pdf clean

deps:
	Rscript scripts/install_dependencies.R

report:
	quarto render analysis/data_analysis.qmd --to html
	@echo "Report written to analysis/data_analysis.html"

dashboard:
	Rscript -e "shiny::runApp('dashboard', launch.browser = TRUE)"

reports-pdf:
	cd docs && pdflatex phase1_proposal.tex && pdflatex phase2_report.tex
	@echo "PDFs written alongside the .tex sources in docs/"

clean:
	rm -rf analysis/.quarto analysis/data_analysis_files analysis/data_analysis.html
	rm -f docs/*.aux docs/*.log docs/*.out docs/*.synctex.gz
	@echo "Cleaned build artifacts."
