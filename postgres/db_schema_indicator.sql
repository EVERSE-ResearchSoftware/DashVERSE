
CREATE SEQUENCE IF NOT EXISTS indicators_id_seq;

CREATE TABLE IF NOT EXISTS indicators (
  id bigint NOT NULL PRIMARY KEY DEFAULT nextval('indicators_id_seq'),
  identifier text NOT NULL UNIQUE,
  name text NOT NULL,
  description text NOT NULL,
  keywords text UNIQUE CHECK
        (
            "keywords" IN(
                'keyword-1',
                'keyword-2',
                'keyword-3'
            )
        ) NULL,
  status text CHECK
        ("status" IN('active', 'deprecated')) NOT NULL,
  "quality-dimension" text CHECK
        (
            "quality-dimension" IN(
                'openness',
                'FAIRness',
                'sustainability'
            )
        ) NOT NULL,
  "release-date" date,
  version text,
  doi text,
  authors_id bigint,
  contacts_id bigint
);

CREATE SEQUENCE IF NOT EXISTS person_id_seq;

CREATE TABLE IF NOT EXISTS person (
  id bigint NOT NULL PRIMARY KEY DEFAULT nextval('person_id_seq'),
  name text NOT NULL UNIQUE,
  orcid text,
  github text,
  gitlab text,
  email text NOT NULL,
  affiliation text,
  "image-url" text,
  organization_id bigint
);

CREATE SEQUENCE IF NOT EXISTS organization_id_seq;

CREATE TABLE IF NOT EXISTS organization (
  id bigint NOT NULL PRIMARY KEY DEFAULT nextval('organization_id_seq'),
  name text NOT NULL,
  url text NOT NULL,
  "image-url" text
);

ALTER TABLE indicators ADD CONSTRAINT indicators_authors_fk FOREIGN KEY (authors_id) REFERENCES person (id);
ALTER TABLE indicators ADD CONSTRAINT indicators_contacts_fk FOREIGN KEY (contacts_id) REFERENCES person (id);
ALTER TABLE person ADD CONSTRAINT person_organization_fk FOREIGN KEY (organization_id) REFERENCES organization (id);
