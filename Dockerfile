FROM debian:12

ENV RPI_BUILD_INSIDE_DOCKER=1

COPY --chmod=755 utils/provision-debian.sh /root/provision-debian.sh
RUN /root/provision-debian.sh

ARG BUILDER_UID
ARG BUILDER_GID
RUN groupadd -g "${BUILDER_GID}" builder && \
    useradd -l -m -u "${BUILDER_UID}" -g "${BUILDER_GID}" builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder
USER builder

COPY . /src
WORKDIR /src

ENTRYPOINT [ "/src/utils/docker-entrypoint.sh" ]

