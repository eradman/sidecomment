Sources for sidecomment.io
==========================

_Select Text, Submit Comments_

Design Goals
------------

Constraints

* Minimal overhead to page load times
* Must not conflict with namespaces
* Must cooperate with each site's CSS
* No local storage or cookies

Authorization

* Lazy signup, no password
* Anonymous; only a valid e-mail
* Rate limit e-mail (per minute and per hour) to avoid abuse

Requirements
------------

Runtime

* Packages: ruby postgresql-server
* Gems: sinatra sinatra-contrib haml pg puma jwt net-smtp

Test

* Packages: ephemeralpg chromium node
* Gems: minitest minitest-utils rack-test ferrum rubocop puma nokogiri
* Node: jshint

Database Initialization
-----------------------

Reset everything

    dropdb -U postgres sidecomment

Initialize database

    psql -U postgres -f schema/roles.sql
    psql -U postgres -c 'CREATE DATABASE sidecomment OWNER sidecomment;'
    psql -U postgres -c 'ALTER USER sidecomment SUPERUSER;'
    for f in schema/??-*.sql; do
        psql -q -U sidecomment < $f
    done
    psql -U postgres -c 'ALTER USER sidecomment NOSUPERUSER;'

Optionally load test data

    psql -U sidecomment < server_tests/data.sql

History
-------

See [TIMELINE.md](TIMELINE.md) for the history of this project.

Source code for `sidecomment.io` is licensed under an ISC-style license.
Copyright 2021 Eric Radman / Ratical Software.
