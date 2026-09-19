USE DATABASE FOOD_DELIVERY_DEV;
USE SCHEMA SCH_CLEAN;

select * from sch_stage.location;

create table sch_clean.restaurant_location (
    restaraunt_location_sk number autoincrement primary key,
    
    location_id number not null unique,
    city string(100) not null,
    state string(100) not null,
    zip_code string(10) not null,
    
    state_code string(100) not null,
    is_union_territory boolean not null default false,
    capital_city_flag boolean not null default false,
    city_tier string(6),
    
    active_flag string(10) not null,
    created_ts timestamp_tz not null,
    modified_ts timestamp_tz,
    
    -- audit columns for tracking & debugging
    _stg_file_name string,
    _stg_file_load_ts timestamp_ntz,
    _stg_file_md5 string,
    _copy_data_ts timestamp_ntz default current_timestamp
)comment = 'Location entity under clean schema with appropriate data type under clean schema layer, data is populated using merge statement from the stage layer location table. This table does not support SCD2';

-- show tables in sch_clean;

create or replace stream sch_clean.restaraunt_location_stream
on table sch_clean.restaurant_location
comment = 'this is a standard stream object on the location table to track insert, update, and delete changes';

DESC TABLE RESTAURANT_LOCATION;
DESC TABLE SCH_STAGE.LOCATION;
select "name" , "type" from (table(result_scan(last_query_id())));

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

show streams IN SCH_STAGE;
SELECT  * FROM RESTARAUNT_LOCATION_STREAM;
SELECT  * FROM SCH_STAGE.LOCATION_STREAM;
SELECT * FROM RESTAURANT_LOCATION;
 
