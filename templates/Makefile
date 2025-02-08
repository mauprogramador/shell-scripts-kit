-include .env
.PHONY: $(MAKECMDGOALS)

PORT ?= 8000


# Environment setup

venv:
	@bash venv.sh

install:
	@poetry install --no-root


# Run application

run:
	@poetry run python3 -m src

docker:
	@docker build -q -t CONTAINER_NAME .
	@docker run -d --env HOST=0.0.0.0 --env-file .env --name CONTAINER_NAME -p ${PORT}:${PORT} CONTAINER_NAME

# Formatting and Linting

format:
	@poetry run isort .
	@poetry run black .

lint:
	@poetry run isort src/ --check
	@poetry run black src/ --check
	@poetry run pylint src/
	@poetry run mypy src/
