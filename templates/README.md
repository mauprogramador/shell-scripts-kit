# PROJECT_NAME

<p align="center">
  <em>PROJECT_DESCRIPTION</em>
</p>
<p align="center">
  <a href="https://github.com/mauprogramador/ifms-dev-competition/releases/latest" target="_blank" rel="external" title="Latest Release">
    <img src="https://img.shields.io/github/v/tag/mauprogramador/ifms-dev-competition?logo=github&label=Release&color=E9711C" alt="Latest Release">
  </a>
  <a href="https://www.python.org/" target="_blank" rel="external" title="Python3 Version">
    <img src="https://img.shields.io/badge/Python-v3.11-FBDA4E?logo=python&logoColor=FFF&labelColor=3776AB" alt="Python3 Version">
  </a>
  <a href="https://fastapi.tiangolo.com/" target="_blank" rel="external" title="FastAPI">
    <img src="https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=FFF" alt="FastAPI">
  </a>
  <a href="https://docs.pydantic.dev/latest/" target="_blank" rel="external" title="Pydantic">
    <img src="https://img.shields.io/badge/Pydantic-E92063?logo=pydantic&logoColor=FFF" alt="Pydantic">
  </a>
  <a href="https://black.readthedocs.io/en/stable/" target="_blank" rel="external" title="Black">
    <img src="https://img.shields.io/badge/Black-000?logo=readthedocs&logoColor=FFF" alt="Black">
  </a>
</p>

---

**PROJECT_URL**: <a href="http://127.0.0.1:8000/" target="_blank" rel="external" title="Swagger UI">http://127.0.0.1:8000/</a>

---

## Overview

PROJECT_OVERVIEW

---

## Configuration

You can create an `.env` file to configure the following options:

| **Parameter**   | **Description**                                            | **Default**   |
| --------------- | ---------------------------------------------------------- | ------------- |
| `database_file` | Sets the database file (*.db*) absolute path               | `database.db` |
| `host`          | Sets the host address to listen on                         | `127.0.0.1`   |
| `port`          | Sets the server port on which the application will run     | `8000`        |
| `reload`        | Enable auto-reload on file changes for local development   | `false`       |
| `workers`       | Sets multiple worker processes                             | `1`           |
| `logging_file`  | Enable saving logs to files                                | `false`       |
| `debug`         | Enable the debug mode and debug logs                       | `false`       |

- The `reload` and `workers` options are **mutually exclusive**.

- Setting the `host` to `0.0.0.0` makes the application externally available.

- Set the `database_file` like `/home/user/project/repository/database.db`.

- Database backup files will be saved inside the `/repository` directory.

Take a look at the [`.env.example`](./.env.example) file.

---

## Run locally

You will need <a href="https://www.python.org/downloads/release/python-3117/" target="_blank" rel="external" title="Python3.11">Python3 `v3.11`</a> with <a href="https://pip.pypa.io/en/stable/installation/" target="_blank" rel="external" title="Pip">Pip</a> and <a href="https://docs.python.org/3/library/venv.html" target="_blank" rel="external" title="Pip">Venv</a> installed.

```bash
# Create new Venv
make venv

# Activate Venv
source .venv/bin/activate

# Install dependencies with Poetry
(.venv) make install

# Install dependencies with Pip
(.venv) pip3 install -r requirements.txt

# Run the API locally
(.venv) make run
```

## Run in Docker

You will need <a href="https://www.docker.com/" target="_blank" rel="external" title="Docker">Docker</a> installed.

```bash
# Run the App in Docker Container
make docker
```

---

This project is licensed under the terms of the [MIT license](./LICENSE)
