{% set a_relation=ref('data_detect_column_changes_a')%}

{% set b_relation=ref('data_detect_column_changes_b') %}


select 
    lower(column_name) as column_name,
    is_changed
from (

    {{ audit_helper.detect_column_changes(
        a_relation=a_relation,
        b_relation=b_relation,
        primary_key="id",
        exclude_columns=["becomes_null"]
    ) }}

) as macro_output