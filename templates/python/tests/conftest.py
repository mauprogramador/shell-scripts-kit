from pytest import fixture


@fixture(scope="session")
def session_data():
    data = {"code": "None"}
    yield data


@fixture(scope="session", autouse=True)
def lifespan():
    print("\033[93mPytest Session Start\033[m", flush=True)

    yield

    print("\033[93mPytest Session Finish\033[m", flush=True)
