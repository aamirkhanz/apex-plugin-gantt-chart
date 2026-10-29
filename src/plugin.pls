-- Gantt Chart region plug-in (TechRevX, www.techrevx.com)
-- render: a JSON block with the settings and the tasks, then techrevx.gantt.init (gantt.js), which draws
--         them with Frappe Gantt (MIT).
-- ajax:   x01 = LIST  returns the tasks again (refresh)
--         x01 = SAVE  runs the Save Code with :ID (x02), :START_DATE (x03), :END_DATE (x04) and :PROGRESS (x05);
--                     the task must be a row of the region's source. Errors come back as { saved: false, message }.
-- Tasks: id, name, start, end (YYYY-MM-DD or YYYY-MM-DD HH24:MI), progress, dependencies, color, description.

c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(
    'ID_COLUMN', 'NAME_COLUMN', 'START_COLUMN', 'END_COLUMN', 'PROGRESS_COLUMN', 'DEPENDENCIES_COLUMN', 'COLOR_COLUMN', 'DESCRIPTION_COLUMN' );
c_column_keys constant apex_t_varchar2 := apex_t_varchar2( 'id', 'name', 'start', 'end', 'progress', 'dependencies', 'color', 'description' );

function date_text( p_date in date ) return varchar2 is
begin
    return to_char( p_date, case when p_date = trunc( p_date ) then 'YYYY-MM-DD' else 'YYYY-MM-DD HH24:MI' end );
end date_text;

function parse_date( p_text in varchar2 ) return date is
begin
    return to_date( p_text, case when length( p_text ) > 10 then 'YYYY-MM-DD HH24:MI' else 'YYYY-MM-DD' end );
end parse_date;

-- writes "tasks" to the current apex_json output; returns whether p_find_id is one of them
function write_tasks( p_region in apex_plugin.t_region, p_find_id in varchar2 default null, p_write in boolean default true ) return boolean is
    l_names   apex_t_varchar2 := apex_t_varchar2();
    l_pos     apex_t_number   := apex_t_number();
    l_types   apex_t_number   := apex_t_number();
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
    l_added   boolean;
    l_found   boolean := false;
begin
    l_names.extend( c_column_attrs.count );
    l_pos.extend( c_column_attrs.count );
    l_types.extend( c_column_attrs.count );
    for i in 1 .. c_column_attrs.count loop
        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );
        if l_names( i ) is not null then
            l_added := false;
            for j in 1 .. i - 1 loop
                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );
            end loop;
            if not l_added then
                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );
            end if;
        end if;
    end loop;

    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );
    for i in 1 .. c_column_attrs.count loop
        if l_names( i ) is not null then
            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );
            if l_pos( i ) is null then
                raise_application_error( -20001, 'Gantt Chart: column ' || l_names( i ) || ' is not in the region source of "' || p_region.name || '".' );
            end if;
            l_types( i ) := apex_exec.get_column( l_context, l_pos( i ) ).data_type;
        end if;
    end loop;

    if p_write then
        apex_json.open_array( 'tasks' );
    end if;
    while apex_exec.next_row( l_context ) loop
        if p_find_id is not null and apex_exec.get_varchar2( l_context, l_pos( 1 ) ) = p_find_id then
            l_found := true;
        end if;
        if p_write then
            apex_json.open_object;
            for i in 1 .. c_column_attrs.count loop
                if l_pos( i ) is not null then
                    if l_types( i ) = apex_exec.c_data_type_date then
                        apex_json.write( c_column_keys( i ), date_text( apex_exec.get_date( l_context, l_pos( i ) ) ) );
                    elsif l_types( i ) in ( apex_exec.c_data_type_timestamp, apex_exec.c_data_type_timestamp_tz, apex_exec.c_data_type_timestamp_ltz ) then
                        apex_json.write( c_column_keys( i ), date_text( cast( apex_exec.get_timestamp( l_context, l_pos( i ) ) as date ) ) );
                    elsif c_column_keys( i ) = 'progress' then
                        apex_json.write( c_column_keys( i ), apex_exec.get_number( l_context, l_pos( i ) ) );
                    else
                        apex_json.write( c_column_keys( i ), apex_exec.get_varchar2( l_context, l_pos( i ) ) );
                    end if;
                end if;
            end loop;
            apex_json.close_object;
        end if;
    end loop;
    if p_write then
        apex_json.close_array;
    end if;
    apex_exec.close( l_context );
    return l_found;
exception
    when others then
        apex_exec.close( l_context );
        raise;
end write_tasks;

procedure render (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_render_param,
    p_result in out nocopy apex_plugin.t_region_render_result )
is
    l_json  clob;
    l_dummy boolean;
begin
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write( 'ajaxIdentifier', apex_plugin.get_ajax_identifier );
    apex_json.write( 'itemsToSubmit', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) );
    apex_json.write( 'noDataFound', apex_plugin_util.replace_substitutions( p_region.no_data_found_message, false ) );
    apex_json.write( 'viewModes', p_region.attributes.get_varchar2( 'VIEW_MODES' ) );
    apex_json.write( 'defaultView', p_region.attributes.get_varchar2( 'DEFAULT_VIEW' ) );
    apex_json.write( 'features', p_region.attributes.get_varchar2( 'FEATURES' ) );
    apex_json.write( 'height', p_region.attributes.get_number( 'HEIGHT' ) );
    apex_json.write( 'barHeight', p_region.attributes.get_number( 'BAR_HEIGHT' ) );
    apex_json.write( 'clickItem', p_region.attributes.get_varchar2( 'CLICK_ITEM' ) );
    apex_json.write( 'canSave', p_region.attributes.get_varchar2( 'SAVE_CODE' ) is not null );
    l_dummy := write_tasks( p_region );
    apex_json.close_object;
    l_json := apex_json.get_clob_output;
    apex_json.free_output;

    sys.htp.p( '<div id="' || apex_escape.html_attribute( p_region.static_id ) || '_gantt" class="tx-Gantt"></div>' );
    sys.htp.p( '<script type="application/json" id="' || apex_escape.html_attribute( p_region.static_id ) || '_tasks">' );
    apex_util.prn( p_clob => replace( l_json, '</', '<\/' ), p_escape => false );
    sys.htp.p( '</script>' );
    dbms_lob.freetemporary( l_json );

    apex_javascript.add_onload_code(
        p_code => 'techrevx.gantt.init(' || apex_javascript.add_value( p_region.static_id, false ) || ');' );
end render;

procedure ajax (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_ajax_param,
    p_result in out nocopy apex_plugin.t_region_ajax_result )
is
    l_code   varchar2( 32767 ) := p_region.attributes.get_varchar2( 'SAVE_CODE' );
    l_params apex_exec.t_parameters;
    l_dummy  boolean;

    -- apex_exec refuses binds the code does not use, so only pass the ones it mentions
    function uses( p_name in varchar2 ) return boolean is
    begin
        return regexp_like( l_code, ':' || p_name || '([^A-Za-z0-9_$#]|$)', 'i' );
    end uses;
begin
    if apex_application.g_x01 = 'SAVE' then
        if l_code is null then
            raise_application_error( -20002, 'Gantt Chart: no Save Code.' );
        end if;
        if not write_tasks( p_region, apex_application.g_x02, false ) then
            raise_application_error( -20003, 'Gantt Chart: unknown task.' );
        end if;
        savepoint tx_gantt_save;
        if uses( 'ID' ) then
            apex_exec.add_parameter( l_params, 'ID', apex_application.g_x02 );
        end if;
        if uses( 'START_DATE' ) then
            apex_exec.add_parameter( l_params, 'START_DATE', parse_date( apex_application.g_x03 ) );
        end if;
        if uses( 'END_DATE' ) then
            apex_exec.add_parameter( l_params, 'END_DATE', parse_date( apex_application.g_x04 ) );
        end if;
        if uses( 'PROGRESS' ) then
            apex_exec.add_parameter( l_params, 'PROGRESS', to_number( apex_application.g_x05 ) );
        end if;
        begin
            apex_exec.execute_plsql( p_plsql_code => l_code, p_sql_parameters => l_params );
            apex_json.open_object;
            apex_json.write( 'saved', true );
            apex_json.close_object;
        exception
            when others then
                -- undo what the Save Code changed; its raise_application_error text is shown to the user
                rollback to tx_gantt_save;
                if sqlcode between -20999 and -20000 then
                    apex_debug.info( 'Gantt Chart: Save Code refused task %s: %s', apex_application.g_x02, sqlerrm );
                else
                    apex_debug.error( 'Gantt Chart: Save Code failed for task %s: %s', apex_application.g_x02, sqlerrm );
                end if;
                apex_json.open_object;
                apex_json.write( 'saved', false );
                apex_json.write( 'message', case when sqlcode between -20999 and -20000
                                                 then regexp_substr( sqlerrm, '^ORA-\d{5}: ([^' || chr( 10 ) || ']+)', 1, 1, null, 1 ) end );
                apex_json.close_object;
        end;
    else
        apex_json.open_object;
        l_dummy := write_tasks( p_region );
        apex_json.close_object;
    end if;
end ajax;
