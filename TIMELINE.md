November 17, 2023
-----------------

> Publish as a Git repo

* Check in source code and publish to github.com
* Drop 'archive' make target

August 26, 2023
---------------

> Formatting

* Allow newlines to be displayed in replies

July 15, 2023
-------------

> Usability

* Set 'viewport' in meta tag for better navigation on small screens

May 27, 2023
------------

> Minor portablity

* Use ${RUBY} instead of 'ruby'

May 1, 2023
-----------

> Improve secret handling

* Adjustment rc.d startup for OpenBSD 7.3
* Generate random hmac secret when tests are run
* Investigate using preventDefualt to avoid extra menu on Edge 98

July 2, 2022
------------

> Neaten up

* Avoid displaying hint if ancestor has a `nav` element
* Clean up some jshint warnings

June 25, 2022
-------------

> First public announcement

* Publish journal entry "The Sidecomment Web Stack"

June 18, 2022
-------------

> First demo to non-family member

* Detect and disable if the user agent includes "Mobile"
* Demo sidecomment.io for Micah Lovell

June 11, 2022
-------------

> Tweak tags used to show the sidecomment hint

* Experiment with a notification queue instead of a flag for ticket open
* Add ol, ul, and table elements to the defaults list of hints
* Expanded bio page

June 4, 2022
------------

> Polish assorted bits of the UI

* Add customized bullets
* Note that a ticket link may be shared
* Replace use of for() with while() on client
* Use window Y offset when displaying hint
* Some jslint cleanups

May 28, 2022
------------

> Better organization around email notification

* Exempt 127.0.0.1 from email rate limits
* New API endpoint to format and email replies
* Correct local port for API calls, use AWK to add newlines
* Avoid string interpolation by passing arrays as parameters
* Separate rate-limit and archive-schema logic into separate files

May 21, 2022
------------

> Reply notification design

* New reply notification queue table maintained by a trigger
* Rename `notifiations` to `notify_log`
* Drop notification delay option

May 14, 2022
------------

> Basic health checks

* Run client tests in headless mode by default
* Ensure `hmac_secret` is in place for local dev server
* Split Chromium exception logging separate module
* Experiment with site checks using Ferrum, install simple HTTP fetch instead
* Rough in a journal entry titled "The Sidecomment Web Stack"

May 7, 2022
-----------

> Spiff up home page

* More complete bio on raticalsoftware.com
* A quick summary of what a usercode is for on the comment page
* Simplify page titles

April 30, 2022
--------------

> Updated OS and packages

* Add missing dependencies to INSTALL
* Switch from Ruby 3.0 to 3.1
* Upgrade VMs to OpenBSD 7.1 and PostgreSQL 14

April 23, 2022
--------------

> First steps on 7.1

* Update auto-install build to use OpenBSD 7.1

April 16, 2022
--------------

> Minor cleanups

* Avoid exception when selection size is zero
* Fix makefile for client build

April 9, 2022
-------------

> More context to parent site

* Start about page on raticalsoftware.com
* Move resume to eradman.com

April 2, 2022
-------------

> Registration is bot-resistant

* Ensure that usercode domain is of type host
* Disable email while I sort out defenses against bots
* Present validation errors on /comment and /install pages
* Use a less jarring color scheme for proxy errors
* Use DNS resolver for basic hostname validation
* Log email notifications and assert on minute and hourly rate limits

March 27, 2022
--------------

> Stronger visibility on database activity

* Incremental improvements to client tests
* Enable `pg_stat_statements` and a view of webui and system queries
* Lighten client tests using a separate script for server tests
* Set a maximum height for hint overlay

March 19, 2022
--------------

> Start the business case

* Add new /plans page (not visible yet)
* Allow notification interval to be specified in URL
* Invite Micah to provide consulting on initial release
* Add created and location fields to account table
* Transition from Unicorn to Puma and use phased-restart
* Return simple error string instead of Sinatra error HTML

March 12, 2022
--------------

> Improved recommendation for src include

* Refactor and conform to most of rubocop's rules
* Recommend using `//cdn` instead of `https://cdn`
* Review similarities with Hyvor Talk platform

March 5, 2022
-------------

> New layer of confidence with basic client tests

* Basic client integrate tests using Ferrum
* Better sidecomment-source archiving
* Ignore selections with have no width and height (input boxes)
* Eliminate relative date formatting
* Avoid duplicate entries in ticket open summary email

February 26, 2022
-----------------

> Improved notifications

* Install daily database backup to home storage
* Change close email subject to match open email
* Replaced wholeText with textContent
* Ignore selections with a rangeCount > 1
* Separate tag-and-close email for tickets and issues

February 19, 2022
-----------------

> Clean up namespace and more correct selections

* Customizable hints shown on right-side
* Rename global var `sidecomment_key` to `sidecomment_sitecode`
* Change comment area to use the term "usercode"
* Ensure most variables and functions are prefixed with 'sidecomment_'
* Account for page scroll offset when displaying '+'
* Use fixed positioning for comment div
* Move scripts to the bottom of pages to avoid reparse warnings
* Unify selection logic using getRangeAt(0)

February 12, 2022
-----------------

> Usability data correctness improvements

* Only add random numbers to username if name is not taken
* Reserve usernames in new data fixture
* Use format() in pg/psql functions instead of concatenation
* Avoid page reload after updating account details
* Reference replies by account ID
* Add logging configuration to postgres
* Ensure '+' isn't off the top of the screen

February 5, 2022
----------------

> More coherent account management

* Basic new ticket/issue email alert (deferred 30 min from last update)
* Cron job to send email notifications
* Delete replies when archiving tickets
* Record count of replies in archive.tickets
* Display email address in disabled form when logged in
* Add account column to reply table and link when adding comments
* Add 3-digit random number to new account username

January 29, 2022
----------------

> Selection tickets adapted to function as an issue tracker

* New /support page with top-level menu
* Tickets are dual purpose: user selection or issue
* Use Anonymous Pro to display usercodes
* Unset pointer-events in comment box
* Use paragraph instead of pre tag for selection and comment text
* Clean up database connections while running tests
* Add acme-client forward from relayd
* Offload static files to httpd

January 22, 2022
----------------

> Think about consulting leads

* Sketch out a consulting form
* Experiment with datetime field support
* Install italic and bold variations on Railway font
* Put font CSS in a separate file
* Add validation property to Comment Code field
* Resize comment div when window is resized

January 15, 2022
----------------

> User interface cleanup

* Send usercode verification link
* Automatically approve usercode if logged in
* Add "copy" link
* Allow usercode to be displayed before any tickets are created
* Procedure for pruening old, unverified usercodes

January 8, 2022
---------------

> Sepearate concerns and maintain minimal design language

* Formatted closed on date, display archive notice
* Include verification link in new sitecode email
* Remove Update Profile show/hide button on Account page
* Change notecard to a class, make each username a link
* Split Sitecodes from Account pages
* Reduce stylization of notecard div and put it at the top

January 1, 2021
---------------

> First use an a Wordpress site

* Set some ticket defaults in server, not javascript UI to save size
* Preserve newlines in selected textarea
* Reduce the selection delay from 1000ms to 500ms
* Make favicon
* Only allow tag-and-close from owner of a site code
* Show stats in Account Details
* Allow closing a ticket with an empty tag
* Show tickets with no replies

December 25, 2021
-----------------

> First use on an external site

* Fix race condition in tests
* Send email when ticket is closed
* Introduce a javascript variable for changing the official service url
* Enable cross-site resource sharing
* Sidecomment configured on http://raticalsoftware.com
* Minimal Firefox support

December 18, 2021
-----------------

> Ticket archive supporting and tag summary statistics

* Sum closed tags and display on notecard
* New an archive schmea
* Create a procedure for archiving tickets
* Tests for stored procedures
* Daily cron job for archiving tickets

December 11, 2021
-----------------

> Tag and close functionality

* Make new copy of the database for each test
* Tried setting the usercode to a 9-digit number `random()*(b-a)+a`
* Create an archive copy of the site under cdn/site/
* Add LICENSE file
* New tag table
* Display Open/Closed tickets separately
* Add tag-and-close / Done button
* Allow updating a tag once a ticket was closed

December 4, 2021
----------------

> Establish permissions model and relay errors

* Add webui role and associated permissions
* Add collapsible notecard on ticket page with account details
* More effective Haml: return values instead of using variable interpolation
* Display errors for ticket replies
* Use memoization to re-use database connections

November 27, 2021
-----------------

> Tidy up ticket/reply user interface

* Updates to extra account details works
* Move page-specific javascript into the header of each page
* Fix ordering on replies
* Set sequence numbers on initial data load
* Fix redundant escaping in replies
* Display usernames in ticket and replies
* Display timestamps for tickets, and age for replies
* Break schema into separate files and mock time in tests

November 20, 2021
-----------------

> Allow users to edit the domain list for each sitecode

* Use install page to update the list of domains
* Add tests to verify authorized requests
* Send email only in production mode
* Add account.username field
* sketch UI to editing account details

November 13, 2021
-----------------

> Usable user authentication and account summary page

* Add link from raticalsoftware.com under "Web Services"
* Test basic mail when registering for a sitecode
* One-time password using new account table
* Moved unicorn.rb to ratical/rset repo
* Enable cookies and JWT
* Account details page with links to ticket summary

November 6, 2021
----------------

> Self-hosted mail and DNS

* Add reverse DNS to VM
* Add relay1, MX to sidecomment.io
* Make relay1 an authoritative nameserver for sidecomment.io
* Add SPF record, request outbound permission from Vultr
* Basic PF rules on relay

October 30, 2021
----------------

> Automated VM provisioning, harden install

* Terraform config for Vultr
* Automatically rebuilt new VM using vultr startup script
* Rebuild server from scratch

October 23, 2021
----------------

> Adding a reply works

* Add missing dependency to README
* Update dev and VM to OpenBSD 7.0
* Some disambiguation of namespaces
* Able to reply individually to each ticket
* Format replies in ticket view
* Highlight fade for new replies
* Change quoted test to preformatted area
* Stronger assertions in server tests

October 16, 2021
----------------

> Adding a reply almost works

* Submit form for adding a reply
* Tweaks to ticket formatting

October 9, 2021
---------------

> First steps to adding commentary on a ticket

* Add reply table to schema

October 2, 2021
---------------

> One "account", multiple domains/subdomains

* Allow a list of domains to be registered
* Require domain names to be composed of valid characters

September 25, 2021
------------------

> Validation and better errors

* Link `sitecode_id` to each ticket
* Require the sitecode key to match the site hostname
* Basic error reporting to UI when submitting a ticket

September 4, 2021
-----------------

> Stronger database schema

* Make "Comment" the first menu item
* Add registration form to Install page
* Generate 11-character shortcode as a default column value
* Unify primary key naming `tablename_id`

August 28, 2021
---------------

> Starting to look professional

* Neaten up user interface

August 21, 2021
---------------

> First time comment interface appears to work

* Submit button and check status link
* Store `comment_area` text on submit
* Rename `comment` table to `ticket`
* Send selection context
* Run sidecomment web app from `rc.d/unicorn`
* Make the color scheme less crude

August 14, 2021
---------------

> Token authorization scheme

* Generate YouTube style random string in database using `pg-sortkey`
* Some refactoring of javascript

August 7, 2021
--------------

> First appearance of a business presence

* Rough in a homepages for raticalsoftware.com
* Set payment information on Vultr
* Add menus and footers to sidecomment.io
* Business cards ordered for raticalsoftware.com

July 31, 2021
-------------

> First infrastructure up

* Tried many things to get ruby fcgi working, settled on unicorn instead
* Brought up sidecomment.io up and running with httpd and relayd as a reverse
  proxy

July 24, 2021
-------------

> First infrastructure up

* Register sidecomment.io, raticalsoftware.com
* Opened dedicated businees bank account

July 17, 2021
-------------

> Architecture choices

* Researched other languages such as Nim
* Quick trial of Express.js
* Decided that Ruby is the answer because of HAML


July 10, 2021
-------------

> Proof of concept

* record selected text and provide in a global
* Display a form on the right for typing into
* provide a popup for starting a new comment
* First swipe at a database schema
