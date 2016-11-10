FROM debian:stable

RUN apt-get update && apt-get install curl xz-utils gcc libssl-dev libevent-dev -y
RUN curl -fsS https://dlang.org/install.sh | bash -s dmd

RUN mkdir -p /app/
WORKDIR /app
COPY ./ /app/

RUN . ~/dlang/dmd-*/activate && dub build

EXPOSE 8080

CMD ./lorem-songus-vibed-docker
