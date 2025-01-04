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
* Anonymous; only a valid email
* Rate limit email (per minute and per hour) to avoid abuse

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

Initialize database

    psql -f schema/roles.sql
    psql -c 'CREATE DATABASE sidecomment OWNER sidecomment;'
    for f in schema/??-*.sql; do
        psql -q -U sidecomment -f $f
    done
    psql -c 'ALTER USER sidecomment NOSUPERUSER;'

Optionally load test data

    psql -U sidecomment -f server_tests/data.sql

Archiving
---------

sidecomment.io preserves a little data as possible.  `cron` or the `pg_cron`
extension can be used to archive records and summarize results

    CALL prune_usercodes('30 days'::interval);
    CALL archive_tickets('30 days'::interval);

Development
-----------

To start a development environment in tmux(1)

    ./start-tmux-dev.sh

This create three windows

1. Edit and run unit tests
2. Development server with auto-reload
3. Database connection
