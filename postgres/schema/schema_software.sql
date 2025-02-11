-- https://github.com/EVERSE-ResearchSoftware/schemas/tree/main/quality_indicators

CREATE SEQUENCE IF NOT EXISTS software_id_seq;

CREATE TABLE IF NOT EXISTS software (

  url text NOT NULL,
  isAccessibleForFree boolean NULL,
  hasQualityDimension text CHECK
        (
            "hasQualityDimension" IN(
                'FAIRness'
            )
        ) NULL,
  howToUse text CHECK
        (
            "howToUse" IN(
                'CI/CD',
                'command-line'
            )
        ) NULL,
  license text
);
