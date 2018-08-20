FROM alpine:3.8 as builder
MAINTAINER Michel Oosterhof <michel@oosterhof.net>
RUN addgroup -S -g 1000 cowrie && \
    adduser -S -u 1000 -h /cowrie -s /bin/sh -G cowrie cowrie

# Set up Debian prereqs
RUN buildenv='libressl-dev libffi-dev' && \
    needtoSetup='musl-dev py3-pip python3-dev python3 gcc git py3-virtualenv' && \
    apk --no-cache add --update $needtoSetup $buildenv

# Build a cowrie environment from github master HEAD.
RUN su - cowrie -c "\
      git clone --separate-git-dir=/tmp/cowrie.git http://github.com/micheloosterhof/cowrie /cowrie/cowrie-git && \
        cd /cowrie && \
        virtualenv -p python3 cowrie-env && \
        . cowrie-env/bin/activate && \
        pip install --upgrade pip && \
        pip install --upgrade cffi && \
        pip install --upgrade setuptools && \
        pip install --upgrade -r /cowrie/cowrie-git/requirements.txt && \
        rm -r ~/.cache/pip"

FROM alpine:3.8
MAINTAINER Michel Oosterhof <michel@oosterhof.net>
RUN addgroup -S -g 1000 cowrie && \
    adduser -S -u 1000 -h /cowrie -G cowrie cowrie

RUN buildenv='libssl1.1 libffi6' && \
    needtoSetup='python3' && \
    apk --no-cache add --update $needtoSetup $buildenv

COPY --chown=cowrie:cowrie --from=builder /cowrie /cowrie

USER cowrie
WORKDIR /cowrie/cowrie-git
CMD [ "/cowrie/cowrie-git/bin/cowrie", "start", "-n" ]
EXPOSE 2222
