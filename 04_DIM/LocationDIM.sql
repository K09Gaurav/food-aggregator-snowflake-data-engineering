USE DATABASE FOOD_DELIVERY_DEV;
USE ROLE SYSADMIN;
USE WAREHOUSE DEV_FOOD_WH;
USE SCHEMA SCH_CONSUMPTION;

--      PURPOSE
-- Store historical versions
-- Enable SCD2 tracking
-- Support reporting and analytics
-- Join with fact tables using surrogate key

-- The clean layer remains a simple current-state entity table, while the consumption layer becomes a historical dimension by introducing a surrogate key (restaurant_location_hk) and SCD2 columns (eff_start_dt, eff_end_dt, current_flag)

CREATE OR REPLACE TABLE sch_consumption.restaurant_location_dim(
    restaraunt_location_hk number primary key,          -- hash key
    
    location_id number not null unique,
    city string(100) not null,
    state string(100) not null,
    zip_code string(10) not null,
    state_code string(100) not null,
    is_union_territory boolean not null default false,
    capital_city_flag boolean not null default false,
    city_tier string(6),
    active_flag string(10) not null,

    eff_start_dt timestamp_tz(9) not null,              -- effective start date for scd2
    eff_end_dt timestamp_tz(9),
    current_flag boolean default true not null
)
comment = 'Dimension table for restaurant location with scd2 (slowly changing dimension) enabled and hashkey as surrogate key';
;

desc table sch_consumption.restaurant_location_dim;
SELECT * FROM SCH_CLEAN.RESTARAUNT_LOCATION_STREAM;



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



SELECT * FROM SCH_CONSUMPTION.RESTAURANT_LOCATION_DIM;