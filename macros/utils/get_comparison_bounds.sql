/*
The idea here is that if the event_time is set, we will only compare records enclosed in both models.
This improves performance and allows us to compare apples to apples, instead of detecting millions/billions
of "deletions" identified due to prod having all data while CI only has a few days' worth.

In the diagram below, the thatched section is the comparison bounds. You can think of it as
                                                         
         greatest(model_a.min_value, model_b.min_value)  
            least(model_a.max_value, model_b.max_value)  
                                                         
                 ┌────────────────────────────┐          
  a min_value    │                a max_value │        
    └──► ┌───────┼────────────────────┐ ◄───┘ │        
         │       │┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼│       │        
model_a  │       │┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼│       │ model_b
         │       │┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼┼│       │        
         └───────┼────────────────────┘       │        
            ┌──► └────────────────────────────┘ ◄────┐ 
           b min_value                      b max_value 
*/
{% macro get_comparison_bounds(a_relation, b_relation, event_time) %}
    {% set min_max_queries %}
        with min_maxes as (
            select min({{ event_time }}) as min_event_time, max({{ event_time }}) as max_event_time
            from {{ a_relation }}
            union all 
            select min({{ event_time }}) as min_event_time, max({{ event_time }}) as max_event_time
            from {{ b_relation }}
        )
        select max(min_event_time) as min_event_time, min(max_event_time) as max_event_time
        from min_maxes
    {% endset %}

    {% set query_response = dbt_utils.get_query_results_as_dict(min_max_queries) %}
    
    {% set event_time_props = {"event_time": event_time} %}
    {% for k in query_response.keys() %}
        {% do event_time_props.update({k | lower: query_response[k][0]}) %}
    {% endfor %}
    
    {% do return(event_time_props) %}
{% endmacro %}