-include .env
.PHONY: $(MAKECMDGOALS)

PORT ?= 8000
CONTAINER_NAME =

# Setup

venv:
	@bash venv.sh

install:
	@poetry install --no-root


# Run

run:
	@poetry run python3 -m src

docker:
	@docker build -q -t ${CONTAINER_NAME} .
	@docker run -d --env HOST=0.0.0.0 --env-file .env --name ${CONTAINER_NAME} -p ${PORT}:${PORT} ${CONTAINER_NAME}

# Format & Lint

format:
	@poetry run isort .
	@poetry run black .

lint:
	@poetry run isort src/ --check
	@poetry run black src/ --check
	@poetry run pylint src/
	@poetry run mypy src/
