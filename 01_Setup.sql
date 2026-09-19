USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS DEV_FOOD_WH
    COMMENT = 'This warehouse is for purpose of food delivery Project'
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

    -- ENABLE_QUERY_ACCELERATION = FALSE       -- extra resource when required = NO
    -- MIN_CLUSTER_COUNT = 1                   -- min num of cluster to keep
    -- MAX_CLUSTER_COUNT = 1                   -- max num of cluster to keep
    -- SCALING_POLICY = 'STANDARD'             -- aggressive scaling when needed. USELESS here as max cluster is 1

USE WAREHOUSE DEV_FOOD_WH;

---------------------------------------------

CREATE DATABASE FOOD_DELIVERY_DEV;
USE DATABASE FOOD_DELIVERY_DEV;

CREATE SCHEMA IF NOT EXISTS SCH_STAGE;
CREATE SCHEMA IF NOT EXISTS SCH_CLEAN;
CREATE SCHEMA IF NOT EXISTS SCH_CONSUMPTION;
CREATE SCHEMA IF NOT EXISTS SCH_COMMON;

------------------------------------------------------------------

USE SCHEMA SCH_STAGE;

CREATE FILE FORMAT IF NOT EXISTS FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT
    TYPE = 'CSV'                            
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('', 'NULL', '\\N')
    COMPRESSION = 'AUTO'                -- DATA MAYBE COMPRESSIOD IN gz, bz2, zst formats
;


CREATE STAGE FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE
    DIRECTORY = (ENABLE = TRUE)                 --ENABLES file visibility , file tracking, metadata inspection
    COMMENT = 'STAGE TO LOAD ALL THE CSV DATA';

-------------------------------------------------------------------



USE SCHEMA FOOD_DELIVERY_DEV.SCH_COMMON;

CREATE OR REPLACE TAG FOOD_DELIVERY_DEV.SCH_COMMON.PII_POLICY_TAG
    ALLOWED_VALUES 'PII', 'PRICE', 'SENSITIVE','EMAIL'
    COMMENT = 'This is PII policy tag object';

CREATE OR REPLACE MASKING POLICY 
    FOOD_DELIVERY_DEV.SCH_COMMON.PII_MASKING_POLICY AS (PII_TEXT STRING)
    RETURNS STRING ->
        TO_VARCHAR('**PII**');
        
CREATE OR REPLACE MASKING POLICY 
    FOOD_DELIVERY_DEV.SCH_COMMON.email_masking_policy AS (EMAIL_TEXT STRING)
    RETURNS STRING ->
        TO_VARCHAR('**EMAIL**');
        
CREATE OR REPLACE MASKING POLICY 
    FOOD_DELIVERY_DEV.SCH_COMMON.phone_masking_policy  AS (PHONE STRING)
    RETURNS STRING ->
        TO_VARCHAR('**PHONE**');

SHOW TAGS ;
SHOW MASKING POLICIES ;