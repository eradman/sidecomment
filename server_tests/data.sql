/*
  5c188e73-bbc8-4c1b-96c2-d4a195bd6cef - testing user interface
  7be302ad-726e-4471-832c-f6691b9b9335 - testing sitecode activation
 */
COPY sitecode (sitecode_id, email, domains, verified) FROM stdin;
5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	ericshane@eradman.com	{localhost,example.org,raticalsoftware.com}	t
7be302ad-726e-4471-832c-f6691b9b9335	ericshane@eradman.com	{localhost,example.org}	f
\.

/*
  hFNjWv2phA8 - testing insert/update
  4dEo73XK2T8 - testing select
  fmKmGEhDVxM - issue tracking
 */
COPY usercode (usercode_id, email, hostname, verified) FROM stdin;
hFNjWv2phA8	ericshane@eradman.com	raticalsoftware.com	f
4dEo73XK2T8	eradman@eradman.com	raticalsoftware.com	t
fmKmGEhDVxM	ericshane@eradman.com	raticalsoftware.com	f
\.

COPY tag (tag_id, name) FROM STDIN;
101	style-guide
102	typo-hawk
103	logician
104	editor-in-chief
105	title-titan
\.

COPY ticket (ticket_id, created, usercode_id, sitecode_id, url, base, selection, extent, comment_area, closed, tag_id) FROM stdin;
50	2021-08-07 20:05	4dEo73XK2T8	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	http://raticalsoftware.com/	Resume: 	HTML | PDF		Add TXT	\N	\N
51	2021-08-08 10:00	4dEo73XK2T8	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	http://raticalsoftware.com/	Resuem:	HTML | PDF		Add TXT	2021-08-08 10:10	102
\.
COPY ticket (ticket_id, created, usercode_id, sitecode_id, comment_area, topic) FROM stdin;
52	2021-08-09 12:02	fmKmGEhDVxM	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	How can I include external JS?	Wordpress Config
\.
ALTER SEQUENCE ticket_ticket_id_seq RESTART WITH 100;

COPY reply (reply_id, created, account_id, ticket_id, comment_area) FROM stdin;
20	2021-10-01 18:00	2	50	80 cols or 72?
21	2021-10-02 00:05	4	50	80 will print nicely
\.
ALTER SEQUENCE reply_reply_id_seq RESTART WITH 30;

/*
 * archive schema
 */

COPY archive.usercode (created, usercode_id, email, hostname) FROM stdin;
2021-06-28	IDIh2v2lSNg	ericshane@eradman.com	raticalsoftware.com
2021-06-29	hI5WNvizeH8	ericshane@eradman.com	raticalsoftware.com
\.

COPY archive.ticket (ticket_id, created, usercode_id, sitecode_id, url, closed, tag_id) FROM stdin;
40	2021-07-01 10:00	IDIh2v2lSNg	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	http://raticalsoftware.com/one.html	2021-07-01 13:00	103
41	2021-08-01 10:00	IDIh2v2lSNg	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	http://raticalsoftware.com/two.html	2021-07-01 13:00	103
42	2021-09-01 10:00	hI5WNvizeH8	5c188e73-bbc8-4c1b-96c2-d4a195bd6cef	http://raticalsoftware.com/three.html	2021-07-01 13:00	\N
\.

REFRESH MATERIALIZED VIEW archive_tag_summary ;

