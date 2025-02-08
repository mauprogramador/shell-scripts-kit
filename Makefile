-include .env
.PHONY: $(MAKECMDGOALS)

venv:
	@bash venv.sh
