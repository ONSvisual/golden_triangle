# docker osrm

[https://docs.docker.com/desktop/mac](https://docs.docker.com/desktop/mac)

### Great Britain

cd /Users/henrypartridge/Documents/docker/osrm

wget http://download.geofabrik.de/europe/great-britain-latest.osm.pbf

docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/great-britain-latest.osm.pbf

docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-partition /data/great-britain-latest.osrm

docker run -t -v "${PWD}:/data" osrm/osrm-backend osrm-customize /data/great-britain-latest.osrm

### Run server

docker run -t -i -p 5000:5000 -v "${PWD}:/data" osrm/osrm-backend osrm-routed --algorithm mld /data/great-britain-latest.osrm

