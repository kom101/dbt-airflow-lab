{{ config(materialized='table') }}

with validated_data as (
    select  
        event_body
    from {{ ref('stg_events_validated') }}
),

flattened_items as (
    select 
        json_value(event_body, '$.order_id') as order_id,
        item -- pojedynczy element z tablicy JSON
    from validated_data,
    unnest(json_query_array(event_body, '$.items')) as item
)

select 
    order_id,
    json_value(item, '$.sku') as sku,
    cast(json_value(item, '$.quantity') as int64) as quantity,
    cast(json_value(item, '$.price') as float64) as price
from flattened_items