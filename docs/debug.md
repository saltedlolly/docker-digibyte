# Debugging

## Things to Check

* RAM utilization -- digibyted is very hungry and typically needs in excess of 4GB.  A swap file might be necessary.
* Disk utilization -- The digibyte blockchain will continue growing and growing and growing.  Then it will grow some more.  At the time of writing, 40GB+ is necessary.

## Viewing bitcoind Logs

    docker logs digibyte-node


## Running Bash in Docker Container

*Note:* This container will be run in the same way as the bitcoind node, but will not connect to already running containers or processes.

    docker run -v digibyte-data:/digibyte --rm -it saltedlolly/digibyte bash -l

You can also attach bash into running container to debug running bitcoind

    docker exec -it digibyte-node bash -l


