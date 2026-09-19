use schema FOOD_DELIVERY_DEV.SCH_STAGE;
list @CSV_STAGE;


-- check working of file
select
    $1 as LocationID,
    $2 as City,
    $3 as State,
    $4 as ZipCode,
    $5 as ActiveFlag,
    $6 as CreatedDate,
    $7 as ModifiedDate
from @FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/initial/location/location-5rows.csv
(file_format => FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT);

-- add audit columns for tracking and debugging
select
    $1 as LocationID,
    $2 as City,
    $3 as State,
    $4 as ZipCode,
    $5 as ActiveFlag,
    $6 as CreatedDate,
    $7 as ModifiedDate,

    -- audit cols
    metadata$filename as _stg_file_name,
    metadata$file_row_number as _stg_file_row_num,
    metadata$file_content_key as _stg_file_md5,
    metadata$file_last_modified as _stg_file_load_ts,
    -- metadata$start_scan_time as _stg_start_scan_time  -- when snowflake last touched the file
    
from @FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/initial/location/location-5rows.csv
(file_format => FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT);


-- Table creation

create table sch_stage.location (
    locationid text,
    city text,
    state text,
    zipcode text,
    activeflag text,
    createddate text,
    modifieddate text,
    -- audit columns for tracking & debugging
    _stg_file_name text,
    _stg_file_load_ts timestamp,
    _stg_file_md5 text,
    _copy_data_ts timestamp default current_timestamp
)
comment = 'This is the location stage/raw table where data will be copied from internal stage using copy command. This is as-is data represetation from the source location. All the columns are text data type except the audit columns that are added for traceability.'
;


-- Create Stream object
CREATE OR REPLACE STREAM location_stream
ON TABLE FOOD_DELIVERY_DEV.SCH_STAGE.LOCATION
    APPEND_ONLY = TRUE
    COMMENT = 'this is the append-only stream object on location table that gets delta data based on changes';


SELECT * FROM location_stream;

// COPY DATA INTO TABLE

COPY INTO FOOD_DELIVERY_DEV.SCH_STAGE.LOCATION (LOCATIONID, CITY, STATE, ZIPCODE, ACTIVEFLAG, CREATEDDATE, MODIFIEDDATE, _STG_FILE_NAME, _STG_FILE_LOAD_TS, _STG_FILE_MD5, _COPY_DATA_TS)
FROM (
    select
    $1 as LocationID,
    $2 as City,
    $3 as State,
    $4 as ZipCode,
    $5 as ActiveFlag,
    $6 as CreatedDate,
    $7 as ModifiedDate,

    -- audit cols
    metadata$filename as _stg_file_name,
    metadata$file_last_modified as _stg_file_load_ts,
    metadata$file_content_key as _stg_file_md5,
    current_timestamp as _copy_data_ts
    
from @FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/initial/location/location-5rows.csv
)
file_format = (format_name = FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT)
on_error = abort_statement;


select * from location;
select * from location_stream;
