FROM perl

WORKDIR /app

# Copy all files to workdir
COPY . .

RUN cpanm --installdeps . 

CMD ./stale-tickets-notifier.pl
