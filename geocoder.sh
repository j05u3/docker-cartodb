cd /cartodb

bundle exec rake cartodb:db:create_user --trace SUBDOMAIN="geocoder" \
	PASSWORD="pass1234" ADMIN_PASSWORD="pass1234" \
	EMAIL="geocoder@example.com"

# # Update your quota to 100GB
echo "--- Updating quota to 100GB"
bundle exec rake cartodb:db:set_user_quota[geocoder,102400]

# # Allow unlimited tables to be created
echo "--- Allowing unlimited tables creation"
bundle exec rake cartodb:db:set_unlimited_table_quota[geocoder]

GEOCODER_DB=`echo "SELECT database_name FROM users WHERE username='geocoder'" | psql -U postgres -t carto_db_production`
psql -U postgres $GEOCODER_DB < /cartodb/script/geocoder_server.sql

# Setup dataservices client
# prod user
USER_DB=`echo "SELECT database_name FROM users WHERE username='admin'" | psql -U postgres -t carto_db_production`
echo "CREATE EXTENSION cdb_dataservices_client;" | psql -U postgres $USER_DB
echo "SELECT CDB_Conf_SetConf('user_config', '{"'"is_organization"'": false, "'"entity_name"'": "'"admin"'"}');" | psql -U postgres $USER_DB
echo -e "SELECT CDB_Conf_SetConf('geocoder_server_config', '{ \"connection_str\": \"host=localhost port=5432 dbname=${GEOCODER_DB# } user=postgres\"}');" | psql -U postgres $USER_DB
bundle exec rake cartodb:services:set_user_quota['dev',geocoding,100000]

