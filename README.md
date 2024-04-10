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

Runtime: ruby postgresql-server
Test: ephemeralpg chromium node

Installation
------------

    bundle install
    npm install

Database Initialization
-----------------------

Reset everything

    dropdb sidecomment

Initialize database

    psql -f schema/roles.sql
    psql -c 'CREATE DATABASE sidecomment OWNER sidecomment;'
    psql -c 'ALTER USER sidecomment SUPERUSER;'
    for f in schema/??-*.sql; do
        psql -q -U sidecomment -f $f
    done
    psql -c 'ALTER USER sidecomment NOSUPERUSER;'

Optionally load test data

    psql -U sidecomment -f server_tests/data.sql

History
-------

See [TIMELINE.md](TIMELINE.md) for the history of this project.

Source code for `sidecomment.io` is licensed under an ISC-style license.
Copyright 2021 Eric Radman / Ratical Software.
