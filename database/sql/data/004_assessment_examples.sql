
SET search_path TO api, public;

BEGIN;

DELETE FROM assessment_raw WHERE payload->>'@id' LIKE 'urn:dashverse:seed:%';


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:cffinit-2025q3",
    "name": "Quality Assessment for CFFinit v2.3.1",
    "description": "Automated quality assessment using the howfairis and rsfc toolchain.",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-09-15T10:30:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.3.1",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": { "@id": "https://doi.org/10.5281/zenodo.8224012" }
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "true",
            "evidence": "Project has a README.md and a docs/ directory."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "true",
            "evidence": "tests/ folder present with cypress configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_releases" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" },
            "process": "Queries the repository host API for tagged releases.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "true",
            "evidence": "Repository has 14 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "false",
            "evidence": "No workflow configuration found."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata" },
            "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": { "@id": "schema:CompletedActionStatus" },
            "output": "false",
            "evidence": "No codemeta.json found."
        }
    ]
}
$$::jsonb, '2025-09-15T10:30:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:cffinit-2025q4",
    "name": "Quality Assessment for CFFinit v2.4.0",
    "description": "Follow-up assessment after release of v2.4.0.",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-12-10T14:18:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.4.0",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": { "@id": "https://doi.org/10.5281/zenodo.8224012" }
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" }, "process": "Validates the CITATION.cff file in the repository root against the CFF schema.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "valid", "evidence": "Found valid CITATION.cff file in repository root." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Inspects the repository for README or docs/ folder content.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Project has a README.md and a docs/ directory." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "tests/ folder present with cypress configuration." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_releases" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Queries the repository host API for tagged releases.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository has 16 tagged releases." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 2 workflows under .github/workflows/." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for codemeta.json or similar descriptive metadata files.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "false", "evidence": "No codemeta.json found." }
    ]
}
$$::jsonb, '2025-12-10T14:18:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:cffinit-2026q1",
    "name": "Quality Assessment for CFFinit v2.5.0",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2026-03-05T09:42:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.5.0",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": { "@id": "https://doi.org/10.5281/zenodo.8224012" }
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" }, "process": "Validates the CITATION.cff file in the repository root against the CFF schema.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "valid", "evidence": "Found valid CITATION.cff file in repository root." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Inspects the repository for README or docs/ folder content.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Project has a README.md and a docs/ directory." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "tests/ folder present with cypress configuration." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_releases" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Queries the repository host API for tagged releases.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository has 18 tagged releases." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 3 workflows under .github/workflows/." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for codemeta.json or similar descriptive metadata files.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found codemeta.json with 12 properties." }
    ]
}
$$::jsonb, '2026-03-05T09:42:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:howfairis-2025q4",
    "name": "Quality Assessment for howfairis v0.14.2",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-12-12T11:05:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "howfairis",
        "softwareVersion": "0.14.2",
        "url": "https://github.com/fair-software/howfairis"
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" }, "process": "Validates the CITATION.cff file in the repository root against the CFF schema.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "valid", "evidence": "Found valid CITATION.cff file in repository root." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found tests/ with pytest configuration." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_releases" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Queries the repository host API for tagged releases.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository has 22 tagged releases." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 4 workflows under .github/workflows/." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/version_control_use" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for a hosted git repository.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository hosted on GitHub." }
    ]
}
$$::jsonb, '2025-12-12T11:05:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:pyani-2025q3",
    "name": "Quality Assessment for PyANI v0.2.13",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-09-22T15:48:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "PyANI",
        "softwareVersion": "0.2.13",
        "url": "https://github.com/widdowquinn/pyani"
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" }, "process": "Validates the CITATION.cff file in the repository root against the CFF schema.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "valid", "evidence": "Found valid CITATION.cff file in repository root." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Inspects the repository for README or docs/ folder content.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "false", "evidence": "README.md exists but docs/ directory is empty." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found tests/ with pytest configuration." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "false", "evidence": "No workflow configuration found." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for codemeta.json or similar descriptive metadata files.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "false", "evidence": "No codemeta.json found." }
    ]
}
$$::jsonb, '2025-09-22T15:48:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:pyani-2025q4",
    "name": "Quality Assessment for PyANI v0.2.14",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-12-20T16:33:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "PyANI",
        "softwareVersion": "0.2.14",
        "url": "https://github.com/widdowquinn/pyani"
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_citation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "cffconvert", "@id": "https://w3id.org/everse/tools/cffconvert", "softwareVersion": "2.0.0" }, "process": "Validates the CITATION.cff file in the repository root against the CFF schema.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "valid", "evidence": "Found valid CITATION.cff file in repository root." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Inspects the repository for README or docs/ folder content.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Project has README.md and docs/ folder with API reference." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found tests/ with pytest configuration." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 1 workflow under .github/workflows/." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for codemeta.json or similar descriptive metadata files.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "false", "evidence": "No codemeta.json found." }
    ]
}
$$::jsonb, '2025-12-20T16:33:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:apptainer-2025q4",
    "name": "Quality Assessment for Apptainer v1.3.0",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2025-12-08T13:11:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "Apptainer",
        "softwareVersion": "1.3.0",
        "url": "https://github.com/apptainer/apptainer"
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "howfairis", "@id": "https://w3id.org/everse/tools/howfairis", "softwareVersion": "0.14.2" }, "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found license file: 'LICENSE.md'." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_documentation" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Inspects the repository for README or docs/ folder content.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Project has README and rendered docs at apptainer.org." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_tests" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Looks for a test directory or known test framework configuration.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found e2e/ test suite in Go." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_releases" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Queries the repository host API for tagged releases.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository has more than 30 tagged releases." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 6 workflows under .github/workflows/." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/version_control_use" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for a hosted git repository.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Repository hosted on GitHub." }
    ]
}
$$::jsonb, '2025-12-08T13:11:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "@id": "urn:dashverse:seed:scorecard-2026q1",
    "name": "Quality Assessment for OpenSSF Scorecard v5.1.1",
    "creator": {
        "@type": "schema:Person",
        "name": "Faruk Diblen",
        "email": "f.diblen@esciencecenter.nl"
    },
    "dateCreated": "2026-03-12T10:55:00Z",
    "version": "1.0",
    "license": { "@id": "https://creativecommons.org/publicdomain/zero/1.0/" },
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "OpenSSF Scorecard",
        "softwareVersion": "5.1.1",
        "url": "https://github.com/ossf/scorecard"
    },
    "checks": [
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/software_has_license" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "OpenSSF Scorecard", "@id": "https://github.com/ossf/scorecard", "softwareVersion": "5.1.1" }, "process": "Checks for a license file recognised by SPDX.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found Apache-2.0 license." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/has_published_package" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "OpenSSF Scorecard", "@id": "https://github.com/ossf/scorecard", "softwareVersion": "5.1.1" }, "process": "Checks if the project is published as a package.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Available as a GitHub Action and a Docker image." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/human_code_review_requirement" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "OpenSSF Scorecard", "@id": "https://github.com/ossf/scorecard", "softwareVersion": "5.1.1" }, "process": "Checks if the repository requires reviews on pull requests.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Branch protection requires at least 1 reviewer." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "OpenSSF Scorecard", "@id": "https://github.com/ossf/scorecard", "softwareVersion": "5.1.1" }, "process": "Checks for known critical vulnerabilities in dependencies.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "No critical advisories at the time of check." },
        { "@type": "CheckResult", "assessesIndicator": { "@id": "https://w3id.org/everse/i/indicators/repository_workflows" }, "checkingSoftware": { "@type": "schema:SoftwareApplication", "name": "RSFC", "@id": "https://w3id.org/everse/tools/rsfc", "softwareVersion": "0.1.1" }, "process": "Checks for CI configuration under .github/workflows or equivalent.", "status": { "@id": "schema:CompletedActionStatus" }, "output": "true", "evidence": "Found 14 workflows under .github/workflows/." }
    ]
}
$$::jsonb, '2026-03-12T10:55:00+00:00');

COMMIT;
