FROM python:3.11.1-buster

ENV WORKDIR=/usr/src/CONTAINER_NAME
WORKDIR $WORKDIR

RUN pip install --upgrade pip && pip3 install wheel && pip3 install poetry

COPY ./pyproject.toml $WORKDIR
COPY ./poetry.lock $WORKDIR

RUN poetry install --no-root

COPY ./src $WORKDIR/src

CMD ["poetry", "run", "python3", "-m", "src"]
