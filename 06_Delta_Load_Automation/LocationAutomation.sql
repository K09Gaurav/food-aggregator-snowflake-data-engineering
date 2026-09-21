USE DATABASE FOOD_DELIVERY_DEV;
USE ROLE SYSADMIN;
USE WAREHOUSE DEV_FOOD_WH;
USE SCHEMA SCH_COMMON;

-- Since i am using snowsight to upload files (Donot have a storage account on aws/azure/gcp)
-- I need to refresh pipe everytime i upload a file.

LIST@FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/delta/location/day1_2;

SELECT
    t.$1::text as LocationID,
    t.$2::text as City,
    t.$3::text as State,
    t.$4::text as ZipCode,
    t.$5::text as ActiveFlag,
    t.$6::text as CreatedDate,
    t.$7::text as ModifiedDate,
    -- audit cols
    metadata$filename as _stg_file_name,
    metadata$file_last_modified as _stg_file_load_ts,
    metadata$file_content_key as _stg_file_md5,
    current_timestamp as _copy_data_ts

FROM 
    @FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/delta/location/day1_2 
(file_format => FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT) t;



CREATE OR REPLACE PIPE LOCATION_PIPE 
COMMENT = 'Pipe to Automatically ingest data into stage location table from stage'
AS 
COPY INTO FOOD_DELIVERY_DEV.SCH_STAGE.LOCATION (LOCATIONID, CITY, STATE, ZIPCODE, ACTIVEFLAG, CREATEDDATE, MODIFIEDDATE, _STG_FILE_NAME, _STG_FILE_LOAD_TS, _STG_FILE_MD5, _COPY_DATA_TS)
FROM (
    SELECT
        t.$1::text as LocationID,
        t.$2::text as City,
        t.$3::text as State,
        t.$4::text as ZipCode,
        t.$5::text as ActiveFlag,
        t.$6::text as CreatedDate,
        t.$7::text as ModifiedDate,
        -- audit cols
        metadata$filename as _stg_file_name,
        metadata$file_last_modified as _stg_file_load_ts,
        metadata$file_content_key as _stg_file_md5,
        current_timestamp as _copy_data_ts

    FROM @FOOD_DELIVERY_DEV.SCH_STAGE.CSV_STAGE/delta/location/day1_2 t
)
file_format = (format_name = FOOD_DELIVERY_DEV.SCH_STAGE.CSV_FILE_FORMAT);

show pipes;
-- SELECT SYSTEM$PIPE_STATUS('LOCATION_PIPE');

alter pipe location_pipe refresh;

select * from sch_stage.location;
select * from sch_stage.location_stream;


-- Pipe stuff is done
-- SO initial ingestion is automated just have to refresh the pipe to do the load
-- next step have to create tasks on the condition of stream having data so that will also be automated
-- to make sure tasks do that we have to make sure the tasks are calling to the merge operation as a stored procedure
-- so convert all the merge operations as stored procedure

create or replace procedure sp_merge_to_location_clean()
RETURNS STRING
LANGUAGE SQL
AS 
$$
BEGIN

MERGE INTO sch_clean.restaurant_location AS target
USING (
    SELECT
        CAST(LOCATIONID AS NUMBER) AS LOCATION_ID,
        CAST(CITY AS STRING) AS CITY,
        CASE
            WHEN CAST(STATE AS STRING) = 'Delhi' THEN 'New Delhi'
            ELSE CAST(STATE AS STRING)
        END AS STATE,
        CAST(ZIPCODE AS STRING) AS ZIP_CODE,
        CASE 
            WHEN State = 'Delhi' THEN 'DL'
            WHEN State = 'Maharashtra' THEN 'MH'
            WHEN State = 'Uttar Pradesh' THEN 'UP'
            WHEN State = 'Gujarat' THEN 'GJ'
            WHEN State = 'Rajasthan' THEN 'RJ'
            WHEN State = 'Kerala' THEN 'KL'
            WHEN State = 'Punjab' THEN 'PB'
            WHEN State = 'Karnataka' THEN 'KA'
            WHEN State = 'Madhya Pradesh' THEN 'MP'
            WHEN State = 'Odisha' THEN 'OR'
            WHEN State = 'Chandigarh' THEN 'CH'
            WHEN State = 'West Bengal' THEN 'WB'
            WHEN State = 'Sikkim' THEN 'SK'
            WHEN State = 'Andhra Pradesh' THEN 'AP'
            WHEN State = 'Assam' THEN 'AS'
            WHEN State = 'Jammu and Kashmir' THEN 'JK'
            WHEN State = 'Puducherry' THEN 'PY'
            WHEN State = 'Uttarakhand' THEN 'UK'
            WHEN State = 'Himachal Pradesh' THEN 'HP'
            WHEN State = 'Tamil Nadu' THEN 'TN'
            WHEN State = 'Goa' THEN 'GA'
            WHEN State = 'Telangana' THEN 'TG'
            WHEN State = 'Chhattisgarh' THEN 'CG'
            WHEN State = 'Jharkhand' THEN 'JH'
            WHEN State = 'Bihar' THEN 'BR'
            ELSE NULL
        END AS STATE_CODE,
        CASE 
            WHEN State IN ('Delhi', 'Chandigarh', 'Puducherry', 'Jammu and Kashmir') THEN 'Y'
            ELSE 'N'
        END AS is_union_territory,
        CASE 
            WHEN (State = 'Delhi' OR City = 'New Delhi') THEN TRUE
            WHEN (State = 'Maharashtra' AND City = 'Mumbai') THEN TRUE
            -- Remaining States
            WHEN (State = 'Andhra Pradesh' AND City = 'Amaravati') THEN TRUE
            WHEN (State = 'Arunachal Pradesh' AND City = 'Itanagar') THEN TRUE
            WHEN (State = 'Assam' AND City = 'Dispur') THEN TRUE
            WHEN (State = 'Bihar' AND City = 'Patna') THEN TRUE
            WHEN (State = 'Chhattisgarh' AND City = 'Raipur') THEN TRUE
            WHEN (State = 'Goa' AND City = 'Panaji') THEN TRUE
            WHEN (State = 'Gujarat' AND City = 'Gandhinagar') THEN TRUE
            WHEN (State = 'Haryana' AND City = 'Chandigarh') THEN TRUE
            WHEN (State = 'Himachal Pradesh' AND City = 'Shimla') THEN TRUE
            WHEN (State = 'Jharkhand' AND City = 'Ranchi') THEN TRUE
            WHEN (State = 'Karnataka' AND City = 'Bengaluru') THEN TRUE
            WHEN (State = 'Kerala' AND City = 'Thiruvananthapuram') THEN TRUE
            WHEN (State = 'Madhya Pradesh' AND City = 'Bhopal') THEN TRUE
            WHEN (State = 'Manipur' AND City = 'Imphal') THEN TRUE
            WHEN (State = 'Meghalaya' AND City = 'Shillong') THEN TRUE
            WHEN (State = 'Mizoram' AND City = 'Aizawl') THEN TRUE
            WHEN (State = 'Nagaland' AND City = 'Kohima') THEN TRUE
            WHEN (State = 'Odisha' AND City = 'Bhubaneswar') THEN TRUE
            WHEN (State = 'Punjab' AND City = 'Chandigarh') THEN TRUE
            WHEN (State = 'Rajasthan' AND City = 'Jaipur') THEN TRUE
            WHEN (State = 'Sikkim' AND City = 'Gangtok') THEN TRUE
            WHEN (State = 'Tamil Nadu' AND City = 'Chennai') THEN TRUE
            WHEN (State = 'Telangana' AND City = 'Hyderabad') THEN TRUE
            WHEN (State = 'Tripura' AND City = 'Agartala') THEN TRUE
            WHEN (State = 'Uttar Pradesh' AND City = 'Lucknow') THEN TRUE
            WHEN (State = 'Uttarakhand' AND City = 'Dehradun') THEN TRUE
            WHEN (State = 'West Bengal' AND City = 'Kolkata') THEN TRUE
            -- Remaining Union Territories
            WHEN (State = 'Andaman and Nicobar Islands' AND City = 'Sri Vijaya Puram') THEN TRUE -- Formerly Port Blair
            WHEN (State = 'Chandigarh' AND City = 'Chandigarh') THEN TRUE
            WHEN (State = 'Dadra and Nagar Haveli and Daman and Diu' AND City = 'Daman') THEN TRUE
            WHEN (State = 'Jammu and Kashmir' AND City = 'Srinagar') THEN TRUE -- Summer Capital
            WHEN (State = 'Jammu and Kashmir' AND City = 'Jammu') THEN TRUE    -- Winter Capital
            WHEN (State = 'Ladakh' AND City = 'Leh') THEN TRUE
            WHEN (State = 'Lakshadweep' AND City = 'Kavaratti') THEN TRUE
            WHEN (State = 'Puducherry' AND City = 'Puducherry') THEN TRUE
            ELSE FALSE
        END AS CAPITAL_CITY_FLAG,
        CASE 
            WHEN City IN ('Mumbai', 'Delhi', 'Bengaluru', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune', 'Ahmedabad') THEN 'Tier-1'
            WHEN City IN ('Jaipur', 'Lucknow', 'Kanpur', 'Nagpur', 'Indore', 'Bhopal', 'Patna', 'Vadodara', 'Coimbatore', 
                          'Ludhiana', 'Agra', 'Nashik', 'Ranchi', 'Meerut', 'Raipur', 'Guwahati', 'Chandigarh') THEN 'Tier-2'
            ELSE 'Tier-3'
        END AS city_tier,
        CAST(ACTIVEFLAG AS STRING) AS ACTIVE_FLAG,
        TO_TIMESTAMP_TZ(CREATEDDATE , 'YYYY-MM-DD HH24:MI:SS') AS CREATED_TS,
        TO_TIMESTAMP_TZ(MODIFIEDDATE , 'YYYY-MM-DD HH24:MI:SS') AS MODIFIED_TS,
        _STG_FILE_NAME,
        _STG_FILE_LOAD_TS,
        _STG_FILE_MD5,
        CURRENT_TIMESTAMP AS _COPY_DATA_TS
    FROM SCH_STAGE.LOCATION_STREAM
) AS SOURCE

ON SOURCE.LOCATION_ID = TARGET.LOCATION_ID

WHEN MATCHED AND (                              -- DATA UPDATED IN SOURCE 
    target.City != source.City OR
    target.State != source.State OR
    target.state_code != source.state_code OR
    target.is_union_territory != source.is_union_territory OR
    target.capital_city_flag != source.capital_city_flag OR
    target.city_tier != source.city_tier OR
    target.Zip_Code != source.Zip_Code OR
    target.Active_Flag != source.Active_Flag OR
    target.modified_ts != source.modified_ts
)
THEN 
    UPDATE SET
        target.City = source.City,
        target.State = source.State,
        target.state_code = source.state_code,
        target.is_union_territory = source.is_union_territory,
        target.capital_city_flag = source.capital_city_flag,
        target.city_tier = source.city_tier,
        target.Zip_Code = source.Zip_Code,
        target.Active_Flag = source.Active_Flag,
        target.modified_ts = source.modified_ts,
        target._stg_file_name = source._stg_file_name,
        target._stg_file_load_ts = source._stg_file_load_ts,
        target._stg_file_md5 = source._stg_file_md5,
        target._copy_data_ts = source._copy_data_ts

WHEN NOT MATCHED                                -- FRESH DATA
THEN INSERT (
        Location_ID,
        City,
        State,
        state_code,
        is_union_territory,
        capital_city_flag,
        city_tier,
        Zip_Code,
        Active_Flag,
        created_ts,
        modified_ts,
        _stg_file_name,
        _stg_file_load_ts,
        _stg_file_md5,
        _copy_data_ts
    )
    VALUES (
        source.Location_ID,
        source.City,
        source.State,
        source.state_code,
        source.is_union_territory,
        source.capital_city_flag,
        source.city_tier,
        source.Zip_Code,
        source.Active_Flag,
        source.created_ts,
        source.modified_ts,
        source._stg_file_name,
        source._stg_file_load_ts,
        source._stg_file_md5,
        source._copy_data_ts
    );

    RETURN 'STAGE Location TO Clean LOCATION Merge Completed';

END
$$;


create or replace procedure sp_merge_to_location_DIM()
RETURNS STRING
LANGUAGE SQL
AS 
$$
BEGIN

    MERGE into sch_consumption.restaurant_location_dim as target
    using sch_clean.restaraunt_location_stream as source
    on source.LOCATION_ID = target.LOCATION_ID and source.ACTIVE_FLAG = target.ACTIVE_FLAG
    
    when MATCHED
        AND source.METADATA$ACTION = 'DELETE' AND source.METADATA$ISUPDATE = 'TRUE' THEN
        UPDATE 
            SET TARGET.eff_end_dt = CURRENT_TIMESTAMP(),
                TARGET.current_flag = FALSE
    
    WHEN NOT MATCHED
        AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'TRUE' THEN
        INSERT(
            RESTARAUNT_LOCATION_HK,
            LOCATION_ID,
            CITY,
            STATE,
            ZIP_CODE,
            STATE_CODE,
            IS_UNION_TERRITORY,
            CAPITAL_CITY_FLAG,
            CITY_TIER,
            ACTIVE_FLAG,
            EFF_START_DT,
            EFF_END_DT,
            CURRENT_FLAG
        )
        VALUES(
            HASH(SHA1_HEX(CONCAT(source.CITY,
                        source.STATE,
                        source.ZIP_CODE,
                        source.STATE_CODE,
                        source.IS_UNION_TERRITORY,
                        source.CAPITAL_CITY_FLAG,
                        source.CITY_TIER,
                        source.ACTIVE_FLAG
                    )
                )
            ),
            source.LOCATION_ID,
            source.CITY,
            source.STATE,
            source.ZIP_CODE,
            source.STATE_CODE,
            source.IS_UNION_TERRITORY,
            source.CAPITAL_CITY_FLAG,
            source.CITY_TIER,
            source.ACTIVE_FLAG,
            current_timestamp(),
            NULL,
            TRUE
        )
        
    WHEN NOT MATCHED
        AND source.METADATA$ACTION = 'INSERT' AND source.METADATA$ISUPDATE = 'FALSE' THEN
        INSERT(
            RESTARAUNT_LOCATION_HK,
            LOCATION_ID,
            CITY,
            STATE,
            ZIP_CODE,
            STATE_CODE,
            IS_UNION_TERRITORY,
            CAPITAL_CITY_FLAG,
            CITY_TIER,
            ACTIVE_FLAG,
            EFF_START_DT,
            EFF_END_DT,
            CURRENT_FLAG
        )
        VALUES(
            HASH(SHA1_HEX(CONCAT(source.CITY,
                        source.STATE,
                        source.ZIP_CODE,
                        source.STATE_CODE,
                        source.IS_UNION_TERRITORY,
                        source.CAPITAL_CITY_FLAG,
                        source.CITY_TIER,
                        source.ACTIVE_FLAG
                    )
                )
            ),
            source.LOCATION_ID,
            source.CITY,
            source.STATE,
            source.ZIP_CODE,
            source.STATE_CODE,
            source.IS_UNION_TERRITORY,
            source.CAPITAL_CITY_FLAG,
            source.CITY_TIER,
            source.ACTIVE_FLAG,
            current_timestamp(),
            NULL,
            TRUE
        )
    WHEN MATCHED
        AND source.METADATA$ACTION = 'DELETE'    AND source.METADATA$ISUPDATE = FALSE
    THEN
    UPDATE SET
        EFF_END_DT = CURRENT_TIMESTAMP(),
        CURRENT_FLAG = FALSE    
    ;
    
    RETURN 'CLEAN Location TO DIM LOCATION Merge Completed';

END
$$;






-- DONE WITH STORED PROCEDURES 
-- NOW LETS USE THEM IN TASKS

SHOW PROCEDURES;

CREATE or replace TASK task_stage_to_clean_location
WAREHOUSE = DEV_FOOD_WH
-- schedule = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('sch_stage.location_stream')
AS CALL SP_MERGE_TO_LOCATION_CLEAN()
;


CREATE or replace TASK task_clean_to_dim_location
WAREHOUSE = DEV_FOOD_WH
-- schedule = '1 MINUTE'
AFTER task_stage_to_clean_location
WHEN SYSTEM$STREAM_HAS_DATA('sch_clean.restaraunt_location_stream')
AS CALL sp_merge_to_location_DIM()
;

ALTER TASK task_stage_to_clean_location resume;

ALTER TASK task_clean_to_dim_location resume;



-- TASKS COMPLETELY CREATED 
-- NOW NEED TO REFRESH THE PIPE
-- EXECUTE THE FIRST TASK (OR WAIT IT WILL TAKE ONE MINUT)


alter pipe location_pipe refresh;
EXECUTE TASK task_stage_to_clean_location;

SELECT * FROM SCH_STAGE.LOCATION_STREAM;
SELECT * FROM SCH_CLEAN.RESTARAUNT_LOCATION_STREAM;

SELECT * FROM SCH_CONSUMPTION.RESTAURANT_LOCATION_DIM;

ALTER TASK task_stage_to_clean_location suspend;

ALTER TASK task_clean_to_dim_location suspend;

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'TASK_STAGE_TO_CLEAN_LOCATION'
    )
)
ORDER BY SCHEDULED_TIME DESC;

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'TASK_CLEAN_TO_DIM_LOCATION'
    )
)
ORDER BY SCHEDULED_TIME DESC;