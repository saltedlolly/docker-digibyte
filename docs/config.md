digibyted config tuning
======================

You can use environment variables to customize config ([see docker run environment options](https://docs.docker.com/engine/reference/run/#/env-environment-variables)):

        docker run -v digibyte-data:/digibyte/.digibyte --name=digibyte-node -d \
            -p 12024:12024 \
            -p 127.0.0.1:14022:14022 \
            -e REGTEST=0 \
            -e DISABLEWALLET=1 \
            -e PRINTTOCONSOLE=1 \
            -e RPCUSER=mysecretrpcuser \
            -e RPCPASSWORD=mysecretrpcpassword \
            saltedlolly/digibyte

Or you can use your very own config file like that:

        docker run -v digibyte-data:/digibyte/.digibyte --name=digibyte-node -d \
            -p 12024:12024 \
            -p 127.0.0.1:14022:14022 \
            -v /etc/mydigibyte.conf:/digibyte/.digibyte/digibyte.conf \
            saltedlolly/digibyte
