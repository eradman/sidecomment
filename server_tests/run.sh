#!/bin/sh

trap 'printf "$0: exit code $? on line $LINENO\n" >&2; exit 1' ERR
cd $(dirname $0)

url=$(pg_tmp -o "-c shared_preload_libraries=pg_stat_statements")
psql="psql $url -v ON_ERROR_STOP=1 -q"
echo "Using ${url}"

openssl rand -base64 20 > .hmac_secret
ln -f .hmac_secret ../

$psql -f ../schema/roles.sql
for f in ../schema/??-*.sql; do
	$psql < $f
done

$psql -f data.sql
$psql -f mocks.sql
$psql -c 'CREATE DATABASE test_0 TEMPLATE test'


ruby=${RUBY:-ruby}
$ruby verify.rb
DATABASE_URL=${url} $ruby data.rb
DATABASE_URL=${url} $ruby main.rb
DATABASE_URL=${url} $ruby authorized.rb
