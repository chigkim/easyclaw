FROM ghcr.io/openclaw/openclaw:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV PLAYWRIGHT_BROWSERS_PATH=/home/node/.cache/ms-playwright

COPY scripts/build.sh /build.sh
RUN sed -i 's/\r$//' /build.sh && chmod +x /build.sh && /build.sh

COPY scripts/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

USER node
RUN uvx markitdown-mcp --help
