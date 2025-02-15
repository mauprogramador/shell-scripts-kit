import DEPENDENCIES  # pylint: disable=w0611 # noqa: F401
import uvicorn

from src.core.config import APP, ENV, HEADERS, LOG

if __name__ == "__main__":

    LOG.info("\033[33mPROJECT_NAME initialized 🚀")
    LOG.debug(ENV.model_dump())

    uvicorn.run(
        app=APP,
        host=ENV.host,
        port=ENV.port,
        reload=ENV.reload,
        workers=ENV.workers,
        access_log=False,
        server_header=True,
        date_header=True,
        timeout_graceful_shutdown=5,
        headers=HEADERS,
        use_colors=True,
    )
