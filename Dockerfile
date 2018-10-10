# florist/Dockerfile

FROM alpine
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL \
  org.label-schema.schema-version="1.0" \
  org.label-schema.build-date="${BUILD_DATE}" \
  org.label-schema.vcs-ref="${VCS_REF}" \
  org.label-schema.vcs-url="${VCS_URL}" \
  maintainer="Neil Roza <neil@rtr.ai>"
WORKDIR /tmp
RUN set -euvx \
  && apk --no-cache add \
    build-base \
    curl \
    expect \
    gettext \
    git \
    openssh-client \
    perl-xml-xpath \
    python \
    shadow \
  && curl -fsSLo get-pip.py https://bootstrap.pypa.io/get-pip.py \
  && python get-pip.py \
  && pip install bloom \
  && rosdep init
