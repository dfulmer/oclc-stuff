# aim-oclc-xrefs
A commandline utility for taking a file of OCLC cross reference updates and
using it to update records in Alma.

## Setting up aim-oclc-xrefs

Clone the repo

```
git clone https://github.com/mlibrary/aim-oclc-xrefs.git
cd aim-oclc-xrefs
```

run the `init.sh` script to set up your environment, build the docker image, and
install the python packages
```
./init.sh
```

edit .env with actual environment variables

## Running the script
```
docker compose run --rm app poetry run python ./process.py --help
```

## Running tests

```
docker-compose run --rm app poetry run pytest
```

## Background

![Cross-refs-2](https://github.com/dfulmer/oclc-stuff/assets/18075253/8e0fa876-36ff-4ac8-b38a-950e98660a37)