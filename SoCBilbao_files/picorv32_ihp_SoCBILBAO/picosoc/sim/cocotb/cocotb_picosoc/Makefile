.PHONY: test test_view help clean formal

SHELL := /bin/bash
SIM ?= questa
PYTEST_ARGS ?= -o log_cli=True --log-cli-level=INFO --html=report.html --self-contained-html -s -p no:xdist
NUM_CORES ?= 1
# NUM_TESTS := $(shell source .venv/bin/activate && pytest --collect-only | grep "<Function\|<Class" -c)
# NUM_RUNS := $(shell echo $$(( $(NUM_CORES) > $(NUM_TESTS) ? $(NUM_TESTS) : $(NUM_CORES) )))
NUM_RUNS := $(NUM_CORES)
PYTHON := python3

.DEFAULT_GOAL := help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


.venv:
	@echo "Setting up virtual environment..."
	@$(PYTHON) -m venv .venv

requirements: requirements.txt .venv
	@echo "Installing requirements..."
	@source .venv/bin/activate && pip install -r $< && touch $@

test: requirements ## Run pytest without waveform generation
	@echo "Running pytest..."
	@source .venv/bin/activate && SIM=$(SIM) pytest $(PYTEST_ARGS) test/
	
test_view: requirements ## Run pytest with waveform generation
	@echo "Running pytest with waveform viewer..."
	@source .venv/bin/activate && WAVES=1 SIM=$(SIM) pytest $(PYTEST_ARGS) test/ -n $(NUM_RUNS)

clean:
	@echo "Cleaning up..."
	@rm -rf .venv
	@rm -rf __pycache__
	@rm -rf .pytest_cache
	@rm -f report.html
	@rm -f .coverage
	@rm -f requirements
	@rm -rf sim_build_test
	@rm -rf sim_build_test_*
