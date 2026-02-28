{{ config(materialized='table') }}

with validated_data as (
    select  
        event_body,
        event_timestamp,
        event_type
    from {{ ref('stg_events_validated') }}
)

select 
    json_value(event_body, '$.order_id') as order_id,
    json_value(event_body, '$.customer_id') as customer_id,
    cast(json_value(event_body, '$.total_amount') as float64) as total_amount,
    event_timestamp as processed_at
from validated_data
where event_type = 'order_placed'