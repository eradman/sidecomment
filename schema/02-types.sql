CREATE DOMAIN host AS text
CHECK(
  VALUE ~ '^[0-9a-z][-.0-9a-z]+$'
);

CREATE DOMAIN shortkey AS char(11);
