FROM farscapian/bcm-base:latest
RUN apt-get -y install squid

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 3128
EXPOSE 3129
EXPOSE 3130
ENTRYPOINT [ "/entrypoint.sh" ]




# RUN apt-get -y install devscripts build-essential fakeroot debhelper dh-autoreconf cdbs
# RUN apt-get install -y libcppunit-dev \
#     libsasl2-dev \
#     libxml2-dev \
#     libkrb5-dev \
#     libdb-dev \
#     libnetfilter-conntrack-dev \
#     libexpat1-dev \
#     libcap2-dev \
#     libldap2-dev \
#     libpam0g-dev \
#     libgnutls28-dev \
#     libssl-dev \
#     libdbi-perl \
#     libecap3 \
#     libecap3-dev
# RUN apt-get install wget -y

# RUN mkdir -p /squid
# WORKDIR /squid

# ADD squid.ver /squid/squid.ver
# ADD rules.patch /squid/rules.patch
# ADD squid_build.sh /squid/squid_build.sh
# RUN chmod +x /squid/squid_build.sh
# RUN bash -c "./squid_build.sh"