FROM node:8

RUN apt-get -qq update \
	&& apt-get install apt-utils --assume-yes

RUN apt-get install zip --assume-yes

RUN apt-get install curl --assume-yes

RUN apt-get install ruby-dev --assume-yes \
	&& apt-get install rubygems --assume-yes \
	&& gem update --system \
	&& gem install sass --pre \
	&& gem install compass --pre \
	&& gem install compass-rgbapng \
	&& gem install animation --pre

RUN npm -g install typings --silent \
	&& npm -g install grunt-cli \
	&& npm -g install bower \
	&& npm -g install vue-cli

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash

CMD ["node"]