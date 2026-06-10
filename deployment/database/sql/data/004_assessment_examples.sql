
SET search_path TO api, public;

BEGIN;

DELETE FROM assessment_raw WHERE payload->'author'->>'email' LIKE '%@dashverse-seed.local';


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.3.1",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.8224012"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Alice Hartmann",
        "email": "alice.hartmann@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Project has a README.md and a docs/ directory."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "tests/ folder present with cypress configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Queries the repository host API for tagged releases.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository has 14 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No workflow configuration found."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No codemeta.json found."
        }
    ],
    "dateCreated": "2025-09-15T10:30:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-09-15T10:30:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.4.0",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.8224012"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Bram Vermeulen",
        "email": "bram.vermeulen@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Project has a README.md and a docs/ directory."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "tests/ folder present with cypress configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Queries the repository host API for tagged releases.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository has 16 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 2 workflows under .github/workflows/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No codemeta.json found."
        }
    ],
    "dateCreated": "2025-12-10T14:18:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-12-10T14:18:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.5.0",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.8224012"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Caterina Lopez",
        "email": "caterina.lopez@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Project has a README.md and a docs/ directory."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "tests/ folder present with cypress configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Queries the repository host API for tagged releases.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository has 18 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 3 workflows under .github/workflows/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found codemeta.json with 12 properties."
        }
    ],
    "dateCreated": "2026-03-05T09:42:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2026-03-05T09:42:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "howfairis",
        "softwareVersion": "0.14.2",
        "url": "https://github.com/fair-software/howfairis"
    },
    "author": {
        "@type": "schema:Person",
        "name": "Daniel Okonkwo",
        "email": "daniel.okonkwo@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found tests/ with pytest configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Queries the repository host API for tagged releases.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository has 22 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 4 workflows under .github/workflows/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/version_control_use"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for a hosted git repository.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository hosted on GitHub."
        }
    ],
    "dateCreated": "2025-12-12T11:05:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-12-12T11:05:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "PyANI",
        "softwareVersion": "0.2.13",
        "url": "https://github.com/widdowquinn/pyani"
    },
    "author": {
        "@type": "schema:Person",
        "name": "Elena Petrova",
        "email": "elena.petrova@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "README.md exists but docs/ directory is empty."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found tests/ with pytest configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No workflow configuration found."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No codemeta.json found."
        }
    ],
    "dateCreated": "2025-09-22T15:48:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-09-22T15:48:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "PyANI",
        "softwareVersion": "0.2.14",
        "url": "https://github.com/widdowquinn/pyani"
    },
    "author": {
        "@type": "schema:Person",
        "name": "Farhan Bakir",
        "email": "farhan.bakir@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validates the CITATION.cff file in the repository root against the CFF schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "Found valid CITATION.cff file in repository root."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Project has README.md and docs/ folder with API reference."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found tests/ with pytest configuration."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 1 workflow under .github/workflows/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/descriptive_metadata"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for codemeta.json or similar descriptive metadata files.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No codemeta.json found."
        }
    ],
    "dateCreated": "2025-12-20T16:33:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-12-20T16:33:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "Apptainer",
        "softwareVersion": "1.3.0",
        "url": "https://github.com/apptainer/apptainer"
    },
    "author": {
        "@type": "schema:Person",
        "name": "Greta Sigurdsson",
        "email": "greta.sigurdsson@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "Searches for a file named 'LICENSE' or 'LICENSE.md' in the repository root.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found license file: 'LICENSE.md'."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Inspects the repository for README or docs/ folder content.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Project has README and rendered docs at apptainer.org."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Looks for a test directory or known test framework configuration.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found e2e/ test suite in Go."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Queries the repository host API for tagged releases.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository has more than 30 tagged releases."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 6 workflows under .github/workflows/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/version_control_use"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for a hosted git repository.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Repository hosted on GitHub."
        }
    ],
    "dateCreated": "2025-12-08T13:11:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2025-12-08T13:11:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "OpenSSF Scorecard",
        "softwareVersion": "5.1.1",
        "url": "https://github.com/ossf/scorecard"
    },
    "author": {
        "@type": "schema:Person",
        "name": "Hiro Tanaka",
        "email": "hiro.tanaka@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Checks for a license file recognised by SPDX.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found Apache-2.0 license."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_published_package"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Checks if the project is published as a package.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Available as a GitHub Action and a Docker image."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/human_code_review_requirement"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Checks if the repository requires reviews on pull requests.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Branch protection requires at least 1 reviewer."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Checks for known critical vulnerabilities in dependencies.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "No critical advisories at the time of check."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Checks for CI configuration under .github/workflows or equivalent.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found 14 workflows under .github/workflows/."
        }
    ],
    "dateCreated": "2026-03-12T10:55:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2026-03-12T10:55:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "CFFinit",
        "softwareVersion": "2.6.0",
        "url": "https://github.com/citation-file-format/cff-initializer-javascript",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.8224012"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Inga Mariotti",
        "email": "inga.mariotti@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License file detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Apache-2.0 LICENSE present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Validate CITATION.cff schema.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff valid against schema 1.2.0."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Detect a tests directory.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Found e2e and unit suites."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Check release tags.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Latest tag v2.6.0."
        }
    ],
    "dateCreated": "2026-05-01T08:14:00Z",
    "license": {
        "@id": "https://creativecommons.org/publicdomain/zero/1.0/"
    }
}
$$::jsonb, '2026-05-01T08:14:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "Apptainer",
        "softwareVersion": "1.4.0",
        "url": "https://github.com/apptainer/apptainer",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.10202687"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Jonas Pereira",
        "email": "jonas.pereira@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "License recognition.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "BSD-3-Clause license present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Check for docs/.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Sphinx docs at docs/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Vulnerability scan.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Two open Go module advisories."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Release detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Stable release cadence."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI config detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GitHub Actions workflows present."
        }
    ],
    "dateCreated": "2026-04-12T11:08:00Z",
    "license": {
        "@id": "https://opensource.org/license/BSD-3-clause"
    }
}
$$::jsonb, '2026-04-12T11:08:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "howfairis",
        "softwareVersion": "0.15.0",
        "url": "https://github.com/fair-software/howfairis",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.4017851"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Kira Adesanya",
        "email": "kira.adesanya@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.15.0"
            },
            "process": "License recognition.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Apache-2.0 license file."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "CITATION.cff validation.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff is valid."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_published_package"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Check for published package.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Available on PyPI."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/version_control_use"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "VCS detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Hosted on GitHub."
        }
    ],
    "dateCreated": "2026-03-08T15:24:00Z",
    "license": {
        "@id": "https://www.apache.org/licenses/LICENSE-2.0"
    }
}
$$::jsonb, '2026-03-08T15:24:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "OpenSSF Scorecard",
        "softwareVersion": "5.2.0",
        "url": "https://github.com/ossf/scorecard",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.13839041"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Lukas Kovacic",
        "email": "lukas.kovacic@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Apache-2.0."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "CVE scan.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "No critical CVEs."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/human_code_review_requirement"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Branch protection check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Required reviews enforced."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Workflows detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Multiple GitHub Actions workflows."
        }
    ],
    "dateCreated": "2026-02-22T13:42:00Z",
    "license": {
        "@id": "https://www.apache.org/licenses/LICENSE-2.0"
    }
}
$$::jsonb, '2026-02-22T13:42:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "ProjectAlpha",
        "softwareVersion": "1.0.0",
        "url": "https://example.org/projectalpha",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990001"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Mira Chowdhury",
        "email": "mira.chowdhury@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT license file present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Citation file check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No CITATION.cff found."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No tests/ directory."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "README.md present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Release tag check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Tag v1.0.0 exists."
        }
    ],
    "dateCreated": "2025-10-15T09:36:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2025-10-15T09:36:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "ProjectAlpha",
        "softwareVersion": "1.2.0",
        "url": "https://example.org/projectalpha",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990001"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Niko Rasmussen",
        "email": "niko.rasmussen@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT license."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "CFF validation.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff added and valid."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests directory.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "tests/ directory now present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "README plus docs/ folder."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI workflow detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No GitHub Actions configured yet."
        }
    ],
    "dateCreated": "2026-01-08T14:11:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2026-01-08T14:11:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "ProjectAlpha",
        "softwareVersion": "2.0.0",
        "url": "https://example.org/projectalpha",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990001"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Olga Mihaylova",
        "email": "olga.mihaylova@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT license."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "CFF validation.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff valid."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Tests with 78% coverage."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GitHub Actions workflow present."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_published_package"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Package publication check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Published on PyPI."
        }
    ],
    "dateCreated": "2026-04-20T10:48:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2026-04-20T10:48:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "SimuLab",
        "softwareVersion": "0.5.0",
        "url": "https://example.org/simulab",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990002"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Pierre Lefebvre",
        "email": "pierre.lefebvre@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GPL-3.0 license."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Citation check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Missing CITATION.cff."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Basic pytest suite."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Release tags.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No tagged releases yet."
        }
    ],
    "dateCreated": "2025-11-22T16:09:00Z",
    "license": {
        "@id": "https://www.gnu.org/licenses/gpl-3.0.html"
    }
}
$$::jsonb, '2025-11-22T16:09:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "SimuLab",
        "softwareVersion": "0.6.0",
        "url": "https://example.org/simulab",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990002"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Quynh Vu",
        "email": "quynh.vu@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GPL-3.0 file."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Pytest suite expanded."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Release tags.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Tag v0.6.0 created."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Only README.md, no docs/ folder."
        }
    ],
    "dateCreated": "2026-02-14T09:52:00Z",
    "license": {
        "@id": "https://www.gnu.org/licenses/gpl-3.0.html"
    }
}
$$::jsonb, '2026-02-14T09:52:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "SimuLab",
        "softwareVersion": "0.7.0",
        "url": "https://example.org/simulab",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990002"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Rafael Becker",
        "email": "rafael.becker@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GPL-3.0."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Citation check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff added."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MkDocs site under docs/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "GitHub Actions."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Vulnerability scan.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "No advisories."
        }
    ],
    "dateCreated": "2026-04-05T07:33:00Z",
    "license": {
        "@id": "https://www.gnu.org/licenses/gpl-3.0.html"
    }
}
$$::jsonb, '2026-04-05T07:33:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "DataPipe",
        "softwareVersion": "3.1.0",
        "url": "https://example.org/datapipe",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990003"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Sanne van der Berg",
        "email": "sanne.vanderberg@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "BSD-3-Clause."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Sphinx docs."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/version_control_use"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "VCS detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Git on GitLab."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_published_package"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Package check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Not on PyPI."
        }
    ],
    "dateCreated": "2025-09-30T11:24:00Z",
    "license": {
        "@id": "https://opensource.org/license/BSD-3-clause"
    }
}
$$::jsonb, '2025-09-30T11:24:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "DataPipe",
        "softwareVersion": "3.2.0",
        "url": "https://example.org/datapipe",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990003"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Takeshi Mori",
        "email": "takeshi.mori@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "BSD-3-Clause."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Citation check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff valid."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Tests cover 65% of lines."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_published_package"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Package check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Now published on PyPI."
        }
    ],
    "dateCreated": "2026-01-25T13:18:00Z",
    "license": {
        "@id": "https://opensource.org/license/BSD-3-clause"
    }
}
$$::jsonb, '2026-01-25T13:18:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "DataPipe",
        "softwareVersion": "3.3.0",
        "url": "https://example.org/datapipe",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990003"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Ursula Kovacs",
        "email": "ursula.kovacs@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "BSD-3-Clause."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Coverage at 72%."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Multiple GitHub Actions workflows."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/human_code_review_requirement"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Branch protection check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Main branch allows direct pushes by maintainers."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/no_critical_vulnerability"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.2.0"
            },
            "process": "Vulnerability scan.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "No critical CVEs."
        }
    ],
    "dateCreated": "2026-03-18T08:56:00Z",
    "license": {
        "@id": "https://opensource.org/license/BSD-3-clause"
    }
}
$$::jsonb, '2026-03-18T08:56:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "TerraGen",
        "softwareVersion": "0.9.0",
        "url": "https://example.org/terragen",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990004"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Victor Ngata",
        "email": "victor.ngata@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.2"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT license."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Only README, no docs/ tree."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "No tests/ folder."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/version_control_use"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.1"
            },
            "process": "VCS check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Hosted on GitHub."
        }
    ],
    "dateCreated": "2025-10-08T15:42:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2025-10-08T15:42:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "TerraGen",
        "softwareVersion": "1.0.0",
        "url": "https://example.org/terragen",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990004"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Wei Zhao",
        "email": "wei.zhao@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_citation"
            },
            "checkingSoftware": {
                "name": "cffconvert",
                "version": "2.0.0"
            },
            "process": "Citation check.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "valid",
            "evidence": "CITATION.cff added for v1.0."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Pytest suite, 58% coverage."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/has_releases"
            },
            "checkingSoftware": {
                "name": "OpenSSF Scorecard",
                "version": "5.1.1"
            },
            "process": "Release tags.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "v1.0.0 tagged."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "false",
            "evidence": "Only one workflow, lacking lint or test runs."
        }
    ],
    "dateCreated": "2026-02-28T10:21:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2026-02-28T10:21:00+00:00');


INSERT INTO assessment_raw (payload, created_at) VALUES
($$
{
    "@context": "https://w3id.org/everse/rsqa/0.0.1/",
    "@type": "SoftwareQualityAssessment",
    "assessedSoftware": {
        "@type": "schema:SoftwareApplication",
        "name": "TerraGen",
        "softwareVersion": "1.1.0",
        "url": "https://example.org/terragen",
        "schema:identifier": {
            "@id": "https://doi.org/10.5281/zenodo.99990004"
        }
    },
    "author": {
        "@type": "schema:Person",
        "name": "Xochitl Reyes",
        "email": "xochitl.reyes@dashverse-seed.local"
    },
    "checks": [
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_license"
            },
            "checkingSoftware": {
                "name": "howfairis",
                "version": "0.14.4"
            },
            "process": "License detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MIT."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_documentation"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Docs detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "MkDocs site at docs/."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/software_has_tests"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "Tests detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Coverage now 71%."
        },
        {
            "@type": "CheckResult",
            "assessesIndicator": {
                "@id": "https://w3id.org/everse/i/indicators/repository_workflows"
            },
            "checkingSoftware": {
                "name": "RSFC",
                "version": "0.1.2"
            },
            "process": "CI detection.",
            "status": {
                "@id": "schema:CompletedActionStatus"
            },
            "output": "true",
            "evidence": "Test, lint and release workflows."
        }
    ],
    "dateCreated": "2026-04-25T12:39:00Z",
    "license": {
        "@id": "https://opensource.org/license/MIT"
    }
}
$$::jsonb, '2026-04-25T12:39:00+00:00');


COMMIT;
