#!/bin/bash
docker pull postgres
docker run --name beeinterns -p 5432:5432 --mount type=bind,source=$PWD/../../sde_test_db,target=/sde_test_db -e POSTGRES_PASSWORD="@sde_password012" -e POSTGRES_USER="test_sde" -e POSTGRES_DB="demo" -d postgres
sleep 5
docker exec -it beeinterns psql "postgresql://test_sde:%40sde_password012@localhost:5432/demo" -f /sde_test_db/sql/init_db/demo.sql

