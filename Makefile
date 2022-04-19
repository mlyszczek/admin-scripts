install:
	install -m755 crypto/crypto-open.init /etc/init.d/crypto-open
	install -m755 crypto/crypto-open.conf /etc/conf.d/crypto-open
	install -m755 bin/mbuffer-for-znapzend /usr/bofc/bin/mbuffer-for-znapzend
	install -m644 lib/utils.sh /usr/bofc/lib/utils.sh
