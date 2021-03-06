FROM python:2.7

RUN useradd --system --shell /bin/nologin reddit
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key 2CA8DFB7072DDEEDDF5410457E07BD4165506D27 
RUN echo "deb http://ppa.launchpad.net/reddit/ppa/ubuntu trusty main" >> /etc/apt/sources.list.d/reddit.list

RUN apt-get update && apt-get install -y \
netcat-openbsd \
python-dev \
python-setuptools \
python-routes \
python-pylons \
python-boto \
python-tz \
python-crypto \
python-babel \
cython \
python-sqlalchemy \
python-beautifulsoup \
python-chardet \
python-psycopg2 \
python-pycassa \
python-imaging \
python-pycaptcha \
python-amqplib \
python-pylibmc \
python-bcrypt \
python-snudown \
python-l2cs \
python-lxml \
python-zope.interface \
python-kazoo \
python-stripe \
python-tinycss2 \
python-unidecode \
python-mock \
python-yaml \
python-flask \
geoip-bin \
geoip-database \
python-geoip \
gettext \
make \
optipng \
jpegoptim \
postgresql-client \
gunicorn \
libpcre3-dev \
nginx \
unzip \

&& apt-get clean \
&& apt-get autoclean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV REDDIT_HOME /opt/rh

RUN mkdir -p "$REDDIT_HOME" \
RUN chown reddit:reddit "$REDDIT_HOME" \
RUN mkdir -p /srv/www/media && chown reddit:reddit /srv/www/media
RUN mkdir -p /var/log/nginx/traffic


RUN set -x \
    && curl -SL "https://github.com/reddit/reddit/archive/master.zip" -o reddit.zip \
    && unzip reddit.zip && mv reddit-master reddit \
    && curl -SL "https://github.com/reddit/reddit-i18n/archive/master.zip" -o i18n.zip \
    && unzip i18n.zip && mv reddit-i18n-master i18n \
    && rm -rf *.zip \
    && cd /reddit/r2/ \
    && python setup.py build \
    && python setup.py develop --no-deps \
    && make clean all \
    && cd "$REDDIT_HOME/i18n" \
    && python setup.py build \
    && python setup.py develop --no-deps \
    && make clean all

WORDIR /opt/rh/reddit

COPY development.update ./development.update
COPY ./click.conf /etc/gunicorn.d/click.conf
COPY ./geoip.conf /etc/gunicorn.d/geoip.conf
COPY ./reddit-all.conf /etc/nginx/sites-available/reddit

RUN make ini && ln -nsf development.ini run.ini \
    && rm -rf /etc/nginx/sites-enabled/default \
    && ln -nsf /etc/nginx/sites-available/reddit /etc/nginx/sites-enabled/ \
    && ln -nsf "$REDDIT_HOME/reddit/r2/development.ini" "$REDDIT_HOME/reddit/scripts/production.ini"

