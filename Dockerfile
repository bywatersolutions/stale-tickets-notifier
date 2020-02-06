FROM alpine

WORKDIR /app

# Copy all files to workdir
COPY . .

RUN apk add --no-cache \
      gcc \
      musl-dev \
      perl \
      perl-app-cpanminus \
      perl-dev \
      perl-net-ssleay \
      wget \
      make

RUN cpanm --notest --installdeps . && rm -rf /root/.cpanm

CMD ./stale-tickets-notifier.pl
