#!/bin/bash

if [ "$1" = "dev" ] || [ "$1" = "prod" ]; then
  rover supergraph compose --config "./supergraph-$1.yaml" >schema.graphql
else
  printf "You must supply dev or prod as arguments to the script\n"
fi
