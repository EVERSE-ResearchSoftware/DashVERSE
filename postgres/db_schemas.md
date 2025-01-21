# Database schemas for the EVERSE dashboard

## indicators

```sql
Table person {
  id integer [primary key]
  name VARCHAR
  orcid VARCHAR
  github VARCHAR
  gitlab VARCHAR
  email VARCHAR
  affiliation VARCHAR
  "image-url" VARCHAR
}

Table organization {
  id integer [primary key]
  name VARCHAR
  url VARCHAR
  "image-url" VARCHAR
}

Table indicators {
  id integer [primary key]
  identifier VARCHAR
  name VARCHAR
  description VARCHAR
  keywords VARCHAR[] UNIQUE
  status VARCHAR
  "quality-dimension" VARCHAR[]
  "release-date" date
  version VARCHAR
  doi VARCHAR
  authors int [ref: > person.id]
  contacts int [ref: > person.id]
  organizations int [ref: > organization.id]
}
```
