SELECT
    ind.id AS indicator_id,
    ind.identifier AS indicator_identifier,
    ind.name AS indicator_name,
    ind.description AS indicator_description,
    ind.keywords AS indicator_keywords,
    ind.status AS indicator_status,
    ind."quality-dimension" AS quality_dimension,
    ind."release-date" AS release_date,
    ind.version AS version,
    ind.doi AS doi,
    authors.name AS author_name,
    authors.email AS author_email,
    contacts.name AS contact_name,
    contacts.email AS contact_email,
    org.name AS organization_name,
    org.url AS organization_url
FROM
    indicators AS ind
LEFT JOIN person AS authors
    ON ind.authors_id = authors.id
LEFT JOIN person AS contacts
    ON ind.contacts_id = contacts.id
LEFT JOIN organization AS org
    ON authors.organization_id = org.id
ORDER BY
    ind.id;
