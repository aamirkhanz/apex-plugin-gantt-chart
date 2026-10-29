prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.04.07'
,p_release=>'26.2.0'
,p_default_workspace_id=>6202419497391597
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'AAMIRKHANZ'
);
end;
/
 
prompt APPLICATION 100 - Apex Plug-ins
--
-- Application Export:
--   Application:     100
--   Name:            Apex Plug-ins
--   Date and Time:   09:17 Thursday October 29, 2026
--   Exported By:     AAMIRKHANZ
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 6234579290952371
--   Manifest End
--   Version:         26.2.0
--   Instance ID:     2400160207269871
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_techrevx_gantt
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(6234579290952371)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.TECHREVX.GANTT'
,p_display_name=>'Gantt Chart'
,p_apexlang_name=>'gantt'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#PLUGIN_FILES#frappe-gantt.umd.js',
'#PLUGIN_FILES#gantt.js'))
,p_css_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#PLUGIN_FILES#frappe-gantt.css',
'#PLUGIN_FILES#gantt.css'))
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- Gantt Chart region plug-in (TechRevX, www.techrevx.com)',
'-- render: a JSON block with the settings and the tasks, then techrevx.gantt.init (gantt.js), which draws',
'--         them with Frappe Gantt (MIT).',
'-- ajax:   x01 = LIST  returns the tasks again (refresh)',
'--         x01 = SAVE  runs the Save Code with :ID (x02), :START_DATE (x03), :END_DATE (x04) and :PROGRESS (x05);',
'--                     the task must be a row of the region''s source. Errors come back as { saved: false, message }.',
'-- Tasks: id, name, start, end (YYYY-MM-DD or YYYY-MM-DD HH24:MI), progress, dependencies, color, description.',
'',
'c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(',
'    ''ID_COLUMN'', ''NAME_COLUMN'', ''START_COLUMN'', ''END_COLUMN'', ''PROGRESS_COLUMN'', ''DEPENDENCIES_COLUMN'', ''COLOR_COLUMN'', ''DESCRIPTION_COLUMN'' );',
'c_column_keys constant apex_t_varchar2 := apex_t_varchar2( ''id'', ''name'', ''start'', ''end'', ''progress'', ''dependencies'', ''color'', ''description'' );',
'',
'function date_text( p_date in date ) return varchar2 is',
'begin',
'    return to_char( p_date, case when p_date = trunc( p_date ) then ''YYYY-MM-DD'' else ''YYYY-MM-DD HH24:MI'' end );',
'end date_text;',
'',
'function parse_date( p_text in varchar2 ) return date is',
'begin',
'    return to_date( p_text, case when length( p_text ) > 10 then ''YYYY-MM-DD HH24:MI'' else ''YYYY-MM-DD'' end );',
'end parse_date;',
'',
'-- writes "tasks" to the current apex_json output; returns whether p_find_id is one of them',
'function write_tasks( p_region in apex_plugin.t_region, p_find_id in varchar2 default null, p_write in boolean default true ) return boolean is',
'    l_names   apex_t_varchar2 := apex_t_varchar2();',
'    l_pos     apex_t_number   := apex_t_number();',
'    l_types   apex_t_number   := apex_t_number();',
'    l_columns apex_exec.t_columns;',
'    l_context apex_exec.t_context;',
'    l_added   boolean;',
'    l_found   boolean := false;',
'begin',
'    l_names.extend( c_column_attrs.count );',
'    l_pos.extend( c_column_attrs.count );',
'    l_types.extend( c_column_attrs.count );',
'    for i in 1 .. c_column_attrs.count loop',
'        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );',
'        if l_names( i ) is not null then',
'            l_added := false;',
'            for j in 1 .. i - 1 loop',
'                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );',
'            end loop;',
'            if not l_added then',
'                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );',
'            end if;',
'        end if;',
'    end loop;',
'',
'    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );',
'    for i in 1 .. c_column_attrs.count loop',
'        if l_names( i ) is not null then',
'            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );',
'            if l_pos( i ) is null then',
'                raise_application_error( -20001, ''Gantt Chart: column '' || l_names( i ) || '' is not in the region source of "'' || p_region.name || ''".'' );',
'            end if;',
'            l_types( i ) := apex_exec.get_column( l_context, l_pos( i ) ).data_type;',
'        end if;',
'    end loop;',
'',
'    if p_write then',
'        apex_json.open_array( ''tasks'' );',
'    end if;',
'    while apex_exec.next_row( l_context ) loop',
'        if p_find_id is not null and apex_exec.get_varchar2( l_context, l_pos( 1 ) ) = p_find_id then',
'            l_found := true;',
'        end if;',
'        if p_write then',
'            apex_json.open_object;',
'            for i in 1 .. c_column_attrs.count loop',
'                if l_pos( i ) is not null then',
'                    if l_types( i ) = apex_exec.c_data_type_date then',
'                        apex_json.write( c_column_keys( i ), date_text( apex_exec.get_date( l_context, l_pos( i ) ) ) );',
'                    elsif l_types( i ) in ( apex_exec.c_data_type_timestamp, apex_exec.c_data_type_timestamp_tz, apex_exec.c_data_type_timestamp_ltz ) then',
'                        apex_json.write( c_column_keys( i ), date_text( cast( apex_exec.get_timestamp( l_context, l_pos( i ) ) as date ) ) );',
'                    elsif c_column_keys( i ) = ''progress'' then',
'                        apex_json.write( c_column_keys( i ), apex_exec.get_number( l_context, l_pos( i ) ) );',
'                    else',
'                        apex_json.write( c_column_keys( i ), apex_exec.get_varchar2( l_context, l_pos( i ) ) );',
'                    end if;',
'                end if;',
'            end loop;',
'            apex_json.close_object;',
'        end if;',
'    end loop;',
'    if p_write then',
'        apex_json.close_array;',
'    end if;',
'    apex_exec.close( l_context );',
'    return l_found;',
'exception',
'    when others then',
'        apex_exec.close( l_context );',
'        raise;',
'end write_tasks;',
'',
'procedure render (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_render_param,',
'    p_result in out nocopy apex_plugin.t_region_render_result )',
'is',
'    l_json  clob;',
'    l_dummy boolean;',
'begin',
'    apex_json.initialize_clob_output;',
'    apex_json.open_object;',
'    apex_json.write( ''ajaxIdentifier'', apex_plugin.get_ajax_identifier );',
'    apex_json.write( ''itemsToSubmit'', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) );',
'    apex_json.write( ''noDataFound'', apex_plugin_util.replace_substitutions( p_region.no_data_found_message, false ) );',
'    apex_json.write( ''viewModes'', p_region.attributes.get_varchar2( ''VIEW_MODES'' ) );',
'    apex_json.write( ''defaultView'', p_region.attributes.get_varchar2( ''DEFAULT_VIEW'' ) );',
'    apex_json.write( ''features'', p_region.attributes.get_varchar2( ''FEATURES'' ) );',
'    apex_json.write( ''height'', p_region.attributes.get_number( ''HEIGHT'' ) );',
'    apex_json.write( ''barHeight'', p_region.attributes.get_number( ''BAR_HEIGHT'' ) );',
'    apex_json.write( ''clickItem'', p_region.attributes.get_varchar2( ''CLICK_ITEM'' ) );',
'    apex_json.write( ''canSave'', p_region.attributes.get_varchar2( ''SAVE_CODE'' ) is not null );',
'    l_dummy := write_tasks( p_region );',
'    apex_json.close_object;',
'    l_json := apex_json.get_clob_output;',
'    apex_json.free_output;',
'',
'    sys.htp.p( ''<div id="'' || apex_escape.html_attribute( p_region.static_id ) || ''_gantt" class="tx-Gantt"></div>'' );',
'    sys.htp.p( ''<script type="application/json" id="'' || apex_escape.html_attribute( p_region.static_id ) || ''_tasks">'' );',
'    apex_util.prn( p_clob => replace( l_json, ''</'', ''<\/'' ), p_escape => false );',
'    sys.htp.p( ''</script>'' );',
'    dbms_lob.freetemporary( l_json );',
'',
'    apex_javascript.add_onload_code(',
'        p_code => ''techrevx.gantt.init('' || apex_javascript.add_value( p_region.static_id, false ) || '');'' );',
'end render;',
'',
'procedure ajax (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_ajax_param,',
'    p_result in out nocopy apex_plugin.t_region_ajax_result )',
'is',
'    l_code   varchar2( 32767 ) := p_region.attributes.get_varchar2( ''SAVE_CODE'' );',
'    l_params apex_exec.t_parameters;',
'    l_dummy  boolean;',
'',
'    -- apex_exec refuses binds the code does not use, so only pass the ones it mentions',
'    function uses( p_name in varchar2 ) return boolean is',
'    begin',
'        return regexp_like( l_code, '':'' || p_name || ''([^A-Za-z0-9_$#]|$)'', ''i'' );',
'    end uses;',
'begin',
'    if apex_application.g_x01 = ''SAVE'' then',
'        if l_code is null then',
'            raise_application_error( -20002, ''Gantt Chart: no Save Code.'' );',
'        end if;',
'        if not write_tasks( p_region, apex_application.g_x02, false ) then',
'            raise_application_error( -20003, ''Gantt Chart: unknown task.'' );',
'        end if;',
'        savepoint tx_gantt_save;',
'        if uses( ''ID'' ) then',
'            apex_exec.add_parameter( l_params, ''ID'', apex_application.g_x02 );',
'        end if;',
'        if uses( ''START_DATE'' ) then',
'            apex_exec.add_parameter( l_params, ''START_DATE'', parse_date( apex_application.g_x03 ) );',
'        end if;',
'        if uses( ''END_DATE'' ) then',
'            apex_exec.add_parameter( l_params, ''END_DATE'', parse_date( apex_application.g_x04 ) );',
'        end if;',
'        if uses( ''PROGRESS'' ) then',
'            apex_exec.add_parameter( l_params, ''PROGRESS'', to_number( apex_application.g_x05 ) );',
'        end if;',
'        begin',
'            apex_exec.execute_plsql( p_plsql_code => l_code, p_sql_parameters => l_params );',
'            apex_json.open_object;',
'            apex_json.write( ''saved'', true );',
'            apex_json.close_object;',
'        exception',
'            when others then',
'                -- undo what the Save Code changed; its raise_application_error text is shown to the user',
'                rollback to tx_gantt_save;',
'                if sqlcode between -20999 and -20000 then',
'                    apex_debug.info( ''Gantt Chart: Save Code refused task %s: %s'', apex_application.g_x02, sqlerrm );',
'                else',
'                    apex_debug.error( ''Gantt Chart: Save Code failed for task %s: %s'', apex_application.g_x02, sqlerrm );',
'                end if;',
'                apex_json.open_object;',
'                apex_json.write( ''saved'', false );',
'                apex_json.write( ''message'', case when sqlcode between -20999 and -20000',
'                                                 then regexp_substr( sqlerrm, ''^ORA-\d{5}: ([^'' || chr( 10 ) || '']+)'', 1, 1, null, 1 ) end );',
'                apex_json.close_object;',
'        end;',
'    else',
'        apex_json.open_object;',
'        l_dummy := write_tasks( p_region );',
'        apex_json.close_object;',
'    end if;',
'end ajax;'))
,p_api_version=>3
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'SOURCE_LOCATION:AJAX_ITEMS_TO_SUBMIT:ORDER_BY:NO_DATA_FOUND_MESSAGE:SUPPORTS_EXTERNAL_FILTERING'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Gantt Chart: Project tasks on a timeline that users reschedule by dragging, saved with your own PL/SQL.',
'',
'Source: any region source with one row per task. Map ID, Name, Start and End; Progress, Dependencies, Color and Description are optional.',
'Timeline: Hour, Quarter Day, Half Day, Day, Week, Month and Year views with view buttons, a Today button, today''s line, weekend shading, dependency arrows, expected progress and a details popup.',
'Editing: drag a bar to move it, drag its ends to change its length, drag the handle to change progress; tasks that depend on it move along. The Save Code gets :ID, :START_DATE, :END_DATE and :PROGRESS; if it fails the task goes back and its message i'
||'s shown.',
'Options: skip weekends in durations, bar height, chart height, Set Item on Click. JavaScript: apex.region( "id" ).refresh(), changeViewMode( "Month" ), scrollToToday(), getTasks(). Events: Gantt - Task Clicked, Task Changed, View Changed.',
'',
'Frappe Gantt is licensed under the MIT License (frappe.io/gantt).',
'Documentation, updates and more plugins: https://www.techrevx.com'))
,p_version_identifier=>'1.0'
,p_about_url=>'https://www.techrevx.com'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Chart library: Frappe Gantt 1.2.2, included',
'Saving: your PL/SQL with :ID, :START_DATE, :END_DATE and :PROGRESS',
'License: Frappe Gantt MIT License'))
,p_files_version=>2461343091607
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6234697654952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_title=>'Chart'
,p_apexlang_name=>'chart'
,p_static_id=>'CHART'
,p_display_sequence=>20
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6234759104952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_title=>'Tasks'
,p_apexlang_name=>'data'
,p_static_id=>'DATA'
,p_display_sequence=>10
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6234895775952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_title=>'Saving'
,p_apexlang_name=>'saving'
,p_static_id=>'SAVING'
,p_display_sequence=>30
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6234914518952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>50
,p_static_id=>'BAR_HEIGHT'
,p_prompt=>'Bar Height'
,p_apexlang_name=>'barHeight'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'28'
,p_unit=>'px'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6235001219952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>60
,p_static_id=>'CLICK_ITEM'
,p_prompt=>'Set Item on Click'
,p_apexlang_name=>'clickItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
,p_help_text=>'Page item set to the task''s ID when a task is clicked, before Gantt - Task Clicked fires. Use it to open a form for the task.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6235108365952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'COLOR_COLUMN'
,p_prompt=>'Color Column'
,p_apexlang_name=>'colorColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'CSS color of the bar, for example #2f6fde or a phase color. The progress is drawn in the full color, the rest lighter.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6235275533952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>20
,p_static_id=>'DEFAULT_VIEW'
,p_prompt=>'Initial View'
,p_apexlang_name=>'defaultView'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'week'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
,p_help_text=>'The time scale shown first. The chart scrolls to today.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235609532952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>40
,p_display_value=>'Day'
,p_return_value=>'day'
,p_apexlang_name=>'day'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235586438952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>30
,p_display_value=>'Half Day'
,p_return_value=>'halfDay'
,p_apexlang_name=>'halfDay'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235396166952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>10
,p_display_value=>'Hour'
,p_return_value=>'hour'
,p_apexlang_name=>'hour'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235819992952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>60
,p_display_value=>'Month'
,p_return_value=>'month'
,p_apexlang_name=>'month'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235414835952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>20
,p_display_value=>'Quarter Day'
,p_return_value=>'quarterDay'
,p_apexlang_name=>'quarterDay'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235727159952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>50
,p_display_value=>'Week'
,p_return_value=>'week'
,p_apexlang_name=>'week'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6235934073952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6235275533952371)
,p_display_sequence=>70
,p_display_value=>'Year'
,p_return_value=>'year'
,p_apexlang_name=>'year'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6236076122952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'DEPENDENCIES_COLUMN'
,p_prompt=>'Dependencies Column'
,p_apexlang_name=>'dependenciesColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'IDs of the tasks this task waits for, separated by commas. Each one is drawn as an arrow, and dragging a task moves the tasks that depend on it.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6236162414952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'DESCRIPTION_COLUMN'
,p_prompt=>'Description Column'
,p_apexlang_name=>'descriptionColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'Text in the details shown when a task is clicked, for example the owner.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6236252161952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'END_COLUMN'
,p_prompt=>'End Column'
,p_apexlang_name=>'endColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'DATE:TIMESTAMP:VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'Last day of the task, included: a task from 3 to 5 March lasts three days. With a time, the task ends at that time.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6236349874952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>30
,p_static_id=>'FEATURES'
,p_prompt=>'Features'
,p_apexlang_name=>'features'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'toolbar:today:dates:progress:popup'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
,p_help_text=>'View Buttons: switch between the View Modes. Today Button: scrolls to today. Change Dates: drag a bar to move it, drag its ends to change its length. Change Progress: drag the handle under the bar. Expected Progress: a line showing how far the task s'
||'hould be by today. Skip Weekends: Saturdays and Sundays are not counted in a task''s length. Details on Click: a popup with the dates, duration and description.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236654666952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>30
,p_display_value=>'Change Dates'
,p_return_value=>'dates'
,p_apexlang_name=>'dates'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236890123952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>50
,p_display_value=>'Expected Progress'
,p_return_value=>'expected'
,p_apexlang_name=>'expected'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6237085552952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>70
,p_display_value=>'Details on Click'
,p_return_value=>'popup'
,p_apexlang_name=>'popup'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236700844952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>40
,p_display_value=>'Change Progress'
,p_return_value=>'progress'
,p_apexlang_name=>'progress'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236528789952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>20
,p_display_value=>'Today Button'
,p_return_value=>'today'
,p_apexlang_name=>'today'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236419030952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>10
,p_display_value=>'View Buttons'
,p_return_value=>'toolbar'
,p_apexlang_name=>'toolbar'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6236913982952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6236349874952371)
,p_display_sequence=>60
,p_display_value=>'Skip Weekends'
,p_return_value=>'weekends'
,p_apexlang_name=>'weekends'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237164367952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>40
,p_static_id=>'HEIGHT'
,p_prompt=>'Height'
,p_apexlang_name=>'height'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'460'
,p_unit=>'px'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
,p_help_text=>'Height of the chart; it scrolls inside. 0 makes it as tall as all its rows.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237299818952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'ID_COLUMN'
,p_prompt=>'ID Column'
,p_apexlang_name=>'idColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'Unique key of each task, used by Dependencies and available as :ID in the Save Code.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237361698952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'NAME_COLUMN'
,p_prompt=>'Name Column'
,p_apexlang_name=>'nameColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'Text on the bar.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237417107952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'PROGRESS_COLUMN'
,p_prompt=>'Progress Column'
,p_apexlang_name=>'progressColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'Percent done, 0 to 100, shown as the filled part of the bar.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237586518952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>15
,p_display_sequence=>10
,p_static_id=>'SAVE_CODE'
,p_prompt=>'Save Code'
,p_apexlang_name=>'saveCode'
,p_attribute_type=>'PLSQL'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234895775952371)
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'update project_tasks',
'   set start_date = :START_DATE,',
'       end_date   = :END_DATE,',
'       progress   = :PROGRESS',
' where task_id = :ID;'))
,p_help_text=>'PL/SQL run after a task''s dates or progress are changed. :ID is the task, :START_DATE and :END_DATE are DATE values (END_DATE is the last day, included) and :PROGRESS is 0 to 100. If it raises an error, the task goes back and the message is shown. Le'
||'ave empty to only fire Gantt - Task Changed.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237682419952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'START_COLUMN'
,p_prompt=>'Start Column'
,p_apexlang_name=>'startColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'DATE:TIMESTAMP:VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6234759104952371)
,p_help_text=>'First day (or time) of the task. Text values use the format YYYY-MM-DD or YYYY-MM-DD HH24:MI.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6237744657952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>10
,p_static_id=>'VIEW_MODES'
,p_prompt=>'View Modes'
,p_apexlang_name=>'viewModes'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'day:week:month'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6234697654952371)
,p_help_text=>'The time scales users can switch between with the view buttons.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6238121638952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>40
,p_display_value=>'Day'
,p_return_value=>'day'
,p_apexlang_name=>'day'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6238013166952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>30
,p_display_value=>'Half Day'
,p_return_value=>'halfDay'
,p_apexlang_name=>'halfDay'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6237846040952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>10
,p_display_value=>'Hour'
,p_return_value=>'hour'
,p_apexlang_name=>'hour'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6238347205952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>60
,p_display_value=>'Month'
,p_return_value=>'month'
,p_apexlang_name=>'month'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6237926519952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>20
,p_display_value=>'Quarter Day'
,p_return_value=>'quarterDay'
,p_apexlang_name=>'quarterDay'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6238232207952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>50
,p_display_value=>'Week'
,p_return_value=>'week'
,p_apexlang_name=>'week'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6238448379952371)
,p_plugin_attribute_id=>wwv_flow_imp.id(6237744657952371)
,p_display_sequence=>70
,p_display_value=>'Year'
,p_return_value=>'year'
,p_apexlang_name=>'year'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6238534799952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_name=>'tx-gantt-change'
,p_display_name=>'Gantt - Task Changed'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6238683067952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_name=>'tx-gantt-click'
,p_display_name=>'Gantt - Task Clicked'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6238797554952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_name=>'tx-gantt-view'
,p_display_name=>'Gantt - View Changed'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '3A726F6F747B2D2D672D6172726F772D636F6C6F723A20233166323933373B2D2D672D6261722D636F6C6F723A20236666663B2D2D672D6261722D626F726465723A20236666663B2D2D672D7469636B2D636F6C6F722D746869636B3A20236564656465';
wwv_flow_imp.g_varchar2_table(2) := '643B2D2D672D7469636B2D636F6C6F723A20236633663366333B2D2D672D616374696F6E732D6261636B67726F756E643A20236633663366333B2D2D672D626F726465722D636F6C6F723A20236562656666323B2D2D672D746578742D6D757465643A20';
wwv_flow_imp.g_varchar2_table(3) := '233763376337633B2D2D672D746578742D6C696768743A20236666663B2D2D672D746578742D6461726B3A20233137313731373B2D2D672D70726F67726573732D636F6C6F723A20236462646264623B2D2D672D68616E646C652D636F6C6F723A202333';
wwv_flow_imp.g_varchar2_table(4) := '37333532663B2D2D672D7765656B656E642D6C6162656C2D636F6C6F723A20236463646365343B2D2D672D65787065637465642D70726F67726573733A20236334633465393B2D2D672D6865616465722D6261636B67726F756E643A20236666663B2D2D';
wwv_flow_imp.g_varchar2_table(5) := '672D726F772D636F6C6F723A20236664666466643B2D2D672D726F772D626F726465722D636F6C6F723A20236337633763373B2D2D672D746F6461792D686967686C696768743A20233337333532663B2D2D672D706F7075702D616374696F6E733A2023';
wwv_flow_imp.g_varchar2_table(6) := '6562656666323B2D2D672D7765656B656E642D686967686C696768742D636F6C6F723A20236637663766377D68746D6C5B646174612D7468656D653D6461726B5D7B2D2D672D6172726F772D636F6C6F723A20236535653565353B2D2D672D6261722D63';
wwv_flow_imp.g_varchar2_table(7) := '6F6C6F723A20233261326132613B2D2D672D6261722D626F726465723A20233361336133613B2D2D672D7469636B2D636F6C6F722D746869636B3A20233161316131613B2D2D672D7469636B2D636F6C6F723A20233061306130613B2D2D672D61637469';
wwv_flow_imp.g_varchar2_table(8) := '6F6E732D6261636B67726F756E643A20233161316131613B2D2D672D626F726465722D636F6C6F723A20233261326132613B2D2D672D746578742D6D757465643A20233939393939393B2D2D672D746578742D6C696768743A20236666666666663B2D2D';
wwv_flow_imp.g_varchar2_table(9) := '672D746578742D6461726B3A20236635663566353B2D2D672D70726F67726573732D636F6C6F723A20233461346134613B2D2D672D68616E646C652D636F6C6F723A20236430643064303B2D2D672D7765656B656E642D6C6162656C2D636F6C6F723A20';
wwv_flow_imp.g_varchar2_table(10) := '233361336133613B2D2D672D65787065637465642D70726F67726573733A20233561356135613B2D2D672D6865616465722D6261636B67726F756E643A20233061306130613B2D2D672D726F772D636F6C6F723A20233134313431343B2D2D672D726F77';
wwv_flow_imp.g_varchar2_table(11) := '2D626F726465722D636F6C6F723A20233261326132613B2D2D672D746F6461792D686967686C696768743A20233939393939393B2D2D672D706F7075702D616374696F6E733A20233161316131613B2D2D672D7765656B656E642D686967686C69676874';
wwv_flow_imp.g_varchar2_table(12) := '2D636F6C6F723A20233066306630667D2E67616E74742D636F6E7461696E65727B6C696E652D6865696768743A31342E3570783B706F736974696F6E3A72656C61746976653B6F766572666C6F773A6175746F3B666F6E742D73697A653A313270783B68';
wwv_flow_imp.g_varchar2_table(13) := '65696768743A766172282D2D67762D677269642D686569676874293B77696474683A313030253B626F726465722D7261646975733A3870783B69736F6C6174696F6E3A69736F6C6174657D2E67616E74742D636F6E7461696E6572202E706F7075702D77';
wwv_flow_imp.g_varchar2_table(14) := '7261707065727B706F736974696F6E3A6162736F6C7574653B746F703A303B6C6566743A303B6261636B67726F756E643A766172282D2D672D6865616465722D6261636B67726F756E64293B626F782D736861646F773A3020313070782032347078202D';
wwv_flow_imp.g_varchar2_table(15) := '3370782023303030333B70616464696E673A313070783B626F726465722D7261646975733A3570783B77696474683A6D61782D636F6E74656E743B7A2D696E6465783A313030307D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170';
wwv_flow_imp.g_varchar2_table(16) := '706572202E7469746C657B6D617267696E2D626F74746F6D3A3270783B636F6C6F723A766172282D2D672D746578742D6461726B293B666F6E742D73697A653A2E383572656D3B666F6E742D7765696768743A3635303B6C696E652D6865696768743A31';
wwv_flow_imp.g_varchar2_table(17) := '3570787D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572202E7375627469746C657B636F6C6F723A766172282D2D672D746578742D6461726B293B666F6E742D73697A653A2E3872656D3B6D617267696E2D626F74746F6D';
wwv_flow_imp.g_varchar2_table(18) := '3A3570787D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572202E64657461696C737B636F6C6F723A766172282D2D672D746578742D6D75746564293B666F6E742D73697A653A2E3772656D7D2E67616E74742D636F6E7461';
wwv_flow_imp.g_varchar2_table(19) := '696E6572202E706F7075702D77726170706572202E616374696F6E737B6D617267696E2D746F703A313070783B6D617267696E2D6C6566743A3370787D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572202E616374696F6E';
wwv_flow_imp.g_varchar2_table(20) := '2D62746E7B626F726465723A6E6F6E653B70616464696E673A357078203870783B6261636B67726F756E642D636F6C6F723A766172282D2D672D706F7075702D616374696F6E73293B626F726465722D72696768743A31707820736F6C69642076617228';
wwv_flow_imp.g_varchar2_table(21) := '2D2D672D626F726465722D636F6C6F72297D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572202E616374696F6E2D62746E3A686F7665727B66696C7465723A6272696768746E65737328393725297D2E67616E74742D636F';
wwv_flow_imp.g_varchar2_table(22) := '6E7461696E6572202E706F7075702D77726170706572202E616374696F6E2D62746E3A66697273742D6368696C647B626F726465722D746F702D6C6566742D7261646975733A3470783B626F726465722D626F74746F6D2D6C6566742D7261646975733A';
wwv_flow_imp.g_varchar2_table(23) := '3470787D2E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572202E616374696F6E2D62746E3A6C6173742D6368696C647B626F726465722D72696768743A6E6F6E653B626F726465722D746F702D72696768742D726164697573';
wwv_flow_imp.g_varchar2_table(24) := '3A3470783B626F726465722D626F74746F6D2D72696768742D7261646975733A3470787D2E67616E74742D636F6E7461696E6572202E677269642D6865616465727B6865696768743A63616C6328766172282D2D67762D6C6F7765722D6865616465722D';
wwv_flow_imp.g_varchar2_table(25) := '68656967687429202B20766172282D2D67762D75707065722D6865616465722D68656967687429202B2031307078293B6261636B67726F756E642D636F6C6F723A766172282D2D672D6865616465722D6261636B67726F756E64293B706F736974696F6E';
wwv_flow_imp.g_varchar2_table(26) := '3A737469636B793B746F703A303B6C6566743A303B626F726465722D626F74746F6D3A31707820736F6C696420766172282D2D672D726F772D626F726465722D636F6C6F72293B7A2D696E6465783A313030307D2E67616E74742D636F6E7461696E6572';
wwv_flow_imp.g_varchar2_table(27) := '202E6C6F7765722D746578742C2E67616E74742D636F6E7461696E6572202E75707065722D746578747B746578742D616E63686F723A6D6964646C657D2E67616E74742D636F6E7461696E6572202E75707065722D6865616465727B6865696768743A76';
wwv_flow_imp.g_varchar2_table(28) := '6172282D2D67762D75707065722D6865616465722D686569676874297D2E67616E74742D636F6E7461696E6572202E6C6F7765722D6865616465727B6865696768743A766172282D2D67762D6C6F7765722D6865616465722D686569676874297D2E6761';
wwv_flow_imp.g_varchar2_table(29) := '6E74742D636F6E7461696E6572202E6C6F7765722D746578747B666F6E742D73697A653A313270783B706F736974696F6E3A6162736F6C7574653B77696474683A63616C6328766172282D2D67762D636F6C756D6E2D776964746829202A202E38293B68';
wwv_flow_imp.g_varchar2_table(30) := '65696768743A63616C6328766172282D2D67762D6C6F7765722D6865616465722D68656967687429202A202E38293B6D617267696E3A302063616C6328766172282D2D67762D636F6C756D6E2D776964746829202A202E31293B616C69676E2D636F6E74';
wwv_flow_imp.g_varchar2_table(31) := '656E743A63656E7465723B746578742D616C69676E3A63656E7465723B636F6C6F723A766172282D2D672D746578742D6D75746564297D2E67616E74742D636F6E7461696E6572202E75707065722D746578747B706F736974696F6E3A6162736F6C7574';
wwv_flow_imp.g_varchar2_table(32) := '653B77696474683A6669742D636F6E74656E743B666F6E742D7765696768743A3530303B666F6E742D73697A653A313470783B636F6C6F723A766172282D2D672D746578742D6461726B293B6865696768743A63616C6328766172282D2D67762D6C6F77';
wwv_flow_imp.g_varchar2_table(33) := '65722D6865616465722D68656967687429202A202E3636297D2E67616E74742D636F6E7461696E6572202E63757272656E742D75707065727B706F736974696F6E3A737469636B793B6C6566743A3021696D706F7274616E743B70616464696E672D6C65';
wwv_flow_imp.g_varchar2_table(34) := '66743A313770783B6261636B67726F756E643A766172282D2D672D6865616465722D6261636B67726F756E64297D2E67616E74742D636F6E7461696E6572202E736964652D6865616465727B706F736974696F6E3A737469636B793B746F703A303B7269';
wwv_flow_imp.g_varchar2_table(35) := '6768743A303B666C6F61743A72696768743B7A2D696E6465783A313030303B6C696E652D6865696768743A323070783B666F6E742D7765696768743A3430303B77696474683A6D61782D636F6E74656E743B6D617267696E2D6C6566743A6175746F3B70';
wwv_flow_imp.g_varchar2_table(36) := '616464696E672D72696768743A313070783B70616464696E672D746F703A313070783B6261636B67726F756E643A766172282D2D672D6865616465722D6261636B67726F756E64293B646973706C61793A666C65787D2E67616E74742D636F6E7461696E';
wwv_flow_imp.g_varchar2_table(37) := '6572202E736964652D686561646572202A7B7472616E736974696F6E2D70726F70657274793A6261636B67726F756E642D636F6C6F723B7472616E736974696F6E2D74696D696E672D66756E6374696F6E3A63756269632D62657A696572282E342C302C';
wwv_flow_imp.g_varchar2_table(38) := '2E322C31293B7472616E736974696F6E2D6475726174696F6E3A2E3135733B6261636B67726F756E642D636F6C6F723A766172282D2D672D616374696F6E732D6261636B67726F756E64293B626F726465722D7261646975733A2E3572656D3B626F7264';
wwv_flow_imp.g_varchar2_table(39) := '65723A6E6F6E653B70616464696E673A357078203870783B636F6C6F723A766172282D2D672D746578742D6461726B293B666F6E742D73697A653A313470783B6C65747465722D73706163696E673A2E3032656D3B666F6E742D7765696768743A343230';
wwv_flow_imp.g_varchar2_table(40) := '3B626F782D73697A696E673A636F6E74656E742D626F783B6D617267696E2D72696768743A3570787D2E67616E74742D636F6E7461696E6572202E736964652D686561646572202A3A6C6173742D6368696C647B6D617267696E2D72696768743A307D2E';
wwv_flow_imp.g_varchar2_table(41) := '67616E74742D636F6E7461696E6572202E736964652D686561646572202A3A686F7665727B66696C7465723A6272696768746E6573732839372E3525297D2E67616E74742D636F6E7461696E6572202E736964652D6865616465722073656C6563747B77';
wwv_flow_imp.g_varchar2_table(42) := '696474683A363070783B70616464696E672D746F703A3270783B70616464696E672D626F74746F6D3A3270787D2E67616E74742D636F6E7461696E6572202E736964652D6865616465722073656C6563743A666F6375737B6F75746C696E653A6E6F6E65';
wwv_flow_imp.g_varchar2_table(43) := '7D2E67616E74742D636F6E7461696E6572202E646174652D72616E67652D686967686C696768747B6261636B67726F756E642D636F6C6F723A766172282D2D672D70726F67726573732D636F6C6F72293B626F726465722D7261646975733A313270783B';
wwv_flow_imp.g_varchar2_table(44) := '6865696768743A63616C6328766172282D2D67762D6C6F7765722D6865616465722D68656967687429202D20367078293B746F703A63616C6328766172282D2D67762D75707065722D6865616465722D68656967687429202B20357078293B706F736974';
wwv_flow_imp.g_varchar2_table(45) := '696F6E3A6162736F6C7574657D2E67616E74742D636F6E7461696E6572202E63757272656E742D686967686C696768747B706F736974696F6E3A6162736F6C7574653B6261636B67726F756E643A766172282D2D672D746F6461792D686967686C696768';
wwv_flow_imp.g_varchar2_table(46) := '74293B77696474683A3170783B7A2D696E6465783A3939397D2E67616E74742D636F6E7461696E6572202E63757272656E742D62616C6C2D686967686C696768747B706F736974696F6E3A6162736F6C7574653B6261636B67726F756E643A766172282D';
wwv_flow_imp.g_varchar2_table(47) := '2D672D746F6461792D686967686C69676874293B7A2D696E6465783A313030313B626F726465722D7261646975733A3530257D2E67616E74742D636F6E7461696E6572202E63757272656E742D646174652D686967686C696768747B6261636B67726F75';
wwv_flow_imp.g_varchar2_table(48) := '6E643A766172282D2D672D746F6461792D686967686C69676874293B636F6C6F723A766172282D2D672D746578742D6C69676874293B626F726465722D7261646975733A3570787D2E67616E74742D636F6E7461696E6572202E686F6C696461792D6C61';
wwv_flow_imp.g_varchar2_table(49) := '62656C7B706F736974696F6E3A6162736F6C7574653B746F703A303B6C6566743A303B6F7061636974793A303B7A2D696E6465783A313030303B6261636B67726F756E643A766172282D2D672D7765656B656E642D6C6162656C2D636F6C6F72293B626F';
wwv_flow_imp.g_varchar2_table(50) := '726465722D7261646975733A3570783B70616464696E673A327078203570787D2E67616E74742D636F6E7461696E6572202E686F6C696461792D6C6162656C2E73686F777B6F7061636974793A3130307D2E67616E74742D636F6E7461696E6572202E65';
wwv_flow_imp.g_varchar2_table(51) := '78747261737B706F736974696F6E3A737469636B793B6C6566743A307D2E67616E74742D636F6E7461696E6572202E657874726173202E61646A7573747B706F736974696F6E3A6162736F6C7574653B6C6566743A3870783B746F703A63616C63287661';
wwv_flow_imp.g_varchar2_table(52) := '72282D2D67762D677269642D68656967687429202D2036307078293B6261636B67726F756E642D636F6C6F723A766172282D2D672D616374696F6E732D6261636B67726F756E64293B636F6C6F723A766172282D2D672D746578742D6C69676874293B62';
wwv_flow_imp.g_varchar2_table(53) := '6F726465723A6E6F6E653B70616464696E673A3870783B626F726465722D7261646975733A3370787D2E67616E74742D636F6E7461696E6572202E686964657B646973706C61793A6E6F6E657D2E67616E74747B757365722D73656C6563743A6E6F6E65';
wwv_flow_imp.g_varchar2_table(54) := '3B2D7765626B69742D757365722D73656C6563743A6E6F6E653B706F736974696F6E3A6162736F6C7574657D2E67616E7474202E677269642D6261636B67726F756E647B66696C6C3A6E6F6E657D2E67616E7474202E677269642D726F777B66696C6C3A';
wwv_flow_imp.g_varchar2_table(55) := '766172282D2D672D726F772D636F6C6F72297D2E67616E7474202E726F772D6C696E657B7374726F6B653A766172282D2D672D626F726465722D636F6C6F72297D2E67616E7474202E7469636B7B7374726F6B653A766172282D2D672D7469636B2D636F';
wwv_flow_imp.g_varchar2_table(56) := '6C6F72293B7374726F6B652D77696474683A2E347D2E67616E7474202E7469636B2E746869636B7B7374726F6B653A766172282D2D672D7469636B2D636F6C6F722D746869636B293B7374726F6B652D77696474683A2E377D2E67616E7474202E617272';
wwv_flow_imp.g_varchar2_table(57) := '6F777B66696C6C3A6E6F6E653B7374726F6B653A766172282D2D672D6172726F772D636F6C6F72293B7374726F6B652D77696474683A312E357D2E67616E7474202E6261722D77726170706572202E6261727B66696C6C3A766172282D2D672D6261722D';
wwv_flow_imp.g_varchar2_table(58) := '636F6C6F72293B7374726F6B653A766172282D2D672D6261722D626F72646572293B7374726F6B652D77696474683A303B7472616E736974696F6E3A7374726F6B652D7769647468202E337320656173657D2E67616E7474202E6261722D70726F677265';
wwv_flow_imp.g_varchar2_table(59) := '73737B66696C6C3A766172282D2D672D70726F67726573732D636F6C6F72293B626F726465722D7261646975733A3470787D2E67616E7474202E6261722D65787065637465642D70726F67726573737B66696C6C3A766172282D2D672D65787065637465';
wwv_flow_imp.g_varchar2_table(60) := '642D70726F6772657373297D2E67616E7474202E6261722D696E76616C69647B66696C6C3A7472616E73706172656E743B7374726F6B653A766172282D2D672D6261722D626F72646572293B7374726F6B652D77696474683A313B7374726F6B652D6461';
wwv_flow_imp.g_varchar2_table(61) := '736861727261793A357D3A6973282E67616E7474202E6261722D696E76616C6964297E2E6261722D6C6162656C7B66696C6C3A766172282D2D672D746578742D6C69676874297D2E67616E7474202E6261722D6C6162656C7B66696C6C3A766172282D2D';
wwv_flow_imp.g_varchar2_table(62) := '672D746578742D6461726B293B646F6D696E616E742D626173656C696E653A63656E7472616C3B666F6E742D66616D696C793A48656C7665746963613B666F6E742D73697A653A313370783B666F6E742D7765696768743A3430307D2E67616E7474202E';
wwv_flow_imp.g_varchar2_table(63) := '6261722D6C6162656C2E6269677B66696C6C3A766172282D2D672D746578742D6461726B293B746578742D616E63686F723A73746172747D2E67616E7474202E68616E646C657B66696C6C3A766172282D2D672D68616E646C652D636F6C6F72293B6F70';
wwv_flow_imp.g_varchar2_table(64) := '61636974793A303B7472616E736974696F6E3A6F706163697479202E337320656173657D2E67616E7474202E68616E646C652E6163746976652C2E67616E7474202E68616E646C652E76697369626C657B637572736F723A65772D726573697A653B6F70';
wwv_flow_imp.g_varchar2_table(65) := '61636974793A317D2E67616E7474202E68616E646C652E70726F67726573737B66696C6C3A766172282D2D672D746578742D6D75746564297D2E67616E7474202E6261722D777261707065727B637572736F723A706F696E7465727D2E67616E7474202E';
wwv_flow_imp.g_varchar2_table(66) := '6261722D77726170706572202E6261727B6F75746C696E653A31707820736F6C696420766172282D2D672D726F772D626F726465722D636F6C6F72293B626F726465722D7261646975733A3370787D2E67616E7474202E6261722D777261707065723A68';
wwv_flow_imp.g_varchar2_table(67) := '6F766572202E6261727B7472616E736974696F6E3A7472616E73666F726D202E337320656173657D2E67616E7474202E6261722D777261707065723A686F766572202E646174652D72616E67652D686967686C696768747B646973706C61793A626C6F63';
wwv_flow_imp.g_varchar2_table(68) := '6B7D2E67616E7474202E677269642D636F6C756D6E7B66696C6C3A7472616E73706172656E743B706F696E7465722D6576656E74733A616C6C7D2E67616E7474202E677269642D636F6C756D6E3A686F7665727B66696C6C3A766172282D2D672D776565';
wwv_flow_imp.g_varchar2_table(69) := '6B656E642D686967686C696768742D636F6C6F72293B7472616E736974696F6E3A66696C6C202E317320656173657D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6238813533952371)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_file_name=>'frappe-gantt.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2866756E6374696F6E28792C78297B747970656F66206578706F7274733D3D226F626A656374222626747970656F66206D6F64756C653C2275223F6D6F64756C652E6578706F7274733D7828293A747970656F6620646566696E653D3D2266756E637469';
wwv_flow_imp.g_varchar2_table(2) := '6F6E222626646566696E652E616D643F646566696E652878293A28793D747970656F6620676C6F62616C546869733C2275223F676C6F62616C546869733A797C7C73656C662C792E47616E74743D782829297D2928746869732C66756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(3) := '7B2275736520737472696374223B636F6E737420793D2279656172222C783D226D6F6E7468222C4D3D22646179222C443D22686F7572222C543D226D696E757465222C4C3D227365636F6E64222C453D226D696C6C697365636F6E64222C643D7B706172';
wwv_flow_imp.g_varchar2_table(4) := '73655F6475726174696F6E286E297B636F6E737420653D2F285B302D395D2B2928797C6D7C647C687C6D696E7C737C6D73292F676D2E65786563286E293B69662865213D3D6E756C6C297B696628655B325D3D3D3D2279222972657475726E7B64757261';
wwv_flow_imp.g_varchar2_table(5) := '74696F6E3A7061727365496E7428655B315D292C7363616C653A2279656172227D3B696628655B325D3D3D3D226D222972657475726E7B6475726174696F6E3A7061727365496E7428655B315D292C7363616C653A226D6F6E7468227D3B696628655B32';
wwv_flow_imp.g_varchar2_table(6) := '5D3D3D3D2264222972657475726E7B6475726174696F6E3A7061727365496E7428655B315D292C7363616C653A22646179227D3B696628655B325D3D3D3D2268222972657475726E7B6475726174696F6E3A7061727365496E7428655B315D292C736361';
wwv_flow_imp.g_varchar2_table(7) := '6C653A22686F7572227D3B696628655B325D3D3D3D226D696E222972657475726E7B6475726174696F6E3A7061727365496E7428655B315D292C7363616C653A226D696E757465227D3B696628655B325D3D3D3D2273222972657475726E7B6475726174';
wwv_flow_imp.g_varchar2_table(8) := '696F6E3A7061727365496E7428655B315D292C7363616C653A227365636F6E64227D3B696628655B325D3D3D3D226D73222972657475726E7B6475726174696F6E3A7061727365496E7428655B315D292C7363616C653A226D696C6C697365636F6E6422';
wwv_flow_imp.g_varchar2_table(9) := '7D7D7D2C7061727365286E2C743D222D222C653D2F5B2E3A5D2F297B6966286E20696E7374616E63656F6620446174652972657475726E206E3B696628747970656F66206E3D3D22737472696E6722297B6C657420692C733B636F6E737420723D6E2E73';
wwv_flow_imp.g_varchar2_table(10) := '706C697428222022293B693D725B305D2E73706C69742874292E6D6170286F3D3E7061727365496E74286F2C313029292C733D725B315D2626725B315D2E73706C69742865292C695B315D3D695B315D3F695B315D2D313A303B6C657420613D693B7265';
wwv_flow_imp.g_varchar2_table(11) := '7475726E20732626732E6C656E6774683F28732E6C656E6774683D3D3D34262628735B335D3D22302E222B735B335D2C735B335D3D7061727365466C6F617428735B335D292A316533292C613D612E636F6E636174287329293A613D612E636F6E636174';
wwv_flow_imp.g_varchar2_table(12) := '285B302C302C302C305D292C6E65772044617465282E2E2E61297D7D2C746F5F737472696E67286E2C743D2131297B69662821286E20696E7374616E63656F66204461746529297468726F77206E657720547970654572726F722822496E76616C696420';
wwv_flow_imp.g_varchar2_table(13) := '617267756D656E74207479706522293B636F6E737420653D746869732E6765745F646174655F76616C756573286E292E6D61702828722C61293D3E28613D3D3D31262628723D722B31292C613D3D3D363F7628722B22222C332C223022293A7628722B22';
wwv_flow_imp.g_varchar2_table(14) := '222C322C2230222929292C693D60247B655B305D7D2D247B655B315D7D2D247B655B325D7D602C733D60247B655B335D7D3A247B655B345D7D3A247B655B355D7D2E247B655B365D7D603B72657475726E20692B28743F2220222B733A2222297D2C666F';
wwv_flow_imp.g_varchar2_table(15) := '726D6174286E2C743D22595959592D4D4D2D44442048483A6D6D3A73732E535353222C653D22656E22297B636F6E737420693D6E657720496E746C2E4461746554696D65466F726D617428652C7B6D6F6E74683A226C6F6E67227D292C733D6E65772049';
wwv_flow_imp.g_varchar2_table(16) := '6E746C2E4461746554696D65466F726D617428652C7B6D6F6E74683A2273686F7274227D292C723D692E666F726D6174286E292C613D722E6368617241742830292E746F55707065724361736528292B722E736C6963652831292C6F3D746869732E6765';
wwv_flow_imp.g_varchar2_table(17) := '745F646174655F76616C756573286E292E6D6170285F3D3E76285F2C322C3029292C683D7B595959593A6F5B305D2C4D4D3A76282B6F5B315D2B312C322C30292C44443A6F5B325D2C48483A6F5B335D2C6D6D3A6F5B345D2C73733A6F5B355D2C535353';
wwv_flow_imp.g_varchar2_table(18) := '3A6F5B365D2C443A6F5B325D2C4D4D4D4D3A612C4D4D4D3A732E666F726D6174286E297D3B6C657420673D743B636F6E7374206C3D5B5D3B72657475726E204F626A6563742E6B6579732868292E736F727428285F2C70293D3E702E6C656E6774682D5F';
wwv_flow_imp.g_varchar2_table(19) := '2E6C656E677468292E666F7245616368285F3D3E7B672E696E636C75646573285F29262628673D672E7265706C616365416C6C285F2C6024247B6C2E6C656E6774687D60292C6C2E7075736828685B5F5D29297D292C6C2E666F724561636828285F2C70';
wwv_flow_imp.g_varchar2_table(20) := '293D3E7B673D672E7265706C616365416C6C286024247B707D602C5F297D292C677D2C64696666286E2C742C653D2264617922297B6C657420692C732C722C612C6F2C682C673B693D6E2D742B28742E67657454696D657A6F6E654F666673657428292D';
wwv_flow_imp.g_varchar2_table(21) := '6E2E67657454696D657A6F6E654F66667365742829292A3665342C733D692F3165332C613D732F36302C723D612F36302C6F3D722F32343B6C6574206C3D6E2E67657446756C6C5965617228292D742E67657446756C6C5965617228292C5F3D6E2E6765';
wwv_flow_imp.g_varchar2_table(22) := '744D6F6E746828292D742E6765744D6F6E746828293B72657475726E205F2B3D6E2E6765744461746528292F33312C683D6C2A31322B5F2C6E2E6765744461746528293C742E6765744461746528292626682D2D2C673D682F31322C652E656E64735769';
wwv_flow_imp.g_varchar2_table(23) := '746828227322297C7C28652B3D227322292C4D6174682E726F756E64287B6D696C6C697365636F6E64733A692C7365636F6E64733A732C6D696E757465733A612C686F7572733A722C646179733A6F2C6D6F6E7468733A682C79656172733A677D5B655D';
wwv_flow_imp.g_varchar2_table(24) := '2A313030292F3130307D2C746F64617928297B636F6E7374206E3D746869732E6765745F646174655F76616C756573286E65772044617465292E736C69636528302C33293B72657475726E206E65772044617465282E2E2E6E297D2C6E6F7728297B7265';
wwv_flow_imp.g_varchar2_table(25) := '7475726E206E657720446174657D2C616464286E2C742C65297B743D7061727365496E7428742C3130293B636F6E737420693D5B6E2E67657446756C6C5965617228292B28653D3D3D793F743A30292C6E2E6765744D6F6E746828292B28653D3D3D783F';
wwv_flow_imp.g_varchar2_table(26) := '743A30292C6E2E6765744461746528292B28653D3D3D4D3F743A30292C6E2E676574486F75727328292B28653D3D3D443F743A30292C6E2E6765744D696E7574657328292B28653D3D3D543F743A30292C6E2E6765745365636F6E647328292B28653D3D';
wwv_flow_imp.g_varchar2_table(27) := '3D4C3F743A30292C6E2E6765744D696C6C697365636F6E647328292B28653D3D3D453F743A30295D3B72657475726E206E65772044617465282E2E2E69297D2C73746172745F6F66286E2C74297B636F6E737420653D7B5B795D3A362C5B785D3A352C5B';
wwv_flow_imp.g_varchar2_table(28) := '4D5D3A342C5B445D3A332C5B545D3A322C5B4C5D3A312C5B455D3A307D3B66756E6374696F6E20692872297B636F6E737420613D655B745D3B72657475726E20655B725D3C3D617D636F6E737420733D5B6E2E67657446756C6C5965617228292C692879';
wwv_flow_imp.g_varchar2_table(29) := '293F303A6E2E6765744D6F6E746828292C692878293F313A6E2E6765744461746528292C69284D293F303A6E2E676574486F75727328292C692844293F303A6E2E6765744D696E7574657328292C692854293F303A6E2E6765745365636F6E647328292C';
wwv_flow_imp.g_varchar2_table(30) := '69284C293F303A6E2E6765744D696C6C697365636F6E647328295D3B72657475726E206E65772044617465282E2E2E73297D2C636C6F6E65286E297B72657475726E206E65772044617465282E2E2E746869732E6765745F646174655F76616C75657328';
wwv_flow_imp.g_varchar2_table(31) := '6E29297D2C6765745F646174655F76616C756573286E297B72657475726E5B6E2E67657446756C6C5965617228292C6E2E6765744D6F6E746828292C6E2E6765744461746528292C6E2E676574486F75727328292C6E2E6765744D696E7574657328292C';
wwv_flow_imp.g_varchar2_table(32) := '6E2E6765745365636F6E647328292C6E2E6765744D696C6C697365636F6E647328295D7D2C6765745F7574635F646174655F76616C756573286E297B72657475726E5B6E2E67657455544346756C6C5965617228292C6E2E6765745554434D6F6E746828';
wwv_flow_imp.g_varchar2_table(33) := '292C6E2E6765745554434461746528292C6E2E676574555443486F75727328292C6E2E6765745554434D696E7574657328292C6E2E6765745554435365636F6E647328292C6E2E6765745554434D696C6C697365636F6E647328295D7D2C636F6E766572';
wwv_flow_imp.g_varchar2_table(34) := '745F7363616C6573286E2C74297B636F6E737420653D7B6D696C6C697365636F6E643A3131353734303734303734303734303734652D32342C7365636F6E643A3131353734303734303734303734303733652D32312C6D696E7574653A2E303030363934';
wwv_flow_imp.g_varchar2_table(35) := '343434343434343434343434352C686F75723A2E3034313636363636363636363636363636342C6461793A312C6D6F6E74683A33302C796561723A3336357D2C7B6475726174696F6E3A692C7363616C653A737D3D746869732E70617273655F64757261';
wwv_flow_imp.g_varchar2_table(36) := '74696F6E286E293B72657475726E20692A655B735D2F655B745D7D2C6765745F646179735F696E5F6D6F6E7468286E297B636F6E737420743D5B33312C32382C33312C33302C33312C33302C33312C33312C33302C33312C33302C33315D2C653D6E2E67';
wwv_flow_imp.g_varchar2_table(37) := '65744D6F6E746828293B69662865213D3D312972657475726E20745B655D3B636F6E737420693D6E2E67657446756C6C5965617228293B72657475726E206925343D3D3D3026266925313030213D307C7C69253430303D3D3D303F32393A32387D2C6765';
wwv_flow_imp.g_varchar2_table(38) := '745F646179735F696E5F79656172286E297B72657475726E206E2E67657446756C6C59656172282925343F3336353A3336367D7D3B66756E6374696F6E2076286E2C742C65297B72657475726E206E3D6E2B22222C743D743E3E302C653D537472696E67';
wwv_flow_imp.g_varchar2_table(39) := '28747970656F6620653C2275223F653A222022292C6E2E6C656E6774683E743F537472696E67286E293A28743D742D6E2E6C656E6774682C743E652E6C656E677468262628652B3D652E72657065617428742F652E6C656E67746829292C652E736C6963';
wwv_flow_imp.g_varchar2_table(40) := '6528302C74292B537472696E67286E29297D66756E6374696F6E2063286E2C74297B72657475726E20747970656F66206E3D3D22737472696E67223F28747C7C646F63756D656E74292E717565727953656C6563746F72286E293A6E7C7C6E756C6C7D66';
wwv_flow_imp.g_varchar2_table(41) := '756E6374696F6E2066286E2C74297B636F6E737420653D646F63756D656E742E637265617465456C656D656E744E532822687474703A2F2F7777772E77332E6F72672F323030302F737667222C6E293B666F72286C6574206920696E207429693D3D3D22';
wwv_flow_imp.g_varchar2_table(42) := '617070656E645F746F223F742E617070656E645F746F2E617070656E644368696C642865293A693D3D3D22696E6E657248544D4C223F652E696E6E657248544D4C3D742E696E6E657248544D4C3A693D3D3D22636C697050617468223F652E7365744174';
wwv_flow_imp.g_varchar2_table(43) := '747269627574652822636C69702D70617468222C2275726C2823222B745B695D2B222922293A652E73657441747472696275746528692C745B695D293B72657475726E20657D66756E6374696F6E2059286E2C742C652C69297B636F6E737420733D5828';
wwv_flow_imp.g_varchar2_table(44) := '6E2C742C652C69293B696628733D3D3D6E297B636F6E737420723D646F63756D656E742E6372656174654576656E74282248544D4C4576656E747322293B722E696E69744576656E742822636C69636B222C21302C2130292C722E6576656E744E616D65';
wwv_flow_imp.g_varchar2_table(45) := '3D22636C69636B222C732E64697370617463684576656E742872297D7D66756E6374696F6E2058286E2C742C652C692C733D22302E3473222C723D22302E317322297B636F6E737420613D6E2E717565727953656C6563746F722822616E696D61746522';
wwv_flow_imp.g_varchar2_table(46) := '293B696628612972657475726E20632E6174747228612C7B6174747269627574654E616D653A742C66726F6D3A652C746F3A692C6475723A732C626567696E3A22636C69636B202B20222B727D292C6E3B636F6E7374206F3D662822616E696D61746522';
wwv_flow_imp.g_varchar2_table(47) := '2C7B6174747269627574654E616D653A742C66726F6D3A652C746F3A692C6475723A732C626567696E3A722C63616C634D6F64653A2273706C696E65222C76616C7565733A652B223B222B692C6B657954696D65733A22303B2031222C6B657953706C69';
wwv_flow_imp.g_varchar2_table(48) := '6E65733A432822656173652D6F757422297D293B72657475726E206E2E617070656E644368696C64286F292C6E7D66756E6374696F6E2043286E297B72657475726E7B656173653A222E3235202E31202E32352031222C6C696E6561723A223020302031';
wwv_flow_imp.g_varchar2_table(49) := '2031222C22656173652D696E223A222E3432203020312031222C22656173652D6F7574223A22302030202E35382031222C22656173652D696E2D6F7574223A222E34322030202E35382031227D5B6E5D7D632E6F6E3D286E2C742C652C69293D3E7B693F';
wwv_flow_imp.g_varchar2_table(50) := '632E64656C6567617465286E2C742C652C69293A28693D652C632E62696E64286E2C742C6929297D2C632E6F66663D286E2C742C65293D3E7B6E2E72656D6F76654576656E744C697374656E657228742C65297D2C632E62696E643D286E2C742C65293D';
wwv_flow_imp.g_varchar2_table(51) := '3E7B742E73706C6974282F5C732B2F292E666F72456163682866756E6374696F6E2869297B6E2E6164644576656E744C697374656E657228692C65297D297D2C632E64656C65676174653D286E2C742C652C69293D3E7B6E2E6164644576656E744C6973';
wwv_flow_imp.g_varchar2_table(52) := '74656E657228742C66756E6374696F6E2873297B636F6E737420723D732E7461726765742E636C6F736573742865293B72262628732E64656C6567617465645461726765743D722C692E63616C6C28746869732C732C7229297D297D2C632E636C6F7365';
wwv_flow_imp.g_varchar2_table(53) := '73743D286E2C74293D3E743F742E6D617463686573286E293F743A632E636C6F73657374286E2C742E706172656E744E6F6465293A6E756C6C2C632E617474723D286E2C742C65293D3E7B69662821652626747970656F6620743D3D22737472696E6722';
wwv_flow_imp.g_varchar2_table(54) := '2972657475726E206E2E6765744174747269627574652874293B696628747970656F6620743D3D226F626A65637422297B666F72286C6574206920696E207429632E61747472286E2C692C745B695D293B72657475726E7D6E2E73657441747472696275';
wwv_flow_imp.g_varchar2_table(55) := '746528742C65297D3B636C61737320577B636F6E7374727563746F7228742C652C69297B746869732E67616E74743D742C746869732E66726F6D5F7461736B3D652C746869732E746F5F7461736B3D692C746869732E63616C63756C6174655F70617468';
wwv_flow_imp.g_varchar2_table(56) := '28292C746869732E6472617728297D63616C63756C6174655F7061746828297B6C657420743D746869732E66726F6D5F7461736B2E246261722E6765745828292B746869732E66726F6D5F7461736B2E246261722E676574576964746828292F323B636F';
wwv_flow_imp.g_varchar2_table(57) := '6E737420653D28293D3E746869732E746F5F7461736B2E246261722E6765745828293C742B746869732E67616E74742E6F7074696F6E732E70616464696E672626743E746869732E66726F6D5F7461736B2E246261722E6765745828292B746869732E67';
wwv_flow_imp.g_varchar2_table(58) := '616E74742E6F7074696F6E732E70616464696E673B666F72283B6528293B29742D3D31303B742D3D31303B6C657420693D746869732E67616E74742E636F6E6669672E6865616465725F6865696768742B746869732E67616E74742E6F7074696F6E732E';
wwv_flow_imp.g_varchar2_table(59) := '6261725F6865696768742B28746869732E67616E74742E6F7074696F6E732E70616464696E672B746869732E67616E74742E6F7074696F6E732E6261725F686569676874292A746869732E66726F6D5F7461736B2E7461736B2E5F696E6465782B746869';
wwv_flow_imp.g_varchar2_table(60) := '732E67616E74742E6F7074696F6E732E70616464696E672F322C733D746869732E746F5F7461736B2E246261722E6765745828292D31332C723D746869732E67616E74742E636F6E6669672E6865616465725F6865696768742B746869732E67616E7474';
wwv_flow_imp.g_varchar2_table(61) := '2E6F7074696F6E732E6261725F6865696768742F322B28746869732E67616E74742E6F7074696F6E732E70616464696E672B746869732E67616E74742E6F7074696F6E732E6261725F686569676874292A746869732E746F5F7461736B2E7461736B2E5F';
wwv_flow_imp.g_varchar2_table(62) := '696E6465782B746869732E67616E74742E6F7074696F6E732E70616464696E672F323B636F6E737420613D746869732E66726F6D5F7461736B2E7461736B2E5F696E6465783E746869732E746F5F7461736B2E7461736B2E5F696E6465783B6C6574206F';
wwv_flow_imp.g_varchar2_table(63) := '3D746869732E67616E74742E6F7074696F6E732E6172726F775F63757276653B636F6E737420683D613F313A303B6C657420673D613F2D6F3A6F3B696628746869732E746F5F7461736B2E246261722E6765745828293C3D746869732E66726F6D5F7461';
wwv_flow_imp.g_varchar2_table(64) := '736B2E246261722E6765745828292B746869732E67616E74742E6F7074696F6E732E70616464696E67297B6C6574206C3D746869732E67616E74742E6F7074696F6E732E70616464696E672F322D6F3B6C3C302626286C3D302C6F3D746869732E67616E';
wwv_flow_imp.g_varchar2_table(65) := '74742E6F7074696F6E732E70616464696E672F322C673D613F2D6F3A6F293B636F6E7374205F3D746869732E746F5F7461736B2E246261722E6765745928292B746869732E746F5F7461736B2E246261722E67657448656967687428292F322D672C703D';
wwv_flow_imp.g_varchar2_table(66) := '746869732E746F5F7461736B2E246261722E6765745828292D746869732E67616E74742E6F7074696F6E732E70616464696E673B746869732E706174683D600A202020202020202020202020202020204D20247B747D20247B697D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(67) := '20202020202020207620247B6C7D0A202020202020202020202020202020206120247B6F7D20247B6F7D20302030203120247B2D6F7D20247B6F7D0A202020202020202020202020202020204820247B707D0A2020202020202020202020202020202061';
wwv_flow_imp.g_varchar2_table(68) := '20247B6F7D20247B6F7D2030203020247B687D20247B2D6F7D20247B677D0A202020202020202020202020202020205620247B5F7D0A202020202020202020202020202020206120247B6F7D20247B6F7D2030203020247B687D20247B6F7D20247B677D';
wwv_flow_imp.g_varchar2_table(69) := '0A202020202020202020202020202020204C20247B737D20247B727D0A202020202020202020202020202020206D202D35202D350A202020202020202020202020202020206C203520350A202020202020202020202020202020206C202D352035607D65';
wwv_flow_imp.g_varchar2_table(70) := '6C73657B733C742B6F2626286F3D732D74293B6C6574206C3D613F722B6F3A722D6F3B746869732E706174683D600A20202020202020202020202020204D20247B747D20247B697D0A20202020202020202020202020205620247B6C7D0A202020202020';
wwv_flow_imp.g_varchar2_table(71) := '20202020202020206120247B6F7D20247B6F7D2030203020247B687D20247B6F7D20247B6F7D0A20202020202020202020202020204C20247B737D20247B727D0A20202020202020202020202020206D202D35202D350A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(72) := '206C203520350A20202020202020202020202020206C202D352035607D7D6472617728297B746869732E656C656D656E743D66282270617468222C7B643A746869732E706174682C22646174612D66726F6D223A746869732E66726F6D5F7461736B2E74';
wwv_flow_imp.g_varchar2_table(73) := '61736B2E69642C22646174612D746F223A746869732E746F5F7461736B2E7461736B2E69647D297D75706461746528297B746869732E63616C63756C6174655F7061746828292C746869732E656C656D656E742E73657441747472696275746528226422';
wwv_flow_imp.g_varchar2_table(74) := '2C746869732E70617468297D7D636C61737320717B636F6E7374727563746F7228742C65297B746869732E7365745F64656661756C747328742C65292C746869732E707265706172655F777261707065727328292C746869732E707265706172655F6865';
wwv_flow_imp.g_varchar2_table(75) := '6C7065727328292C746869732E7265667265736828297D7265667265736828297B746869732E6261725F67726F75702E696E6E657248544D4C3D22222C746869732E68616E646C655F67726F75702E696E6E657248544D4C3D22222C746869732E746173';
wwv_flow_imp.g_varchar2_table(76) := '6B2E637573746F6D5F636C6173733F746869732E67726F75702E636C6173734C6973742E61646428746869732E7461736B2E637573746F6D5F636C617373293A746869732E67726F75702E636C6173734C6973743D5B226261722D77726170706572225D';
wwv_flow_imp.g_varchar2_table(77) := '2C746869732E707265706172655F76616C75657328292C746869732E6472617728292C746869732E62696E6428297D7365745F64656661756C747328742C65297B746869732E616374696F6E5F636F6D706C657465643D21312C746869732E67616E7474';
wwv_flow_imp.g_varchar2_table(78) := '3D742C746869732E7461736B3D652C746869732E6E616D653D746869732E6E616D657C7C22227D707265706172655F777261707065727328297B746869732E67726F75703D66282267222C7B636C6173733A226261722D77726170706572222B28746869';
wwv_flow_imp.g_varchar2_table(79) := '732E7461736B2E637573746F6D5F636C6173733F2220222B746869732E7461736B2E637573746F6D5F636C6173733A2222292C22646174612D6964223A746869732E7461736B2E69647D292C746869732E6261725F67726F75703D66282267222C7B636C';
wwv_flow_imp.g_varchar2_table(80) := '6173733A226261722D67726F7570222C617070656E645F746F3A746869732E67726F75707D292C746869732E68616E646C655F67726F75703D66282267222C7B636C6173733A2268616E646C652D67726F7570222C617070656E645F746F3A746869732E';
wwv_flow_imp.g_varchar2_table(81) := '67726F75707D297D707265706172655F76616C75657328297B746869732E696E76616C69643D746869732E7461736B2E696E76616C69642C746869732E6865696768743D746869732E67616E74742E6F7074696F6E732E6261725F6865696768742C7468';
wwv_flow_imp.g_varchar2_table(82) := '69732E696D6167655F73697A653D746869732E6865696768742D352C746869732E7461736B2E5F73746172747C7C28746869732E7461736B2E5F73746172743D6E6577204461746528746869732E7461736B2E737461727429292C746869732E7461736B';
wwv_flow_imp.g_varchar2_table(83) := '2E5F656E647C7C28746869732E7461736B2E5F656E643D6E6577204461746528746869732E7461736B2E656E6429292C746869732E636F6D707574655F7828292C746869732E636F6D707574655F7928292C746869732E636F6D707574655F6475726174';
wwv_flow_imp.g_varchar2_table(84) := '696F6E28292C746869732E636F726E65725F7261646975733D746869732E67616E74742E6F7074696F6E732E6261725F636F726E65725F7261646975732C746869732E77696474683D746869732E67616E74742E636F6E6669672E636F6C756D6E5F7769';
wwv_flow_imp.g_varchar2_table(85) := '6474682A746869732E6475726174696F6E2C2821746869732E7461736B2E70726F67726573737C7C746869732E7461736B2E70726F67726573733C3029262628746869732E7461736B2E70726F67726573733D30292C746869732E7461736B2E70726F67';
wwv_flow_imp.g_varchar2_table(86) := '726573733E313030262628746869732E7461736B2E70726F67726573733D313030297D707265706172655F68656C7065727328297B535647456C656D656E742E70726F746F747970652E676574583D66756E6374696F6E28297B72657475726E2B746869';
wwv_flow_imp.g_varchar2_table(87) := '732E67657441747472696275746528227822297D2C535647456C656D656E742E70726F746F747970652E676574593D66756E6374696F6E28297B72657475726E2B746869732E67657441747472696275746528227922297D2C535647456C656D656E742E';
wwv_flow_imp.g_varchar2_table(88) := '70726F746F747970652E67657457696474683D66756E6374696F6E28297B72657475726E2B746869732E6765744174747269627574652822776964746822297D2C535647456C656D656E742E70726F746F747970652E6765744865696768743D66756E63';
wwv_flow_imp.g_varchar2_table(89) := '74696F6E28297B72657475726E2B746869732E676574417474726962757465282268656967687422297D2C535647456C656D656E742E70726F746F747970652E676574456E64583D66756E6374696F6E28297B72657475726E20746869732E6765745828';
wwv_flow_imp.g_varchar2_table(90) := '292B746869732E676574576964746828297D7D707265706172655F65787065637465645F70726F67726573735F76616C75657328297B746869732E636F6D707574655F65787065637465645F70726F677265737328292C746869732E6578706563746564';
wwv_flow_imp.g_varchar2_table(91) := '5F70726F67726573735F77696474683D746869732E67616E74742E6F7074696F6E732E636F6C756D6E5F77696474682A746869732E6475726174696F6E2A28746869732E65787065637465645F70726F67726573732F313030297C7C307D647261772829';
wwv_flow_imp.g_varchar2_table(92) := '7B746869732E647261775F62617228292C746869732E647261775F70726F67726573735F62617228292C746869732E67616E74742E6F7074696F6E732E73686F775F65787065637465645F70726F6772657373262628746869732E707265706172655F65';
wwv_flow_imp.g_varchar2_table(93) := '787065637465645F70726F67726573735F76616C75657328292C746869732E647261775F65787065637465645F70726F67726573735F6261722829292C746869732E647261775F6C6162656C28292C746869732E647261775F726573697A655F68616E64';
wwv_flow_imp.g_varchar2_table(94) := '6C657328292C746869732E7461736B2E7468756D626E61696C2626746869732E647261775F7468756D626E61696C28297D647261775F62617228297B746869732E246261723D66282272656374222C7B783A746869732E782C793A746869732E792C7769';
wwv_flow_imp.g_varchar2_table(95) := '6474683A746869732E77696474682C6865696768743A746869732E6865696768742C72783A746869732E636F726E65725F7261646975732C72793A746869732E636F726E65725F7261646975732C636C6173733A22626172222C617070656E645F746F3A';
wwv_flow_imp.g_varchar2_table(96) := '746869732E6261725F67726F75707D292C746869732E7461736B2E636F6C6F72262628746869732E246261722E7374796C652E66696C6C3D746869732E7461736B2E636F6C6F72292C5928746869732E246261722C227769647468222C302C746869732E';
wwv_flow_imp.g_varchar2_table(97) := '7769647468292C746869732E696E76616C69642626746869732E246261722E636C6173734C6973742E61646428226261722D696E76616C696422297D647261775F65787065637465645F70726F67726573735F62617228297B746869732E696E76616C69';
wwv_flow_imp.g_varchar2_table(98) := '647C7C28746869732E2465787065637465645F6261725F70726F67726573733D66282272656374222C7B783A746869732E782C793A746869732E792C77696474683A746869732E65787065637465645F70726F67726573735F77696474682C6865696768';
wwv_flow_imp.g_varchar2_table(99) := '743A746869732E6865696768742C72783A746869732E636F726E65725F7261646975732C72793A746869732E636F726E65725F7261646975732C636C6173733A226261722D65787065637465642D70726F6772657373222C617070656E645F746F3A7468';
wwv_flow_imp.g_varchar2_table(100) := '69732E6261725F67726F75707D292C5928746869732E2465787065637465645F6261725F70726F67726573732C227769647468222C302C746869732E65787065637465645F70726F67726573735F776964746829297D647261775F70726F67726573735F';
wwv_flow_imp.g_varchar2_table(101) := '62617228297B696628746869732E696E76616C69642972657475726E3B746869732E70726F67726573735F77696474683D746869732E63616C63756C6174655F70726F67726573735F776964746828293B6C657420743D746869732E636F726E65725F72';
wwv_flow_imp.g_varchar2_table(102) := '61646975733B2F5E28283F216368726F6D657C616E64726F6964292E292A7361666172692F692E74657374286E6176696761746F722E757365724167656E74297C7C28743D746869732E636F726E65725F7261646975732B32292C746869732E24626172';
wwv_flow_imp.g_varchar2_table(103) := '5F70726F67726573733D66282272656374222C7B783A746869732E782C793A746869732E792C77696474683A746869732E70726F67726573735F77696474682C6865696768743A746869732E6865696768742C72783A742C72793A742C636C6173733A22';
wwv_flow_imp.g_varchar2_table(104) := '6261722D70726F6772657373222C617070656E645F746F3A746869732E6261725F67726F75707D292C746869732E7461736B2E636F6C6F725F70726F6772657373262628746869732E246261725F70726F67726573732E7374796C652E66696C6C3D7468';
wwv_flow_imp.g_varchar2_table(105) := '69732E7461736B2E636F6C6F725F70726F6772657373293B636F6E737420653D642E6469666628746869732E7461736B2E5F73746172742C746869732E67616E74742E67616E74745F73746172742C746869732E67616E74742E636F6E6669672E756E69';
wwv_flow_imp.g_varchar2_table(106) := '74292F746869732E67616E74742E636F6E6669672E737465702A746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B6C657420693D746869732E67616E74742E6372656174655F656C287B636C61737365733A60646174652D72';
wwv_flow_imp.g_varchar2_table(107) := '616E67652D686967686C69676874206869646520686967686C696768742D247B746869732E7461736B2E69647D602C77696474683A746869732E77696474682C6C6566743A657D293B746869732E24646174655F686967686C696768743D692C74686973';
wwv_flow_imp.g_varchar2_table(108) := '2E67616E74742E246C6F7765725F6865616465722E70726570656E6428746869732E24646174655F686967686C69676874292C5928746869732E246261725F70726F67726573732C227769647468222C302C746869732E70726F67726573735F77696474';
wwv_flow_imp.g_varchar2_table(109) := '68297D63616C63756C6174655F70726F67726573735F776964746828297B636F6E737420743D746869732E246261722E676574576964746828292C653D746869732E782B742C693D746869732E67616E74742E636F6E6669672E69676E6F7265645F706F';
wwv_flow_imp.g_varchar2_table(110) := '736974696F6E732E7265647563652828682C67293D3E682B28673E3D746869732E782626673C65292C30292A746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B6C657420733D28742D69292A746869732E7461736B2E70726F';
wwv_flow_imp.g_varchar2_table(111) := '67726573732F3130303B636F6E737420723D746869732E782B732C613D746869732E67616E74742E636F6E6669672E69676E6F7265645F706F736974696F6E732E7265647563652828682C67293D3E682B28673E3D746869732E782626673C72292C3029';
wwv_flow_imp.g_varchar2_table(112) := '2A746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B732B3D613B6C6574206F3D746869732E67616E74742E6765745F69676E6F7265645F726567696F6E28746869732E782B73293B666F72283B6F2E6C656E6774683B29732B';
wwv_flow_imp.g_varchar2_table(113) := '3D746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474682C6F3D746869732E67616E74742E6765745F69676E6F7265645F726567696F6E28746869732E782B73293B72657475726E20746869732E70726F67726573735F7769647468';
wwv_flow_imp.g_varchar2_table(114) := '3D732C737D647261775F6C6162656C28297B6C657420743D746869732E782B746869732E246261722E676574576964746828292F323B746869732E7461736B2E7468756D626E61696C262628743D746869732E782B746869732E696D6167655F73697A65';
wwv_flow_imp.g_varchar2_table(115) := '2B35292C66282274657874222C7B783A742C793A746869732E792B746869732E6865696768742F322C696E6E657248544D4C3A746869732E7461736B2E6E616D652C636C6173733A226261722D6C6162656C222C617070656E645F746F3A746869732E62';
wwv_flow_imp.g_varchar2_table(116) := '61725F67726F75707D292C72657175657374416E696D6174696F6E4672616D652828293D3E746869732E7570646174655F6C6162656C5F706F736974696F6E2829297D647261775F7468756D626E61696C28297B6C657420743D31302C653D322C692C73';
wwv_flow_imp.g_varchar2_table(117) := '3B693D66282264656673222C7B617070656E645F746F3A746869732E6261725F67726F75707D292C66282272656374222C7B69643A22726563745F222B746869732E7461736B2E69642C783A746869732E782B742C793A746869732E792B652C77696474';
wwv_flow_imp.g_varchar2_table(118) := '683A746869732E696D6167655F73697A652C6865696768743A746869732E696D6167655F73697A652C72783A223135222C636C6173733A22696D675F6D61736B222C617070656E645F746F3A697D292C733D662822636C697050617468222C7B69643A22';
wwv_flow_imp.g_varchar2_table(119) := '636C69705F222B746869732E7461736B2E69642C617070656E645F746F3A697D292C662822757365222C7B687265663A2223726563745F222B746869732E7461736B2E69642C617070656E645F746F3A737D292C662822696D616765222C7B783A746869';
wwv_flow_imp.g_varchar2_table(120) := '732E782B742C793A746869732E792B652C77696474683A746869732E696D6167655F73697A652C6865696768743A746869732E696D6167655F73697A652C636C6173733A226261722D696D67222C687265663A746869732E7461736B2E7468756D626E61';
wwv_flow_imp.g_varchar2_table(121) := '696C2C636C6970506174683A22636C69705F222B746869732E7461736B2E69642C617070656E645F746F3A746869732E6261725F67726F75707D297D647261775F726573697A655F68616E646C657328297B696628746869732E696E76616C69647C7C74';
wwv_flow_imp.g_varchar2_table(122) := '6869732E67616E74742E6F7074696F6E732E726561646F6E6C792972657475726E3B636F6E737420743D746869732E246261722C653D333B696628746869732E68616E646C65733D5B5D2C21746869732E67616E74742E6F7074696F6E732E726561646F';
wwv_flow_imp.g_varchar2_table(123) := '6E6C795F6461746573262621746869732E67616E74742E6F7074696F6E732E66697865645F6475726174696F6E262628746869732E68616E646C65732E707573682866282272656374222C7B783A742E676574456E645828292D652F322C793A742E6765';
wwv_flow_imp.g_varchar2_table(124) := '745928292B746869732E6865696768742F342C77696474683A652C6865696768743A746869732E6865696768742F322C72783A322C72793A322C636C6173733A2268616E646C65207269676874222C617070656E645F746F3A746869732E68616E646C65';
wwv_flow_imp.g_varchar2_table(125) := '5F67726F75707D29292C746869732E68616E646C65732E707573682866282272656374222C7B783A742E6765745828292D652F322C793A742E6765745928292B746869732E6865696768742F342C77696474683A652C6865696768743A746869732E6865';
wwv_flow_imp.g_varchar2_table(126) := '696768742F322C72783A322C72793A322C636C6173733A2268616E646C65206C656674222C617070656E645F746F3A746869732E68616E646C655F67726F75707D2929292C21746869732E67616E74742E6F7074696F6E732E726561646F6E6C795F7072';
wwv_flow_imp.g_varchar2_table(127) := '6F6772657373297B636F6E737420693D746869732E246261725F70726F67726573733B746869732E2468616E646C655F70726F67726573733D662822636972636C65222C7B63783A692E676574456E645828292C63793A692E6765745928292B692E6765';
wwv_flow_imp.g_varchar2_table(128) := '7448656967687428292F322C723A342E352C636C6173733A2268616E646C652070726F6772657373222C617070656E645F746F3A746869732E68616E646C655F67726F75707D292C746869732E68616E646C65732E7075736828746869732E2468616E64';
wwv_flow_imp.g_varchar2_table(129) := '6C655F70726F6772657373297D666F72286C65742069206F6620746869732E68616E646C657329632E6F6E28692C226D6F757365656E746572222C28293D3E692E636C6173734C6973742E61646428226163746976652229292C632E6F6E28692C226D6F';
wwv_flow_imp.g_varchar2_table(130) := '7573656C65617665222C28293D3E692E636C6173734C6973742E72656D6F766528226163746976652229297D62696E6428297B746869732E696E76616C69647C7C746869732E73657475705F636C69636B5F6576656E7428297D73657475705F636C6963';
wwv_flow_imp.g_varchar2_table(131) := '6B5F6576656E7428297B6C657420743D746869732E7461736B2E69643B632E6F6E28746869732E67726F75702C226D6F7573656F766572222C733D3E7B746869732E67616E74742E747269676765725F6576656E742822686F766572222C5B746869732E';
wwv_flow_imp.g_varchar2_table(132) := '7461736B2C732E73637265656E582C732E73637265656E592C735D297D292C746869732E67616E74742E6F7074696F6E732E706F7075705F6F6E3D3D3D22636C69636B222626632E6F6E28746869732E67726F75702C226D6F7573657570222C733D3E7B';
wwv_flow_imp.g_varchar2_table(133) := '636F6E737420723D732E6F6666736574587C7C732E6C61796572583B696628746869732E2468616E646C655F70726F6772657373297B636F6E737420613D2B746869732E2468616E646C655F70726F67726573732E676574417474726962757465282263';
wwv_flow_imp.g_varchar2_table(134) := '7822293B696628613E722D312626613C722B317C7C746869732E67616E74742E6261725F6265696E675F647261676765642972657475726E7D746869732E67616E74742E73686F775F706F707570287B783A732E6F6666736574587C7C732E6C61796572';
wwv_flow_imp.g_varchar2_table(135) := '582C793A732E6F6666736574597C7C732E6C61796572592C7461736B3A746869732E7461736B2C7461726765743A746869732E246261727D297D293B6C657420653B632E6F6E28746869732E67726F75702C226D6F757365656E746572222C733D3E7B65';
wwv_flow_imp.g_varchar2_table(136) := '3D73657454696D656F75742828293D3E7B746869732E67616E74742E6F7074696F6E732E706F7075705F6F6E3D3D3D22686F766572222626746869732E67616E74742E73686F775F706F707570287B783A732E6F6666736574587C7C732E6C6179657258';
wwv_flow_imp.g_varchar2_table(137) := '2C793A732E6F6666736574597C7C732E6C61796572592C7461736B3A746869732E7461736B2C7461726765743A746869732E246261727D292C746869732E67616E74742E24636F6E7461696E65722E717565727953656C6563746F7228602E686967686C';
wwv_flow_imp.g_varchar2_table(138) := '696768742D247B747D60292E636C6173734C6973742E72656D6F766528226869646522297D2C323030297D292C632E6F6E28746869732E67726F75702C226D6F7573656C65617665222C28293D3E7B76617220732C723B636C65617254696D656F757428';
wwv_flow_imp.g_varchar2_table(139) := '65292C746869732E67616E74742E6F7074696F6E732E706F7075705F6F6E3D3D3D22686F7665722226262828723D28733D746869732E67616E74742E706F707570293D3D6E756C6C3F766F696420303A732E68696465293D3D6E756C6C7C7C722E63616C';
wwv_flow_imp.g_varchar2_table(140) := '6C287329292C746869732E67616E74742E24636F6E7461696E65722E717565727953656C6563746F7228602E686967686C696768742D247B747D60292E636C6173734C6973742E61646428226869646522297D292C632E6F6E28746869732E67726F7570';
wwv_flow_imp.g_varchar2_table(141) := '2C22636C69636B222C28293D3E7B746869732E67616E74742E747269676765725F6576656E742822636C69636B222C5B746869732E7461736B5D297D292C632E6F6E28746869732E67726F75702C2264626C636C69636B222C733D3E7B746869732E6163';
wwv_flow_imp.g_varchar2_table(142) := '74696F6E5F636F6D706C657465647C7C28746869732E67726F75702E636C6173734C6973742E72656D6F7665282261637469766522292C746869732E67616E74742E706F7075702626746869732E67616E74742E706F7075702E706172656E742E636C61';
wwv_flow_imp.g_varchar2_table(143) := '73734C6973742E72656D6F766528226869646522292C746869732E67616E74742E747269676765725F6576656E742822646F75626C655F636C69636B222C5B746869732E7461736B5D29297D293B6C657420693D21313B632E6F6E28746869732E67726F';
wwv_flow_imp.g_varchar2_table(144) := '75702C22746F7563687374617274222C733D3E7B69662821692972657475726E20693D21302C73657454696D656F75742866756E6374696F6E28297B693D21317D2C333030292C21313B732E70726576656E7444656661756C7428292C21746869732E61';
wwv_flow_imp.g_varchar2_table(145) := '6374696F6E5F636F6D706C65746564262628746869732E67726F75702E636C6173734C6973742E72656D6F7665282261637469766522292C746869732E67616E74742E706F7075702626746869732E67616E74742E706F7075702E706172656E742E636C';
wwv_flow_imp.g_varchar2_table(146) := '6173734C6973742E72656D6F766528226869646522292C746869732E67616E74742E747269676765725F6576656E742822646F75626C655F636C69636B222C5B746869732E7461736B5D29297D297D7570646174655F6261725F706F736974696F6E287B';
wwv_flow_imp.g_varchar2_table(147) := '783A743D6E756C6C2C77696474683A653D6E756C6C7D297B636F6E737420693D746869732E246261723B69662874297B69662821746869732E7461736B2E646570656E64656E636965732E6D617028613D3E746869732E67616E74742E6765745F626172';
wwv_flow_imp.g_varchar2_table(148) := '2861292E246261722E676574582829292E7265647563652828612C6F293D3E612626743E3D6F2C2130292972657475726E3B746869732E7570646174655F6174747228692C2278222C74292C746869732E783D742C746869732E24646174655F68696768';
wwv_flow_imp.g_varchar2_table(149) := '6C696768742E7374796C652E6C6566743D742B227078227D653E30262628746869732E7570646174655F6174747228692C227769647468222C65292C746869732E24646174655F686967686C696768742E7374796C652E77696474683D652B2270782229';
wwv_flow_imp.g_varchar2_table(150) := '2C746869732E7570646174655F6C6162656C5F706F736974696F6E28292C746869732E7570646174655F68616E646C655F706F736974696F6E28292C746869732E646174655F6368616E67656428292C746869732E636F6D707574655F6475726174696F';
wwv_flow_imp.g_varchar2_table(151) := '6E28292C746869732E67616E74742E6F7074696F6E732E73686F775F65787065637465645F70726F67726573732626746869732E7570646174655F65787065637465645F70726F67726573736261725F706F736974696F6E28292C746869732E75706461';
wwv_flow_imp.g_varchar2_table(152) := '74655F70726F67726573736261725F706F736974696F6E28292C746869732E7570646174655F6172726F775F706F736974696F6E28297D7570646174655F6C6162656C5F706F736974696F6E5F6F6E5F686F72697A6F6E74616C5F7363726F6C6C287B78';
wwv_flow_imp.g_varchar2_table(153) := '3A742C73783A657D297B636F6E737420693D746869732E67616E74742E24636F6E7461696E65722C733D746869732E67726F75702E717565727953656C6563746F7228222E6261722D6C6162656C22292C723D746869732E67726F75702E717565727953';
wwv_flow_imp.g_varchar2_table(154) := '656C6563746F7228222E6261722D696D6722297C7C22222C613D746869732E6261725F67726F75702E717565727953656C6563746F7228222E696D675F6D61736B22297C7C22223B6C6574206F3D746869732E246261722E6765745828292B746869732E';
wwv_flow_imp.g_varchar2_table(155) := '246261722E676574576964746828292C683D732E6765745828292B742C673D722626722E6765745828292B747C7C302C6C3D722626722E67657442426F7828292E77696474682B377C7C372C5F3D682B732E67657442426F7828292E77696474682B372C';
wwv_flow_imp.g_varchar2_table(156) := '703D652B692E636C69656E7457696474682F323B732E636C6173734C6973742E636F6E7461696E73282262696722297C7C285F3C6F2626743E3026265F3C707C7C682D6C3E746869732E246261722E6765745828292626743C3026265F3E702926262873';
wwv_flow_imp.g_varchar2_table(157) := '2E736574417474726962757465282278222C68292C72262628722E736574417474726962757465282278222C67292C612E736574417474726962757465282278222C672929297D646174655F6368616E67656428297B6C657420743D21313B636F6E7374';
wwv_flow_imp.g_varchar2_table(158) := '7B6E65775F73746172745F646174653A652C6E65775F656E645F646174653A697D3D746869732E636F6D707574655F73746172745F656E645F6461746528293B4E756D62657228746869732E7461736B2E5F737461727429213D3D4E756D626572286529';
wwv_flow_imp.g_varchar2_table(159) := '262628743D21302C746869732E7461736B2E5F73746172743D65292C4E756D62657228746869732E7461736B2E5F656E6429213D3D4E756D626572286929262628743D21302C746869732E7461736B2E5F656E643D69292C742626746869732E67616E74';
wwv_flow_imp.g_varchar2_table(160) := '742E747269676765725F6576656E742822646174655F6368616E6765222C5B746869732E7461736B2C652C642E61646428692C2D312C227365636F6E6422295D297D70726F67726573735F6368616E67656428297B746869732E7461736B2E70726F6772';
wwv_flow_imp.g_varchar2_table(161) := '6573733D746869732E636F6D707574655F70726F677265737328292C746869732E67616E74742E747269676765725F6576656E74282270726F67726573735F6368616E6765222C5B746869732E7461736B2C746869732E7461736B2E70726F6772657373';
wwv_flow_imp.g_varchar2_table(162) := '5D297D7365745F616374696F6E5F636F6D706C6574656428297B746869732E616374696F6E5F636F6D706C657465643D21302C73657454696D656F75742828293D3E746869732E616374696F6E5F636F6D706C657465643D21312C316533297D636F6D70';
wwv_flow_imp.g_varchar2_table(163) := '7574655F73746172745F656E645F6461746528297B636F6E737420743D746869732E246261722C653D742E6765745828292F746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B6C657420693D642E61646428746869732E6761';
wwv_flow_imp.g_varchar2_table(164) := '6E74742E67616E74745F73746172742C652A746869732E67616E74742E636F6E6669672E737465702C746869732E67616E74742E636F6E6669672E756E6974293B636F6E737420733D742E676574576964746828292F746869732E67616E74742E636F6E';
wwv_flow_imp.g_varchar2_table(165) := '6669672E636F6C756D6E5F77696474682C723D642E61646428692C732A746869732E67616E74742E636F6E6669672E737465702C746869732E67616E74742E636F6E6669672E756E6974293B72657475726E7B6E65775F73746172745F646174653A692C';
wwv_flow_imp.g_varchar2_table(166) := '6E65775F656E645F646174653A727D7D636F6D707574655F70726F677265737328297B746869732E70726F67726573735F77696474683D746869732E246261725F70726F67726573732E676574576964746828292C746869732E783D746869732E246261';
wwv_flow_imp.g_varchar2_table(167) := '725F70726F67726573732E67657442426F7828292E783B636F6E737420743D746869732E782B746869732E70726F67726573735F77696474682C653D746869732E70726F67726573735F77696474682D746869732E67616E74742E636F6E6669672E6967';
wwv_flow_imp.g_varchar2_table(168) := '6E6F7265645F706F736974696F6E732E7265647563652828732C72293D3E732B28723E3D746869732E782626723C3D74292C30292A746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B696628653C302972657475726E20303B';
wwv_flow_imp.g_varchar2_table(169) := '636F6E737420693D746869732E246261722E676574576964746828292D746869732E69676E6F7265645F6475726174696F6E5F7261772A746869732E67616E74742E636F6E6669672E636F6C756D6E5F77696474683B72657475726E207061727365496E';
wwv_flow_imp.g_varchar2_table(170) := '7428652F692A3130302C3130297D636F6D707574655F65787065637465645F70726F677265737328297B746869732E65787065637465645F70726F67726573733D642E6469666628642E746F64617928292C746869732E7461736B2E5F73746172742C22';
wwv_flow_imp.g_varchar2_table(171) := '686F757222292F746869732E67616E74742E636F6E6669672E737465702C746869732E65787065637465645F70726F67726573733D28746869732E65787065637465645F70726F67726573733C746869732E6475726174696F6E3F746869732E65787065';
wwv_flow_imp.g_varchar2_table(172) := '637465645F70726F67726573733A746869732E6475726174696F6E292A3130302F746869732E6475726174696F6E7D636F6D707574655F7828297B636F6E73747B636F6C756D6E5F77696474683A747D3D746869732E67616E74742E636F6E6669672C65';
wwv_flow_imp.g_varchar2_table(173) := '3D746869732E7461736B2E5F73746172742C693D746869732E67616E74742E67616E74745F73746172743B6C657420723D642E6469666628652C692C746869732E67616E74742E636F6E6669672E756E6974292F746869732E67616E74742E636F6E6669';
wwv_flow_imp.g_varchar2_table(174) := '672E737465702A743B746869732E783D727D636F6D707574655F7928297B746869732E793D746869732E67616E74742E636F6E6669672E6865616465725F6865696768742B746869732E67616E74742E6F7074696F6E732E70616464696E672F322B7468';
wwv_flow_imp.g_varchar2_table(175) := '69732E7461736B2E5F696E6465782A28746869732E6865696768742B746869732E67616E74742E6F7074696F6E732E70616464696E67297D636F6D707574655F6475726174696F6E28297B6C657420743D302C653D303B666F72286C657420693D6E6577';
wwv_flow_imp.g_varchar2_table(176) := '204461746528746869732E7461736B2E5F7374617274293B693C746869732E7461736B2E5F656E643B692E7365744461746528692E6765744461746528292B312929652B2B2C21746869732E67616E74742E636F6E6669672E69676E6F7265645F646174';
wwv_flow_imp.g_varchar2_table(177) := '65732E66696E6428733D3E732E67657454696D6528293D3D3D692E67657454696D6528292926262821746869732E67616E74742E636F6E6669672E69676E6F7265645F66756E6374696F6E7C7C21746869732E67616E74742E636F6E6669672E69676E6F';
wwv_flow_imp.g_varchar2_table(178) := '7265645F66756E6374696F6E286929292626742B2B3B746869732E7461736B2E61637475616C5F6475726174696F6E3D742C746869732E7461736B2E69676E6F7265645F6475726174696F6E3D652D742C746869732E6475726174696F6E3D642E636F6E';
wwv_flow_imp.g_varchar2_table(179) := '766572745F7363616C657328652B2264222C746869732E67616E74742E636F6E6669672E756E6974292F746869732E67616E74742E636F6E6669672E737465702C746869732E61637475616C5F6475726174696F6E5F7261773D642E636F6E766572745F';
wwv_flow_imp.g_varchar2_table(180) := '7363616C657328742B2264222C746869732E67616E74742E636F6E6669672E756E6974292F746869732E67616E74742E636F6E6669672E737465702C746869732E69676E6F7265645F6475726174696F6E5F7261773D746869732E6475726174696F6E2D';
wwv_flow_imp.g_varchar2_table(181) := '746869732E61637475616C5F6475726174696F6E5F7261777D7570646174655F6174747228742C652C69297B72657475726E20693D2B692C69734E614E2869297C7C742E73657441747472696275746528652C69292C747D7570646174655F6578706563';
wwv_flow_imp.g_varchar2_table(182) := '7465645F70726F67726573736261725F706F736974696F6E28297B746869732E696E76616C69647C7C28746869732E2465787065637465645F6261725F70726F67726573732E736574417474726962757465282278222C746869732E246261722E676574';
wwv_flow_imp.g_varchar2_table(183) := '582829292C746869732E636F6D707574655F65787065637465645F70726F677265737328292C746869732E2465787065637465645F6261725F70726F67726573732E73657441747472696275746528227769647468222C746869732E67616E74742E636F';
wwv_flow_imp.g_varchar2_table(184) := '6E6669672E636F6C756D6E5F77696474682A746869732E61637475616C5F6475726174696F6E5F7261772A28746869732E65787065637465645F70726F67726573732F313030297C7C3029297D7570646174655F70726F67726573736261725F706F7369';
wwv_flow_imp.g_varchar2_table(185) := '74696F6E28297B746869732E696E76616C69647C7C746869732E67616E74742E6F7074696F6E732E726561646F6E6C797C7C28746869732E246261725F70726F67726573732E736574417474726962757465282278222C746869732E246261722E676574';
wwv_flow_imp.g_varchar2_table(186) := '582829292C746869732E246261725F70726F67726573732E73657441747472696275746528227769647468222C746869732E63616C63756C6174655F70726F67726573735F7769647468282929297D7570646174655F6C6162656C5F706F736974696F6E';
wwv_flow_imp.g_varchar2_table(187) := '28297B636F6E737420743D746869732E6261725F67726F75702E717565727953656C6563746F7228222E696D675F6D61736B22297C7C22222C653D746869732E246261722C693D746869732E67726F75702E717565727953656C6563746F7228222E6261';
wwv_flow_imp.g_varchar2_table(188) := '722D6C6162656C22292C733D746869732E67726F75702E717565727953656C6563746F7228222E6261722D696D6722293B6C657420723D352C613D746869732E696D6167655F73697A652B31303B636F6E7374206F3D692E67657442426F7828292E7769';
wwv_flow_imp.g_varchar2_table(189) := '6474682C683D652E676574576964746828293B6F3E683F28692E636C6173734C6973742E616464282262696722292C733F28732E736574417474726962757465282278222C652E676574456E645828292B72292C742E7365744174747269627574652822';
wwv_flow_imp.g_varchar2_table(190) := '78222C652E676574456E645828292B72292C692E736574417474726962757465282278222C652E676574456E645828292B6129293A692E736574417474726962757465282278222C652E676574456E645828292B7229293A28692E636C6173734C697374';
wwv_flow_imp.g_varchar2_table(191) := '2E72656D6F7665282262696722292C733F28732E736574417474726962757465282278222C652E6765745828292B72292C742E736574417474726962757465282278222C652E6765745828292B72292C692E736574417474726962757465282278222C65';
wwv_flow_imp.g_varchar2_table(192) := '2E6765745828292B682F322B6129293A692E736574417474726962757465282278222C652E6765745828292B682F322D6F2F3229297D7570646174655F68616E646C655F706F736974696F6E28297B696628746869732E696E76616C69647C7C74686973';
wwv_flow_imp.g_varchar2_table(193) := '2E67616E74742E6F7074696F6E732E726561646F6E6C792972657475726E3B636F6E737420743D746869732E246261723B746869732E68616E646C655F67726F75702E717565727953656C6563746F7228222E68616E646C652E6C65667422292E736574';
wwv_flow_imp.g_varchar2_table(194) := '417474726962757465282278222C742E676574582829292C746869732E68616E646C655F67726F75702E717565727953656C6563746F7228222E68616E646C652E726967687422292E736574417474726962757465282278222C742E676574456E645828';
wwv_flow_imp.g_varchar2_table(195) := '29293B636F6E737420653D746869732E67726F75702E717565727953656C6563746F7228222E68616E646C652E70726F677265737322293B652626652E73657441747472696275746528226378222C746869732E246261725F70726F67726573732E6765';
wwv_flow_imp.g_varchar2_table(196) := '74456E64582829297D7570646174655F6172726F775F706F736974696F6E28297B746869732E6172726F77733D746869732E6172726F77737C7C5B5D3B666F72286C65742074206F6620746869732E6172726F777329742E75706461746528297D7D636C';
wwv_flow_imp.g_varchar2_table(197) := '61737320467B636F6E7374727563746F7228742C652C69297B746869732E706172656E743D742C746869732E706F7075705F66756E633D652C746869732E67616E74743D692C746869732E6D616B6528297D6D616B6528297B746869732E706172656E74';
wwv_flow_imp.g_varchar2_table(198) := '2E696E6E657248544D4C3D600A2020202020202020202020203C64697620636C6173733D227469746C65223E3C2F6469763E0A2020202020202020202020203C64697620636C6173733D227375627469746C65223E3C2F6469763E0A2020202020202020';
wwv_flow_imp.g_varchar2_table(199) := '202020203C64697620636C6173733D2264657461696C73223E3C2F6469763E0A2020202020202020202020203C64697620636C6173733D22616374696F6E73223E3C2F6469763E0A2020202020202020602C746869732E6869646528292C746869732E74';
wwv_flow_imp.g_varchar2_table(200) := '69746C653D746869732E706172656E742E717565727953656C6563746F7228222E7469746C6522292C746869732E7375627469746C653D746869732E706172656E742E717565727953656C6563746F7228222E7375627469746C6522292C746869732E64';
wwv_flow_imp.g_varchar2_table(201) := '657461696C733D746869732E706172656E742E717565727953656C6563746F7228222E64657461696C7322292C746869732E616374696F6E733D746869732E706172656E742E717565727953656C6563746F7228222E616374696F6E7322297D73686F77';
wwv_flow_imp.g_varchar2_table(202) := '287B783A742C793A652C7461736B3A692C7461726765743A737D297B746869732E616374696F6E732E696E6E657248544D4C3D22223B6C657420723D746869732E706F7075705F66756E63287B7461736B3A692C63686172743A746869732E67616E7474';
wwv_flow_imp.g_varchar2_table(203) := '2C6765745F7469746C653A28293D3E746869732E7469746C652C7365745F7469746C653A613D3E746869732E7469746C652E696E6E657248544D4C3D612C6765745F7375627469746C653A28293D3E746869732E7375627469746C652C7365745F737562';
wwv_flow_imp.g_varchar2_table(204) := '7469746C653A613D3E746869732E7375627469746C652E696E6E657248544D4C3D612C6765745F64657461696C733A28293D3E746869732E64657461696C732C7365745F64657461696C733A613D3E746869732E64657461696C732E696E6E657248544D';
wwv_flow_imp.g_varchar2_table(205) := '4C3D612C6164645F616374696F6E3A28612C6F293D3E7B6C657420683D746869732E67616E74742E6372656174655F656C287B636C61737365733A22616374696F6E2D62746E222C747970653A22627574746F6E222C617070656E645F746F3A74686973';
wwv_flow_imp.g_varchar2_table(206) := '2E616374696F6E737D293B747970656F6620613D3D2266756E6374696F6E22262628613D61286929292C682E696E6E657248544D4C3D612C682E6F6E636C69636B3D673D3E6F28692C746869732E67616E74742C67297D7D293B72213D3D213126262872';
wwv_flow_imp.g_varchar2_table(207) := '262628746869732E706172656E742E696E6E657248544D4C3D72292C746869732E616374696F6E732E696E6E657248544D4C3D3D3D22223F746869732E616374696F6E732E72656D6F766528293A746869732E706172656E742E617070656E644368696C';
wwv_flow_imp.g_varchar2_table(208) := '6428746869732E616374696F6E73292C746869732E706172656E742E7374796C652E6C6566743D742B31302B227078222C746869732E706172656E742E7374796C652E746F703D652D31302B227078222C746869732E706172656E742E636C6173734C69';
wwv_flow_imp.g_varchar2_table(209) := '73742E72656D6F76652822686964652229297D6869646528297B746869732E706172656E742E636C6173734C6973742E61646428226869646522297D7D66756E6374696F6E2041286E297B636F6E737420743D6E2E67657446756C6C5965617228293B72';
wwv_flow_imp.g_varchar2_table(210) := '657475726E20742D742531302B22227D66756E6374696F6E204F286E2C742C65297B6C657420693D642E616464286E2C362C2264617922292C733D692E6765744D6F6E74682829213D3D6E2E6765744D6F6E746828293F2244204D4D4D223A2244222C72';
wwv_flow_imp.g_varchar2_table(211) := '3D21747C7C6E2E6765744D6F6E74682829213D3D742E6765744D6F6E746828293F2244204D4D4D223A2244223B72657475726E60247B642E666F726D6174286E2C722C65297D202D20247B642E666F726D617428692C732C65297D607D636F6E73742077';
wwv_flow_imp.g_varchar2_table(212) := '3D5B7B6E616D653A22486F7572222C70616464696E673A223764222C737465703A223168222C646174655F666F726D61743A22595959592D4D4D2D44442048483A222C6C6F7765725F746578743A224848222C75707065725F746578743A286E2C742C65';
wwv_flow_imp.g_varchar2_table(213) := '293D3E21747C7C6E2E676574446174652829213D3D742E6765744461746528293F642E666F726D6174286E2C2244204D4D4D4D222C65293A22222C75707065725F746578745F6672657175656E63793A32347D2C7B6E616D653A22517561727465722044';
wwv_flow_imp.g_varchar2_table(214) := '6179222C70616464696E673A223764222C737465703A223668222C646174655F666F726D61743A22595959592D4D4D2D44442048483A222C6C6F7765725F746578743A224848222C75707065725F746578743A286E2C742C65293D3E21747C7C6E2E6765';
wwv_flow_imp.g_varchar2_table(215) := '74446174652829213D3D742E6765744461746528293F642E666F726D6174286E2C2244204D4D4D222C65293A22222C75707065725F746578745F6672657175656E63793A347D2C7B6E616D653A2248616C6620446179222C70616464696E673A22313464';
wwv_flow_imp.g_varchar2_table(216) := '222C737465703A22313268222C646174655F666F726D61743A22595959592D4D4D2D44442048483A222C6C6F7765725F746578743A224848222C75707065725F746578743A286E2C742C65293D3E21747C7C6E2E676574446174652829213D3D742E6765';
wwv_flow_imp.g_varchar2_table(217) := '744461746528293F6E2E6765744D6F6E74682829213D3D6E2E6765744D6F6E746828293F642E666F726D6174286E2C2244204D4D4D222C65293A642E666F726D6174286E2C2244222C65293A22222C75707065725F746578745F6672657175656E63793A';
wwv_flow_imp.g_varchar2_table(218) := '327D2C7B6E616D653A22446179222C70616464696E673A223764222C646174655F666F726D61743A22595959592D4D4D2D4444222C737465703A223164222C6C6F7765725F746578743A286E2C742C65293D3E21747C7C6E2E676574446174652829213D';
wwv_flow_imp.g_varchar2_table(219) := '3D742E6765744461746528293F642E666F726D6174286E2C2244222C65293A22222C75707065725F746578743A286E2C742C65293D3E21747C7C6E2E6765744D6F6E74682829213D3D742E6765744D6F6E746828293F642E666F726D6174286E2C224D4D';
wwv_flow_imp.g_varchar2_table(220) := '4D4D222C65293A22222C746869636B5F6C696E653A6E3D3E6E2E67657444617928293D3D3D317D2C7B6E616D653A225765656B222C70616464696E673A22316D222C737465703A223764222C646174655F666F726D61743A22595959592D4D4D2D444422';
wwv_flow_imp.g_varchar2_table(221) := '2C636F6C756D6E5F77696474683A3134302C6C6F7765725F746578743A4F2C75707065725F746578743A286E2C742C65293D3E21747C7C6E2E6765744D6F6E74682829213D3D742E6765744D6F6E746828293F642E666F726D6174286E2C224D4D4D4D22';
wwv_flow_imp.g_varchar2_table(222) := '2C65293A22222C746869636B5F6C696E653A6E3D3E6E2E6765744461746528293E3D3126266E2E6765744461746528293C3D372C75707065725F746578745F6672657175656E63793A347D2C7B6E616D653A224D6F6E7468222C70616464696E673A2232';
wwv_flow_imp.g_varchar2_table(223) := '6D222C737465703A22316D222C636F6C756D6E5F77696474683A3132302C646174655F666F726D61743A22595959592D4D4D222C6C6F7765725F746578743A224D4D4D4D222C75707065725F746578743A286E2C742C65293D3E21747C7C6E2E67657446';
wwv_flow_imp.g_varchar2_table(224) := '756C6C596561722829213D3D742E67657446756C6C5965617228293F642E666F726D6174286E2C2259595959222C65293A22222C746869636B5F6C696E653A6E3D3E6E2E6765744D6F6E7468282925333D3D3D302C736E61705F61743A223764227D2C7B';
wwv_flow_imp.g_varchar2_table(225) := '6E616D653A2259656172222C70616464696E673A223279222C737465703A223179222C636F6C756D6E5F77696474683A3132302C646174655F666F726D61743A2259595959222C75707065725F746578743A286E2C742C65293D3E21747C7C41286E2921';
wwv_flow_imp.g_varchar2_table(226) := '3D3D412874293F41286E293A22222C6C6F7765725F746578743A2259595959222C736E61705F61743A22333064227D5D2C493D7B6172726F775F63757276653A352C6175746F5F6D6F76655F6C6162656C3A21312C6261725F636F726E65725F72616469';
wwv_flow_imp.g_varchar2_table(227) := '75733A332C6261725F6865696768743A33302C636F6E7461696E65725F6865696768743A226175746F222C636F6C756D6E5F77696474683A6E756C6C2C646174655F666F726D61743A22595959592D4D4D2D44442048483A6D6D222C75707065725F6865';
wwv_flow_imp.g_varchar2_table(228) := '616465725F6865696768743A34352C6C6F7765725F6865616465725F6865696768743A33302C736E61705F61743A6E756C6C2C696E66696E6974655F70616464696E673A21302C686F6C69646179733A7B22766172282D2D672D7765656B656E642D6869';
wwv_flow_imp.g_varchar2_table(229) := '67686C696768742D636F6C6F7229223A227765656B656E64227D2C69676E6F72653A5B5D2C6C616E67756167653A22656E222C6C696E65733A22626F7468222C6D6F76655F646570656E64656E636965733A21302C70616464696E673A31382C706F7075';
wwv_flow_imp.g_varchar2_table(230) := '703A6E3D3E7B6E2E7365745F7469746C65286E2E7461736B2E6E616D65292C6E2E7461736B2E6465736372697074696F6E3F6E2E7365745F7375627469746C65286E2E7461736B2E6465736372697074696F6E293A6E2E7365745F7375627469746C6528';
wwv_flow_imp.g_varchar2_table(231) := '2222293B636F6E737420743D642E666F726D6174286E2E7461736B2E5F73746172742C224D4D4D2044222C6E2E63686172742E6F7074696F6E732E6C616E6775616765292C653D642E666F726D617428642E616464286E2E7461736B2E5F656E642C2D31';
wwv_flow_imp.g_varchar2_table(232) := '2C227365636F6E6422292C224D4D4D2044222C6E2E63686172742E6F7074696F6E732E6C616E6775616765292C693D6E2E7461736B2E61637475616C5F6475726174696F6E3D3D3D313F22646179223A2264617973223B6E2E7365745F64657461696C73';
wwv_flow_imp.g_varchar2_table(233) := '2860247B747D202D20247B657D2028247B6E2E7461736B2E61637475616C5F6475726174696F6E7D20247B697D247B6E2E7461736B2E69676E6F7265645F6475726174696F6E3F22202B20222B6E2E7461736B2E69676E6F7265645F6475726174696F6E';
wwv_flow_imp.g_varchar2_table(234) := '2B22206578636C75646564223A22227D293C62722F3E50726F67726573733A20247B4D6174682E666C6F6F72286E2E7461736B2E70726F67726573732A313030292F3130307D2560297D2C706F7075705F6F6E3A22636C69636B222C726561646F6E6C79';
wwv_flow_imp.g_varchar2_table(235) := '5F70726F67726573733A21312C726561646F6E6C795F64617465733A21312C726561646F6E6C793A21312C686F7665725F6F6E5F646174653A21312C66697865645F6475726174696F6E3A21312C7363726F6C6C5F746F3A22746F646179222C73686F77';
wwv_flow_imp.g_varchar2_table(236) := '5F65787065637465645F70726F67726573733A21312C746F6461795F627574746F6E3A21302C766965775F6D6F64653A22446179222C766965775F6D6F64655F73656C6563743A21312C766965775F6D6F6465733A772C69735F7765656B656E643A6E3D';
wwv_flow_imp.g_varchar2_table(237) := '3E6E2E67657444617928293D3D3D307C7C6E2E67657444617928293D3D3D367D3B636C61737320537B636F6E7374727563746F7228742C652C69297B746869732E73657475705F777261707065722874292C746869732E73657475705F6F7074696F6E73';
wwv_flow_imp.g_varchar2_table(238) := '2869292C746869732E73657475705F7461736B732865292C746869732E6368616E67655F766965775F6D6F646528292C746869732E62696E645F6576656E747328297D73657475705F777261707065722874297B6C657420652C693B696628747970656F';
wwv_flow_imp.g_varchar2_table(239) := '6620743D3D22737472696E6722297B6C657420733D646F63756D656E742E717565727953656C6563746F722874293B6966282173297468726F77206E6577205265666572656E63654572726F7228604353532073656C6563746F722022247B747D222063';
wwv_flow_imp.g_varchar2_table(240) := '6F756C64206E6F7420626520666F756E6420696E20444F4D60293B743D737D6966287420696E7374616E63656F662048544D4C456C656D656E7429693D742C653D742E717565727953656C6563746F72282273766722293B656C7365206966287420696E';
wwv_flow_imp.g_varchar2_table(241) := '7374616E63656F6620535647456C656D656E7429653D743B656C7365207468726F77206E657720547970654572726F7228224672617070652047616E7474206F6E6C7920737570706F727473207573616765206F66206120737472696E67204353532073';
wwv_flow_imp.g_varchar2_table(242) := '656C6563746F722C2048544D4C20444F4D20656C656D656E74206F722053564720444F4D20656C656D656E7420666F72207468652027656C656D656E742720706172616D6574657222293B653F28746869732E247376673D652C746869732E247376672E';
wwv_flow_imp.g_varchar2_table(243) := '636C6173734C6973742E616464282267616E74742229293A746869732E247376673D662822737667222C7B617070656E645F746F3A692C636C6173733A2267616E7474227D292C746869732E24636F6E7461696E65723D746869732E6372656174655F65';
wwv_flow_imp.g_varchar2_table(244) := '6C287B636C61737365733A2267616E74742D636F6E7461696E6572222C617070656E645F746F3A746869732E247376672E706172656E74456C656D656E747D292C746869732E24636F6E7461696E65722E617070656E644368696C6428746869732E2473';
wwv_flow_imp.g_varchar2_table(245) := '7667292C746869732E24706F7075705F777261707065723D746869732E6372656174655F656C287B636C61737365733A22706F7075702D77726170706572222C617070656E645F746F3A746869732E24636F6E7461696E65727D297D73657475705F6F70';
wwv_flow_imp.g_varchar2_table(246) := '74696F6E732874297B746869732E6F726967696E616C5F6F7074696F6E733D742C74213D6E756C6C2626742E766965775F6D6F646573262628742E766965775F6D6F6465733D742E766965775F6D6F6465732E6D617028693D3E7B696628747970656F66';
wwv_flow_imp.g_varchar2_table(247) := '20693D3D22737472696E6722297B636F6E737420733D772E66696E6428723D3E722E6E616D653D3D3D69293B72657475726E20737C7C636F6E736F6C652E6572726F7228605468652076696577206D6F64652022247B697D22206973206E6F7420707265';
wwv_flow_imp.g_varchar2_table(248) := '646566696E656420696E204672617070652047616E74742E20506C6561736520646566696E65207468652076696577206D6F6465206F626A65637420696E73746561642E60292C737D72657475726E20697D292C742E766965775F6D6F64653D742E7669';
wwv_flow_imp.g_varchar2_table(249) := '65775F6D6F6465735B305D292C746869732E6F7074696F6E733D7B2E2E2E492C2E2E2E747D3B636F6E737420653D7B22677269642D686569676874223A22636F6E7461696E65725F686569676874222C226261722D686569676874223A226261725F6865';
wwv_flow_imp.g_varchar2_table(250) := '69676874222C226C6F7765722D6865616465722D686569676874223A226C6F7765725F6865616465725F686569676874222C2275707065722D6865616465722D686569676874223A2275707065725F6865616465725F686569676874227D3B666F72286C';
wwv_flow_imp.g_varchar2_table(251) := '6574206920696E2065297B6C657420733D746869732E6F7074696F6E735B655B695D5D3B73213D3D226175746F222626746869732E24636F6E7461696E65722E7374796C652E73657450726F706572747928222D2D67762D222B692C732B22707822297D';
wwv_flow_imp.g_varchar2_table(252) := '696628746869732E636F6E6669673D7B69676E6F7265645F64617465733A5B5D2C69676E6F7265645F706F736974696F6E733A5B5D2C657874656E645F62795F756E6974733A31307D2C747970656F6620746869732E6F7074696F6E732E69676E6F7265';
wwv_flow_imp.g_varchar2_table(253) := '213D2266756E6374696F6E22297B747970656F6620746869732E6F7074696F6E732E69676E6F72653D3D22737472696E6722262628746869732E6F7074696F6E732E69676E6F72653D5B746869732E6F7074696F6E732E69676E6F72655D293B666F7228';
wwv_flow_imp.g_varchar2_table(254) := '6C65742069206F6620746869732E6F7074696F6E732E69676E6F7265297B696628747970656F6620693D3D2266756E6374696F6E22297B746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E3D693B636F6E74696E75657D747970656F';
wwv_flow_imp.g_varchar2_table(255) := '6620693D3D22737472696E6722262628693D3D3D227765656B656E64223F746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E3D733D3E732E67657444617928293D3D367C7C732E67657444617928293D3D303A746869732E636F6E66';
wwv_flow_imp.g_varchar2_table(256) := '69672E69676E6F7265645F64617465732E70757368286E6577204461746528692B2220222929297D7D656C736520746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E3D746869732E6F7074696F6E732E69676E6F72657D7570646174';
wwv_flow_imp.g_varchar2_table(257) := '655F6F7074696F6E732874297B746869732E73657475705F6F7074696F6E73287B2E2E2E746869732E6F726967696E616C5F6F7074696F6E732C2E2E2E747D292C746869732E6368616E67655F766965775F6D6F646528766F696420302C2130297D7365';
wwv_flow_imp.g_varchar2_table(258) := '7475705F7461736B732874297B746869732E7461736B733D742E6D61702828652C69293D3E7B69662821652E73746172742972657475726E20636F6E736F6C652E6572726F7228607461736B2022247B652E69647D2220646F65736E2774206861766520';
wwv_flow_imp.g_varchar2_table(259) := '61207374617274206461746560292C21313B696628652E5F73746172743D642E706172736528652E7374617274292C652E656E643D3D3D766F696420302626652E6475726174696F6E213D3D766F69642030262628652E656E643D652E5F73746172742C';
wwv_flow_imp.g_varchar2_table(260) := '652E6475726174696F6E2E73706C697428222022292E666F7245616368286F3D3E7B6C65747B6475726174696F6E3A682C7363616C653A677D3D642E70617273655F6475726174696F6E286F293B652E656E643D642E61646428652E656E642C682C6729';
wwv_flow_imp.g_varchar2_table(261) := '7D29292C21652E656E642972657475726E20636F6E736F6C652E6572726F7228607461736B2022247B652E69647D2220646F65736E2774206861766520616E20656E64206461746560292C21313B696628652E5F656E643D642E706172736528652E656E';
wwv_flow_imp.g_varchar2_table(262) := '64292C642E6469666628652E5F656E642C652E5F73746172742C227965617222293C302972657475726E20636F6E736F6C652E6572726F7228607374617274206F66207461736B2063616E277420626520616674657220656E64206F66207461736B3A20';
wwv_flow_imp.g_varchar2_table(263) := '696E207461736B2022247B652E69647D2260292C21313B696628642E6469666628652E5F656E642C652E5F73746172742C227965617222293E31302972657475726E20636F6E736F6C652E6572726F722860746865206475726174696F6E206F66207461';
wwv_flow_imp.g_varchar2_table(264) := '736B2022247B652E69647D2220697320746F6F206C6F6E67202861626F76652074656E2079656172732960292C21313B696628652E5F696E6465783D692C642E6765745F646174655F76616C75657328652E5F656E64292E736C6963652833292E657665';
wwv_flow_imp.g_varchar2_table(265) := '727928613D3E613D3D3D3029262628652E5F656E643D642E61646428652E5F656E642C32342C22686F75722229292C747970656F6620652E646570656E64656E636965733D3D22737472696E67227C7C21652E646570656E64656E63696573297B6C6574';
wwv_flow_imp.g_varchar2_table(266) := '20613D5B5D3B652E646570656E64656E63696573262628613D652E646570656E64656E636965732E73706C697428222C22292E6D6170286F3D3E6F2E7472696D28292E7265706C616365416C6C282220222C225F2229292E66696C746572286F3D3E6F29';
wwv_flow_imp.g_varchar2_table(267) := '292C652E646570656E64656E636965733D617D72657475726E20652E69643F747970656F6620652E69643D3D22737472696E67223F652E69643D652E69642E7265706C616365416C6C282220222C225F22293A652E69643D60247B652E69647D603A652E';
wwv_flow_imp.g_varchar2_table(268) := '69643D7A2865292C657D292E66696C74657228653D3E65292C746869732E73657475705F646570656E64656E6369657328297D73657475705F646570656E64656E6369657328297B746869732E646570656E64656E63795F6D61703D7B7D3B666F72286C';
wwv_flow_imp.g_varchar2_table(269) := '65742074206F6620746869732E7461736B7329666F72286C65742065206F6620742E646570656E64656E6369657329746869732E646570656E64656E63795F6D61705B655D3D746869732E646570656E64656E63795F6D61705B655D7C7C5B5D2C746869';
wwv_flow_imp.g_varchar2_table(270) := '732E646570656E64656E63795F6D61705B655D2E7075736828742E6964297D726566726573682874297B746869732E73657475705F7461736B732874292C746869732E6368616E67655F766965775F6D6F646528297D7570646174655F7461736B28742C';
wwv_flow_imp.g_varchar2_table(271) := '65297B6C657420693D746869732E7461736B732E66696E6428723D3E722E69643D3D3D74292C733D746869732E626172735B692E5F696E6465785D3B4F626A6563742E61737369676E28692C65292C732E7265667265736828297D6368616E67655F7669';
wwv_flow_imp.g_varchar2_table(272) := '65775F6D6F646528743D746869732E6F7074696F6E732E766965775F6D6F64652C653D2131297B747970656F6620743D3D22737472696E6722262628743D746869732E6F7074696F6E732E766965775F6D6F6465732E66696E6428723D3E722E6E616D65';
wwv_flow_imp.g_varchar2_table(273) := '3D3D3D7429293B6C657420692C733B65262628693D746869732E24636F6E7461696E65722E7363726F6C6C4C6566742C733D746869732E6F7074696F6E732E7363726F6C6C5F746F2C746869732E6F7074696F6E732E7363726F6C6C5F746F3D6E756C6C';
wwv_flow_imp.g_varchar2_table(274) := '292C746869732E6F7074696F6E732E766965775F6D6F64653D742E6E616D652C746869732E636F6E6669672E766965775F6D6F64653D742C746869732E7570646174655F766965775F7363616C652874292C746869732E73657475705F64617465732865';
wwv_flow_imp.g_varchar2_table(275) := '292C746869732E72656E64657228292C65262628746869732E24636F6E7461696E65722E7363726F6C6C4C6566743D692C746869732E6F7074696F6E732E7363726F6C6C5F746F3D73292C746869732E747269676765725F6576656E742822766965775F';
wwv_flow_imp.g_varchar2_table(276) := '6368616E6765222C5B745D297D7570646174655F766965775F7363616C652874297B6C65747B6475726174696F6E3A652C7363616C653A697D3D642E70617273655F6475726174696F6E28742E73746570293B746869732E636F6E6669672E737465703D';
wwv_flow_imp.g_varchar2_table(277) := '652C746869732E636F6E6669672E756E69743D692C746869732E636F6E6669672E636F6C756D6E5F77696474683D746869732E6F7074696F6E732E636F6C756D6E5F77696474687C7C742E636F6C756D6E5F77696474687C7C34352C746869732E24636F';
wwv_flow_imp.g_varchar2_table(278) := '6E7461696E65722E7374796C652E73657450726F706572747928222D2D67762D636F6C756D6E2D7769647468222C746869732E636F6E6669672E636F6C756D6E5F77696474682B22707822292C746869732E636F6E6669672E6865616465725F68656967';
wwv_flow_imp.g_varchar2_table(279) := '68743D746869732E6F7074696F6E732E6C6F7765725F6865616465725F6865696768742B746869732E6F7074696F6E732E75707065725F6865616465725F6865696768742B31307D73657475705F646174657328743D2131297B746869732E7365747570';
wwv_flow_imp.g_varchar2_table(280) := '5F67616E74745F64617465732874292C746869732E73657475705F646174655F76616C75657328297D73657475705F67616E74745F64617465732874297B6C657420652C693B746869732E7461736B732E6C656E6774687C7C28653D6E65772044617465';
wwv_flow_imp.g_varchar2_table(281) := '2C693D6E65772044617465293B666F72286C65742073206F6620746869732E7461736B73292821657C7C732E5F73746172743C6529262628653D732E5F7374617274292C2821697C7C732E5F656E643E6929262628693D732E5F656E64293B696628653D';
wwv_flow_imp.g_varchar2_table(282) := '642E73746172745F6F6628652C746869732E636F6E6669672E756E6974292C693D642E73746172745F6F6628692C746869732E636F6E6669672E756E6974292C217429696628746869732E6F7074696F6E732E696E66696E6974655F70616464696E6729';
wwv_flow_imp.g_varchar2_table(283) := '746869732E67616E74745F73746172743D642E61646428652C2D746869732E636F6E6669672E657874656E645F62795F756E6974732A332C746869732E636F6E6669672E756E6974292C746869732E67616E74745F656E643D642E61646428692C746869';
wwv_flow_imp.g_varchar2_table(284) := '732E636F6E6669672E657874656E645F62795F756E6974732A332C746869732E636F6E6669672E756E6974293B656C73657B747970656F6620746869732E636F6E6669672E766965775F6D6F64652E70616464696E673D3D22737472696E672226262874';
wwv_flow_imp.g_varchar2_table(285) := '6869732E636F6E6669672E766965775F6D6F64652E70616464696E673D5B746869732E636F6E6669672E766965775F6D6F64652E70616464696E672C746869732E636F6E6669672E766965775F6D6F64652E70616464696E675D293B6C65745B732C725D';
wwv_flow_imp.g_varchar2_table(286) := '3D746869732E636F6E6669672E766965775F6D6F64652E70616464696E672E6D617028642E70617273655F6475726174696F6E293B746869732E67616E74745F73746172743D642E61646428652C2D732E6475726174696F6E2C732E7363616C65292C74';
wwv_flow_imp.g_varchar2_table(287) := '6869732E67616E74745F656E643D642E61646428692C722E6475726174696F6E2C722E7363616C65297D746869732E636F6E6669672E646174655F666F726D61743D746869732E636F6E6669672E766965775F6D6F64652E646174655F666F726D61747C';
wwv_flow_imp.g_varchar2_table(288) := '7C746869732E6F7074696F6E732E646174655F666F726D61742C746869732E67616E74745F73746172742E736574486F75727328302C302C302C30297D73657475705F646174655F76616C75657328297B6C657420743D746869732E67616E74745F7374';
wwv_flow_imp.g_varchar2_table(289) := '6172743B666F7228746869732E64617465733D5B745D3B743C746869732E67616E74745F656E643B29743D642E61646428742C746869732E636F6E6669672E737465702C746869732E636F6E6669672E756E6974292C746869732E64617465732E707573';
wwv_flow_imp.g_varchar2_table(290) := '682874297D62696E645F6576656E747328297B746869732E62696E645F677269645F636C69636B28292C746869732E62696E645F686F6C696461795F6C6162656C7328292C746869732E62696E645F6261725F6576656E747328297D72656E6465722829';
wwv_flow_imp.g_varchar2_table(291) := '7B746869732E636C65617228292C746869732E73657475705F6C617965727328292C746869732E6D616B655F6772696428292C746869732E6D616B655F646174657328292C746869732E6D616B655F677269645F65787472617328292C746869732E6D61';
wwv_flow_imp.g_varchar2_table(292) := '6B655F6261727328292C746869732E6D616B655F6172726F777328292C746869732E6D61705F6172726F77735F6F6E5F6261727328292C746869732E7365745F64696D656E73696F6E7328292C746869732E7365745F7363726F6C6C5F706F736974696F';
wwv_flow_imp.g_varchar2_table(293) := '6E28746869732E6F7074696F6E732E7363726F6C6C5F746F297D73657475705F6C617965727328297B746869732E6C61796572733D7B7D3B636F6E737420743D5B2267726964222C226172726F77222C2270726F6772657373222C22626172225D3B666F';
wwv_flow_imp.g_varchar2_table(294) := '72286C65742065206F66207429746869732E6C61796572735B655D3D66282267222C7B636C6173733A652C617070656E645F746F3A746869732E247376677D293B746869732E246578747261733D746869732E6372656174655F656C287B636C61737365';
wwv_flow_imp.g_varchar2_table(295) := '733A22657874726173222C617070656E645F746F3A746869732E24636F6E7461696E65727D292C746869732E2461646A7573743D746869732E6372656174655F656C287B636C61737365733A2261646A7573742068696465222C617070656E645F746F3A';
wwv_flow_imp.g_varchar2_table(296) := '746869732E246578747261732C747970653A22627574746F6E227D292C746869732E2461646A7573742E696E6E657248544D4C3D22266C6172723B227D6D616B655F6772696428297B746869732E6D616B655F677269645F6261636B67726F756E642829';
wwv_flow_imp.g_varchar2_table(297) := '2C746869732E6D616B655F677269645F726F777328292C746869732E6D616B655F677269645F68656164657228292C746869732E6D616B655F736964655F68656164657228297D6D616B655F677269645F65787472617328297B746869732E6D616B655F';
wwv_flow_imp.g_varchar2_table(298) := '677269645F686967686C696768747328292C746869732E6D616B655F677269645F7469636B7328297D6D616B655F677269645F6261636B67726F756E6428297B636F6E737420743D746869732E64617465732E6C656E6774682A746869732E636F6E6669';
wwv_flow_imp.g_varchar2_table(299) := '672E636F6C756D6E5F77696474682C653D4D6174682E6D617828746869732E636F6E6669672E6865616465725F6865696768742B746869732E6F7074696F6E732E70616464696E672B28746869732E6F7074696F6E732E6261725F6865696768742B7468';
wwv_flow_imp.g_varchar2_table(300) := '69732E6F7074696F6E732E70616464696E67292A746869732E7461736B732E6C656E6774682D31302C746869732E6F7074696F6E732E636F6E7461696E65725F686569676874213D3D226175746F223F746869732E6F7074696F6E732E636F6E7461696E';
wwv_flow_imp.g_varchar2_table(301) := '65725F6865696768743A30293B66282272656374222C7B783A302C793A302C77696474683A742C6865696768743A652C636C6173733A22677269642D6261636B67726F756E64222C617070656E645F746F3A746869732E247376677D292C632E61747472';
wwv_flow_imp.g_varchar2_table(302) := '28746869732E247376672C7B6865696768743A652C77696474683A2231303025227D292C746869732E677269645F6865696768743D652C746869732E6F7074696F6E732E636F6E7461696E65725F6865696768743D3D3D226175746F2226262874686973';
wwv_flow_imp.g_varchar2_table(303) := '2E24636F6E7461696E65722E7374796C652E6865696768743D652B22707822297D6D616B655F677269645F726F777328297B636F6E737420743D66282267222C7B617070656E645F746F3A746869732E6C61796572732E677269647D292C653D74686973';
wwv_flow_imp.g_varchar2_table(304) := '2E64617465732E6C656E6774682A746869732E636F6E6669672E636F6C756D6E5F77696474682C693D746869732E6F7074696F6E732E6261725F6865696768742B746869732E6F7074696F6E732E70616464696E673B746869732E636F6E6669672E6865';
wwv_flow_imp.g_varchar2_table(305) := '616465725F6865696768743B666F72286C657420733D746869732E636F6E6669672E6865616465725F6865696768743B733C746869732E677269645F6865696768743B732B3D692966282272656374222C7B783A302C793A732C77696474683A652C6865';
wwv_flow_imp.g_varchar2_table(306) := '696768743A692C636C6173733A22677269642D726F77222C617070656E645F746F3A747D297D6D616B655F677269645F68656164657228297B746869732E246865616465723D746869732E6372656174655F656C287B77696474683A746869732E646174';
wwv_flow_imp.g_varchar2_table(307) := '65732E6C656E6774682A746869732E636F6E6669672E636F6C756D6E5F77696474682C636C61737365733A22677269642D686561646572222C617070656E645F746F3A746869732E24636F6E7461696E65727D292C746869732E2475707065725F686561';
wwv_flow_imp.g_varchar2_table(308) := '6465723D746869732E6372656174655F656C287B636C61737365733A2275707065722D686561646572222C617070656E645F746F3A746869732E246865616465727D292C746869732E246C6F7765725F6865616465723D746869732E6372656174655F65';
wwv_flow_imp.g_varchar2_table(309) := '6C287B636C61737365733A226C6F7765722D686561646572222C617070656E645F746F3A746869732E246865616465727D297D6D616B655F736964655F68656164657228297B696628746869732E24736964655F6865616465723D746869732E63726561';
wwv_flow_imp.g_varchar2_table(310) := '74655F656C287B636C61737365733A22736964652D686561646572227D292C746869732E2475707065725F6865616465722E70726570656E6428746869732E24736964655F686561646572292C746869732E6F7074696F6E732E766965775F6D6F64655F';
wwv_flow_imp.g_varchar2_table(311) := '73656C656374297B636F6E737420743D646F63756D656E742E637265617465456C656D656E74282273656C65637422293B742E636C6173734C6973742E6164642822766965776D6F64652D73656C65637422293B636F6E737420653D646F63756D656E74';
wwv_flow_imp.g_varchar2_table(312) := '2E637265617465456C656D656E7428226F7074696F6E22293B652E73656C65637465643D21302C652E64697361626C65643D21302C652E74657874436F6E74656E743D224D6F6465222C742E617070656E644368696C642865293B666F7228636F6E7374';
wwv_flow_imp.g_varchar2_table(313) := '2069206F6620746869732E6F7074696F6E732E766965775F6D6F646573297B636F6E737420733D646F63756D656E742E637265617465456C656D656E7428226F7074696F6E22293B732E76616C75653D692E6E616D652C732E74657874436F6E74656E74';
wwv_flow_imp.g_varchar2_table(314) := '3D692E6E616D652C692E6E616D653D3D3D746869732E636F6E6669672E766965775F6D6F64652E6E616D65262628732E73656C65637465643D2130292C742E617070656E644368696C642873297D742E6164644576656E744C697374656E657228226368';
wwv_flow_imp.g_varchar2_table(315) := '616E6765222C2866756E6374696F6E28297B746869732E6368616E67655F766965775F6D6F646528742E76616C75652C2130297D292E62696E64287468697329292C746869732E24736964655F6865616465722E617070656E644368696C642874297D69';
wwv_flow_imp.g_varchar2_table(316) := '6628746869732E6F7074696F6E732E746F6461795F627574746F6E297B6C657420743D646F63756D656E742E637265617465456C656D656E742822627574746F6E22293B742E636C6173734C6973742E6164642822746F6461792D627574746F6E22292C';
wwv_flow_imp.g_varchar2_table(317) := '742E74657874436F6E74656E743D22546F646179222C742E6F6E636C69636B3D746869732E7363726F6C6C5F63757272656E742E62696E642874686973292C746869732E24736964655F6865616465722E70726570656E642874292C746869732E24746F';
wwv_flow_imp.g_varchar2_table(318) := '6461795F627574746F6E3D747D7D6D616B655F677269645F7469636B7328297B696628746869732E6F7074696F6E732E6C696E65733D3D3D226E6F6E65222972657475726E3B6C657420743D302C653D746869732E636F6E6669672E6865616465725F68';
wwv_flow_imp.g_varchar2_table(319) := '65696768742C693D746869732E677269645F6865696768742D746869732E636F6E6669672E6865616465725F6865696768742C733D66282267222C7B636C6173733A226C696E65735F6C61796572222C617070656E645F746F3A746869732E6C61796572';
wwv_flow_imp.g_varchar2_table(320) := '732E677269647D292C723D746869732E636F6E6669672E6865616465725F6865696768743B636F6E737420613D746869732E64617465732E6C656E6774682A746869732E636F6E6669672E636F6C756D6E5F77696474682C6F3D746869732E6F7074696F';
wwv_flow_imp.g_varchar2_table(321) := '6E732E6261725F6865696768742B746869732E6F7074696F6E732E70616464696E673B696628746869732E6F7074696F6E732E6C696E6573213D3D22766572746963616C2229666F72286C657420683D746869732E636F6E6669672E6865616465725F68';
wwv_flow_imp.g_varchar2_table(322) := '65696768743B683C746869732E677269645F6865696768743B682B3D6F296628226C696E65222C7B78313A302C79313A722B6F2C78323A612C79323A722B6F2C636C6173733A22726F772D6C696E65222C617070656E645F746F3A737D292C722B3D6F3B';
wwv_flow_imp.g_varchar2_table(323) := '696628746869732E6F7074696F6E732E6C696E6573213D3D22686F72697A6F6E74616C2229666F72286C65742068206F6620746869732E6461746573297B6C657420673D227469636B223B746869732E636F6E6669672E766965775F6D6F64652E746869';
wwv_flow_imp.g_varchar2_table(324) := '636B5F6C696E652626746869732E636F6E6669672E766965775F6D6F64652E746869636B5F6C696E65286829262628672B3D2220746869636B22292C66282270617468222C7B643A604D20247B747D20247B657D207620247B697D602C636C6173733A67';
wwv_flow_imp.g_varchar2_table(325) := '2C617070656E645F746F3A746869732E6C61796572732E677269647D292C746869732E766965775F697328226D6F6E746822293F742B3D642E6765745F646179735F696E5F6D6F6E74682868292A746869732E636F6E6669672E636F6C756D6E5F776964';
wwv_flow_imp.g_varchar2_table(326) := '74682F33303A746869732E766965775F697328227965617222293F742B3D642E6765745F646179735F696E5F796561722868292A746869732E636F6E6669672E636F6C756D6E5F77696474682F3336353A742B3D746869732E636F6E6669672E636F6C75';
wwv_flow_imp.g_varchar2_table(327) := '6D6E5F77696474687D7D686967686C696768745F686F6C696461797328297B6C657420743D7B7D3B696628746869732E6F7074696F6E732E686F6C696461797329666F72286C6574206520696E20746869732E6F7074696F6E732E686F6C696461797329';
wwv_flow_imp.g_varchar2_table(328) := '7B6C657420693D746869732E6F7074696F6E732E686F6C69646179735B655D3B693D3D3D227765656B656E6422262628693D746869732E6F7074696F6E732E69735F7765656B656E64293B6C657420733B696628747970656F6620693D3D226F626A6563';
wwv_flow_imp.g_varchar2_table(329) := '7422297B6C657420723D692E66696E6428613D3E747970656F6620613D3D2266756E6374696F6E22293B69662872262628733D72292C746869732E6F7074696F6E732E686F6C69646179732E6E616D65297B6C657420613D6E6577204461746528692E64';
wwv_flow_imp.g_varchar2_table(330) := '6174652B222022293B693D6F3D3E612E67657454696D6528293D3D3D6F2E67657454696D6528292C745B615D3D692E6E616D657D656C736520693D613D3E746869732E6F7074696F6E732E686F6C69646179735B655D2E66696C746572286F3D3E747970';
wwv_flow_imp.g_varchar2_table(331) := '656F66206F213D2266756E6374696F6E22292E6D6170286F3D3E7B6966286F2E6E616D65297B6C657420683D6E65772044617465286F2E646174652B222022293B72657475726E20745B685D3D6F2E6E616D652C682E67657454696D6528297D72657475';
wwv_flow_imp.g_varchar2_table(332) := '726E206E65772044617465286F2B222022292E67657454696D6528297D292E696E636C7564657328612E67657454696D652829297D666F72286C657420723D6E6577204461746528746869732E67616E74745F7374617274293B723C3D746869732E6761';
wwv_flow_imp.g_varchar2_table(333) := '6E74745F656E643B722E7365744461746528722E6765744461746528292B3129297B696628746869732E636F6E6669672E69676E6F7265645F64617465732E66696E64285F3D3E5F2E67657454696D6528293D3D722E67657454696D652829297C7C7468';
wwv_flow_imp.g_varchar2_table(334) := '69732E636F6E6669672E69676E6F7265645F66756E6374696F6E2626746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E28722929636F6E74696E75653B636F6E737420613D692872297C7C732626732872292C6F3D642E6469666628';
wwv_flow_imp.g_varchar2_table(335) := '722C746869732E67616E74745F73746172742C746869732E636F6E6669672E756E6974292F746869732E636F6E6669672E737465702A746869732E636F6E6669672E636F6C756D6E5F77696474682C683D746869732E677269645F6865696768742D7468';
wwv_flow_imp.g_varchar2_table(336) := '69732E636F6E6669672E6865616465725F6865696768742C673D642E666F726D617428722C22595959592D4D4D2D4444222C746869732E6F7074696F6E732E6C616E6775616765292E7265706C616365282220222C225F22292C6C3D7B783A4D6174682E';
wwv_flow_imp.g_varchar2_table(337) := '726F756E64286F292C793A746869732E636F6E6669672E6865616465725F6865696768742C77696474683A746869732E636F6E6669672E636F6C756D6E5F77696474682F642E636F6E766572745F7363616C657328746869732E636F6E6669672E766965';
wwv_flow_imp.g_varchar2_table(338) := '775F6D6F64652E737465702C2264617922292C6865696768743A682C617070656E645F746F3A746869732E6C61796572732E677269647D3B69662861297B696628745B725D297B6C6574205F3D746869732E6372656174655F656C287B636C6173736573';
wwv_flow_imp.g_varchar2_table(339) := '3A22686F6C696461792D6C6162656C206C6162656C5F222B672C617070656E645F746F3A746869732E246578747261737D293B5F2E74657874436F6E74656E743D745B725D7D66282272656374222C7B2E2E2E6C2C636C6173733A22686F6C696461792D';
wwv_flow_imp.g_varchar2_table(340) := '686967686C6967687420222B672B28746869732E6F7074696F6E732E686F7665725F6F6E5F646174653F2220677269642D636F6C756D6E223A2222292C7374796C653A6066696C6C3A20247B657D3B602C617070656E645F746F3A746869732E6C617965';
wwv_flow_imp.g_varchar2_table(341) := '72732E677269647D297D656C736520746869732E6F7074696F6E732E686F7665725F6F6E5F64617465262666282272656374222C7B2E2E2E6C2C636C6173733A22677269642D636F6C756D6E227D297D7D7D686967686C696768745F63757272656E7428';
wwv_flow_imp.g_varchar2_table(342) := '297B636F6E737420743D746869732E6765745F636C6F736573745F6461746528293B69662821747C7C21745B315D2972657475726E3B636F6E73745B652C695D3D743B692E636C6173734C6973742E616464282263757272656E742D646174652D686967';
wwv_flow_imp.g_varchar2_table(343) := '686C6967687422293B636F6E737420723D642E64696666286E657720446174652C746869732E67616E74745F73746172742C746869732E636F6E6669672E756E6974292F746869732E636F6E6669672E737465702A746869732E636F6E6669672E636F6C';
wwv_flow_imp.g_varchar2_table(344) := '756D6E5F77696474683B746869732E2463757272656E745F686967686C696768743D746869732E6372656174655F656C287B746F703A746869732E636F6E6669672E6865616465725F6865696768742C6C6566743A722C6865696768743A746869732E67';
wwv_flow_imp.g_varchar2_table(345) := '7269645F6865696768742D746869732E636F6E6669672E6865616465725F6865696768742C636C61737365733A2263757272656E742D686967686C69676874222C617070656E645F746F3A746869732E24636F6E7461696E65727D292C746869732E2463';
wwv_flow_imp.g_varchar2_table(346) := '757272656E745F62616C6C5F686967686C696768743D746869732E6372656174655F656C287B746F703A746869732E636F6E6669672E6865616465725F6865696768742D362C6C6566743A722D322E352C77696474683A362C6865696768743A362C636C';
wwv_flow_imp.g_varchar2_table(347) := '61737365733A2263757272656E742D62616C6C2D686967686C69676874222C617070656E645F746F3A746869732E246865616465727D297D6D616B655F677269645F686967686C696768747328297B746869732E686967686C696768745F686F6C696461';
wwv_flow_imp.g_varchar2_table(348) := '797328292C746869732E636F6E6669672E69676E6F7265645F706F736974696F6E733D5B5D3B636F6E737420743D28746869732E6F7074696F6E732E6261725F6865696768742B746869732E6F7074696F6E732E70616464696E67292A746869732E7461';
wwv_flow_imp.g_varchar2_table(349) := '736B732E6C656E6774683B746869732E6C61796572732E677269642E696E6E657248544D4C2B3D603C7061747465726E2069643D22646961676F6E616C486174636822207061747465726E556E6974733D227573657253706163654F6E55736522207769';
wwv_flow_imp.g_varchar2_table(350) := '6474683D223422206865696768743D2234223E0A202020202020202020203C7061746820643D224D2D312C31206C322C2D320A202020202020202020202020202020202020204D302C34206C342C2D340A20202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(351) := '4D332C35206C322C2D32220A202020202020202020202020202020207374796C653D227374726F6B653A677265793B207374726F6B652D77696474683A302E3322202F3E0A20202020202020203C2F7061747465726E3E603B666F72286C657420693D6E';
wwv_flow_imp.g_varchar2_table(352) := '6577204461746528746869732E67616E74745F7374617274293B693C3D746869732E67616E74745F656E643B692E7365744461746528692E6765744461746528292B3129297B69662821746869732E636F6E6669672E69676E6F7265645F64617465732E';
wwv_flow_imp.g_varchar2_table(353) := '66696E6428723D3E722E67657454696D6528293D3D692E67657454696D6528292926262821746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E7C7C21746869732E636F6E6669672E69676E6F7265645F66756E6374696F6E28692929';
wwv_flow_imp.g_varchar2_table(354) := '29636F6E74696E75653B6C657420733D642E636F6E766572745F7363616C657328642E6469666628692C746869732E67616E74745F7374617274292B2264222C746869732E636F6E6669672E756E6974292F746869732E636F6E6669672E737465703B74';
wwv_flow_imp.g_varchar2_table(355) := '6869732E636F6E6669672E69676E6F7265645F706F736974696F6E732E7075736828732A746869732E636F6E6669672E636F6C756D6E5F7769647468292C66282272656374222C7B783A732A746869732E636F6E6669672E636F6C756D6E5F7769647468';
wwv_flow_imp.g_varchar2_table(356) := '2C793A746869732E636F6E6669672E6865616465725F6865696768742C77696474683A746869732E636F6E6669672E636F6C756D6E5F77696474682C6865696768743A742C636C6173733A2269676E6F7265642D626172222C7374796C653A2266696C6C';
wwv_flow_imp.g_varchar2_table(357) := '3A2075726C2823646961676F6E616C4861746368293B222C617070656E645F746F3A746869732E247376677D297D746869732E686967686C696768745F63757272656E7428746869732E636F6E6669672E766965775F6D6F6465297D6372656174655F65';
wwv_flow_imp.g_varchar2_table(358) := '6C287B6C6566743A742C746F703A652C77696474683A692C6865696768743A732C69643A722C636C61737365733A612C617070656E645F746F3A6F2C747970653A687D297B6C657420673D646F63756D656E742E637265617465456C656D656E7428687C';
wwv_flow_imp.g_varchar2_table(359) := '7C2264697622293B666F72286C6574206C206F6620612E73706C6974282220222929672E636C6173734C6973742E616464286C293B72657475726E20672E7374796C652E746F703D652B227078222C672E7374796C652E6C6566743D742B227078222C72';
wwv_flow_imp.g_varchar2_table(360) := '262628672E69643D72292C69262628672E7374796C652E77696474683D692B22707822292C73262628672E7374796C652E6865696768743D732B22707822292C6F26266F2E617070656E644368696C642867292C677D6D616B655F646174657328297B74';
wwv_flow_imp.g_varchar2_table(361) := '6869732E6765745F64617465735F746F5F6472617728292E666F72456163682828742C65293D3E7B696628742E6C6F7765725F74657874297B6C657420693D746869732E6372656174655F656C287B6C6566743A742E782C746F703A742E6C6F7765725F';
wwv_flow_imp.g_varchar2_table(362) := '792C636C61737365733A226C6F7765722D7465787420646174655F222B6B28742E666F726D61747465645F64617465292C617070656E645F746F3A746869732E246C6F7765725F6865616465727D293B692E696E6E6572546578743D742E6C6F7765725F';
wwv_flow_imp.g_varchar2_table(363) := '746578747D696628742E75707065725F74657874297B6C657420693D746869732E6372656174655F656C287B6C6566743A742E782C746F703A742E75707065725F792C636C61737365733A2275707065722D74657874222C617070656E645F746F3A7468';
wwv_flow_imp.g_varchar2_table(364) := '69732E2475707065725F6865616465727D293B692E696E6E6572546578743D742E75707065725F746578747D7D292C746869732E757070657254657874733D41727261792E66726F6D28746869732E24636F6E7461696E65722E717565727953656C6563';
wwv_flow_imp.g_varchar2_table(365) := '746F72416C6C28222E75707065722D746578742229292C746869732E6C6F77657254657874733D41727261792E66726F6D28746869732E24636F6E7461696E65722E717565727953656C6563746F72416C6C28222E6C6F7765722D746578742229297D67';
wwv_flow_imp.g_varchar2_table(366) := '65745F64617465735F746F5F6472617728297B6C657420743D6E756C6C3B72657475726E20746869732E64617465732E6D61702828692C73293D3E7B636F6E737420723D746869732E6765745F646174655F696E666F28692C742C73293B72657475726E';
wwv_flow_imp.g_varchar2_table(367) := '20743D722C727D297D6765745F646174655F696E666F28742C65297B6C657420693D653F652E646174653A6E756C6C3B746869732E636F6E6669672E636F6C756D6E5F77696474683B636F6E737420733D653F652E782B652E636F6C756D6E5F77696474';
wwv_flow_imp.g_varchar2_table(368) := '683A303B6C657420723D746869732E636F6E6669672E766965775F6D6F64652E75707065725F746578742C613D746869732E636F6E6669672E766965775F6D6F64652E6C6F7765725F746578743B72657475726E20723F747970656F6620723D3D227374';
wwv_flow_imp.g_varchar2_table(369) := '72696E6722262628746869732E636F6E6669672E766965775F6D6F64652E75707065725F746578743D6F3D3E642E666F726D6174286F2C722C746869732E6F7074696F6E732E6C616E677561676529293A746869732E636F6E6669672E766965775F6D6F';
wwv_flow_imp.g_varchar2_table(370) := '64652E75707065725F746578743D28293D3E22222C613F747970656F6620613D3D22737472696E6722262628746869732E636F6E6669672E766965775F6D6F64652E6C6F7765725F746578743D6F3D3E642E666F726D6174286F2C612C746869732E6F70';
wwv_flow_imp.g_varchar2_table(371) := '74696F6E732E6C616E677561676529293A746869732E636F6E6669672E766965775F6D6F64652E6C6F7765725F746578743D28293D3E22222C7B646174653A742C666F726D61747465645F646174653A6B28642E666F726D617428742C746869732E636F';
wwv_flow_imp.g_varchar2_table(372) := '6E6669672E646174655F666F726D61742C746869732E6F7074696F6E732E6C616E677561676529292C636F6C756D6E5F77696474683A746869732E636F6E6669672E636F6C756D6E5F77696474682C783A732C75707065725F746578743A746869732E63';
wwv_flow_imp.g_varchar2_table(373) := '6F6E6669672E766965775F6D6F64652E75707065725F7465787428742C692C746869732E6F7074696F6E732E6C616E6775616765292C6C6F7765725F746578743A746869732E636F6E6669672E766965775F6D6F64652E6C6F7765725F7465787428742C';
wwv_flow_imp.g_varchar2_table(374) := '692C746869732E6F7074696F6E732E6C616E6775616765292C75707065725F793A31372C6C6F7765725F793A746869732E6F7074696F6E732E75707065725F6865616465725F6865696768742B357D7D6D616B655F6261727328297B746869732E626172';
wwv_flow_imp.g_varchar2_table(375) := '733D746869732E7461736B732E6D617028743D3E7B636F6E737420653D6E6577207128746869732C74293B72657475726E20746869732E6C61796572732E6261722E617070656E644368696C6428652E67726F7570292C657D297D6D616B655F6172726F';
wwv_flow_imp.g_varchar2_table(376) := '777328297B746869732E6172726F77733D5B5D3B666F72286C65742074206F6620746869732E7461736B73297B6C657420653D5B5D3B653D742E646570656E64656E636965732E6D617028693D3E7B636F6E737420733D746869732E6765745F7461736B';
wwv_flow_imp.g_varchar2_table(377) := '2869293B69662821732972657475726E3B636F6E737420723D6E6577205728746869732C746869732E626172735B732E5F696E6465785D2C746869732E626172735B742E5F696E6465785D293B72657475726E20746869732E6C61796572732E6172726F';
wwv_flow_imp.g_varchar2_table(378) := '772E617070656E644368696C6428722E656C656D656E74292C727D292E66696C74657228426F6F6C65616E292C746869732E6172726F77733D746869732E6172726F77732E636F6E6361742865297D7D6D61705F6172726F77735F6F6E5F626172732829';
wwv_flow_imp.g_varchar2_table(379) := '7B666F72286C65742074206F6620746869732E6261727329742E6172726F77733D746869732E6172726F77732E66696C74657228653D3E652E66726F6D5F7461736B2E7461736B2E69643D3D3D742E7461736B2E69647C7C652E746F5F7461736B2E7461';
wwv_flow_imp.g_varchar2_table(380) := '736B2E69643D3D3D742E7461736B2E6964297D7365745F64696D656E73696F6E7328297B636F6E73747B77696474683A747D3D746869732E247376672E676574426F756E64696E67436C69656E745265637428292C653D746869732E247376672E717565';
wwv_flow_imp.g_varchar2_table(381) := '727953656C6563746F7228222E67726964202E677269642D726F7722293F746869732E247376672E717565727953656C6563746F7228222E67726964202E677269642D726F7722292E6765744174747269627574652822776964746822293A303B743C65';
wwv_flow_imp.g_varchar2_table(382) := '2626746869732E247376672E73657441747472696275746528227769647468222C65297D7365745F7363726F6C6C5F706F736974696F6E2874297B696628746869732E6F7074696F6E732E696E66696E6974655F70616464696E6726262821747C7C743D';
wwv_flow_imp.g_varchar2_table(383) := '3D3D2273746172742229297B6C65745B612C2E2E2E6F5D3D746869732E6765745F73746172745F656E645F706F736974696F6E7328293B746869732E24636F6E7461696E65722E7363726F6C6C4C6566743D613B72657475726E7D69662821747C7C743D';
wwv_flow_imp.g_varchar2_table(384) := '3D3D2273746172742229743D746869732E67616E74745F73746172743B656C736520696628743D3D3D22656E642229743D746869732E67616E74745F656E643B656C73657B696628743D3D3D22746F646179222972657475726E20746869732E7363726F';
wwv_flow_imp.g_varchar2_table(385) := '6C6C5F63757272656E7428293B747970656F6620743D3D22737472696E6722262628743D642E7061727365287429297D636F6E737420693D642E6469666628742C746869732E67616E74745F73746172742C746869732E636F6E6669672E756E6974292F';
wwv_flow_imp.g_varchar2_table(386) := '746869732E636F6E6669672E737465702A746869732E636F6E6669672E636F6C756D6E5F77696474683B746869732E24636F6E7461696E65722E7363726F6C6C546F287B6C6566743A692D746869732E636F6E6669672E636F6C756D6E5F77696474682F';
wwv_flow_imp.g_varchar2_table(387) := '362C6265686176696F723A22736D6F6F7468227D292C746869732E2463757272656E742626746869732E2463757272656E742E636C6173734C6973742E72656D6F7665282263757272656E742D757070657222292C746869732E63757272656E745F6461';
wwv_flow_imp.g_varchar2_table(388) := '74653D642E61646428746869732E67616E74745F73746172742C746869732E24636F6E7461696E65722E7363726F6C6C4C6566742F746869732E636F6E6669672E636F6C756D6E5F77696474682C746869732E636F6E6669672E756E6974293B6C657420';
wwv_flow_imp.g_varchar2_table(389) := '733D746869732E636F6E6669672E766965775F6D6F64652E75707065725F7465787428746869732E63757272656E745F646174652C6E756C6C2C746869732E6F7074696F6E732E6C616E6775616765292C723D746869732E757070657254657874732E66';
wwv_flow_imp.g_varchar2_table(390) := '696E6428613D3E612E74657874436F6E74656E743D3D3D73293B746869732E63757272656E745F646174653D642E61646428746869732E67616E74745F73746172742C28746869732E24636F6E7461696E65722E7363726F6C6C4C6566742B722E636C69';
wwv_flow_imp.g_varchar2_table(391) := '656E745769647468292F746869732E636F6E6669672E636F6C756D6E5F77696474682C746869732E636F6E6669672E756E6974292C733D746869732E636F6E6669672E766965775F6D6F64652E75707065725F7465787428746869732E63757272656E74';
wwv_flow_imp.g_varchar2_table(392) := '5F646174652C6E756C6C2C746869732E6F7074696F6E732E6C616E6775616765292C723D746869732E757070657254657874732E66696E6428613D3E612E74657874436F6E74656E743D3D3D73292C722E636C6173734C6973742E616464282263757272';
wwv_flow_imp.g_varchar2_table(393) := '656E742D757070657222292C746869732E2463757272656E743D727D7363726F6C6C5F63757272656E7428297B6C657420743D746869732E6765745F636C6F736573745F6461746528293B742626746869732E7365745F7363726F6C6C5F706F73697469';
wwv_flow_imp.g_varchar2_table(394) := '6F6E28745B305D297D6765745F636C6F736573745F6461746528297B6C657420743D6E657720446174653B696628743C746869732E67616E74745F73746172747C7C743E746869732E67616E74745F656E642972657475726E206E756C6C3B6C65742065';
wwv_flow_imp.g_varchar2_table(395) := '3D6E657720446174652C693D746869732E24636F6E7461696E65722E717565727953656C6563746F7228222E646174655F222B6B28642E666F726D617428652C746869732E636F6E6669672E646174655F666F726D61742C746869732E6F7074696F6E73';
wwv_flow_imp.g_varchar2_table(396) := '2E6C616E67756167652929292C733D303B666F72283B21692626733C746869732E636F6E6669672E737465703B29653D642E61646428652C2D312C746869732E636F6E6669672E756E6974292C693D746869732E24636F6E7461696E65722E7175657279';
wwv_flow_imp.g_varchar2_table(397) := '53656C6563746F7228222E646174655F222B6B28642E666F726D617428652C746869732E636F6E6669672E646174655F666F726D61742C746869732E6F7074696F6E732E6C616E67756167652929292C732B2B3B72657475726E5B6E6577204461746528';
wwv_flow_imp.g_varchar2_table(398) := '642E666F726D617428652C746869732E636F6E6669672E646174655F666F726D61742C746869732E6F7074696F6E732E6C616E6775616765292B222022292C695D7D62696E645F677269645F636C69636B28297B632E6F6E28746869732E24636F6E7461';
wwv_flow_imp.g_varchar2_table(399) := '696E65722C22636C69636B222C222E677269642D726F772C202E677269642D6865616465722C202E69676E6F7265642D6261722C202E686F6C696461792D686967686C69676874222C28293D3E7B746869732E756E73656C6563745F616C6C28292C7468';
wwv_flow_imp.g_varchar2_table(400) := '69732E686964655F706F70757028297D297D62696E645F686F6C696461795F6C6162656C7328297B636F6E737420743D746869732E24636F6E7461696E65722E717565727953656C6563746F72416C6C28222E686F6C696461792D686967686C69676874';
wwv_flow_imp.g_varchar2_table(401) := '22293B666F72286C65742065206F662074297B636F6E737420693D746869732E24636F6E7461696E65722E717565727953656C6563746F7228222E6C6162656C5F222B652E636C6173734C6973745B315D293B696628216929636F6E74696E75653B6C65';
wwv_flow_imp.g_varchar2_table(402) := '7420733B652E6F6E6D6F757365656E7465723D723D3E7B733D73657454696D656F75742828293D3E7B692E636C6173734C6973742E616464282273686F7722292C692E7374796C652E6C6566743D28722E6F6666736574587C7C722E6C6179657258292B';
wwv_flow_imp.g_varchar2_table(403) := '227078222C692E7374796C652E746F703D28722E6F6666736574597C7C722E6C6179657259292B227078227D2C333030297D2C652E6F6E6D6F7573656C656176653D723D3E7B636C65617254696D656F75742873292C692E636C6173734C6973742E7265';
wwv_flow_imp.g_varchar2_table(404) := '6D6F7665282273686F7722297D7D7D6765745F73746172745F656E645F706F736974696F6E7328297B69662821746869732E626172732E6C656E6774682972657475726E5B302C302C305D3B6C65747B783A742C77696474683A657D3D746869732E6261';
wwv_flow_imp.g_varchar2_table(405) := '72735B305D2E67726F75702E67657442426F7828292C693D742C733D742C723D742B653B72657475726E2041727261792E70726F746F747970652E666F72456163682E63616C6C28746869732E626172732C66756E6374696F6E287B67726F75703A617D';
wwv_flow_imp.g_varchar2_table(406) := '2C6F297B6C65747B783A682C77696474683A677D3D612E67657442426F7828293B683C69262628693D68292C683E73262628733D68292C682B673E72262628723D682B67297D292C5B692C732C725D7D62696E645F6261725F6576656E747328297B6C65';
wwv_flow_imp.g_varchar2_table(407) := '7420743D21312C653D302C693D302C733D21312C723D21312C613D6E756C6C2C6F3D5B5D3B746869732E6261725F6265696E675F647261676765643D6E756C6C3B636F6E737420683D28293D3E747C7C737C7C723B746869732E247376672E6F6E636C69';
wwv_flow_imp.g_varchar2_table(408) := '636B3D6C3D3E7B6C2E7461726765742E636C6173734C6973742E636F6E7461696E732822677269642D726F7722292626746869732E756E73656C6563745F616C6C28297D3B6C657420673D303B696628632E6F6E28746869732E247376672C226D6F7573';
wwv_flow_imp.g_varchar2_table(409) := '656D6F7665222C222E6261722D777261707065722C202E68616E646C65222C6C3D3E7B746869732E6261725F6265696E675F647261676765643D3D3D213126264D6174682E61627328286C2E6F6666736574587C7C6C2E6C6179657258292D67293E3130';
wwv_flow_imp.g_varchar2_table(410) := '262628746869732E6261725F6265696E675F647261676765643D2130297D292C632E6F6E28746869732E247376672C226D6F757365646F776E222C222E677269642D636F6C756D6E222C6C3D3E7B746869732E747269676765725F6576656E7428226461';
wwv_flow_imp.g_varchar2_table(411) := '74655F636C69636B222C5B746869732E6765744461746546726F6D436C69636B286C295D297D292C632E6F6E28746869732E247376672C226D6F757365646F776E222C222E6261722D777261707065722C202E68616E646C65222C286C2C5F293D3E7B63';
wwv_flow_imp.g_varchar2_table(412) := '6F6E737420703D632E636C6F7365737428222E6261722D77726170706572222C5F293B5F2E636C6173734C6973742E636F6E7461696E7328226C65667422293F28733D21302C5F2E636C6173734C6973742E616464282276697369626C652229293A5F2E';
wwv_flow_imp.g_varchar2_table(413) := '636C6173734C6973742E636F6E7461696E732822726967687422293F28723D21302C5F2E636C6173734C6973742E616464282276697369626C652229293A5F2E636C6173734C6973742E636F6E7461696E7328226261722D777261707065722229262628';
wwv_flow_imp.g_varchar2_table(414) := '743D2130292C746869732E706F7075702626746869732E706F7075702E6869646528292C653D6C2E6F6666736574587C7C6C2E6C61796572582C613D702E6765744174747269627574652822646174612D696422293B6C657420753B746869732E6F7074';
wwv_flow_imp.g_varchar2_table(415) := '696F6E732E6D6F76655F646570656E64656E636965733F753D5B612C2E2E2E746869732E6765745F616C6C5F646570656E64656E745F7461736B732861295D3A753D5B615D2C6F3D752E6D617028243D3E746869732E6765745F626172282429292C7468';
wwv_flow_imp.g_varchar2_table(416) := '69732E6261725F6265696E675F647261676765643D21312C673D652C6F2E666F724561636828243D3E7B636F6E7374206D3D242E246261723B6D2E6F783D6D2E6765745828292C6D2E6F793D6D2E6765745928292C6D2E6F77696474683D6D2E67657457';
wwv_flow_imp.g_varchar2_table(417) := '6964746828292C6D2E66696E616C64783D307D297D292C746869732E6F7074696F6E732E696E66696E6974655F70616464696E67297B6C6574206C3D21313B632E6F6E28746869732E24636F6E7461696E65722C226D6F757365776865656C222C5F3D3E';
wwv_flow_imp.g_varchar2_table(418) := '7B6C657420703D746869732E24636F6E7461696E65722E7363726F6C6C57696474682F323B696628216C26265F2E63757272656E745461726765742E7363726F6C6C4C6566743C3D70297B6C657420753D5F2E63757272656E745461726765742E736372';
wwv_flow_imp.g_varchar2_table(419) := '6F6C6C4C6566743B6C3D21302C746869732E67616E74745F73746172743D642E61646428746869732E67616E74745F73746172742C2D746869732E636F6E6669672E657874656E645F62795F756E6974732C746869732E636F6E6669672E756E6974292C';
wwv_flow_imp.g_varchar2_table(420) := '746869732E73657475705F646174655F76616C75657328292C746869732E72656E64657228292C5F2E63757272656E745461726765742E7363726F6C6C4C6566743D752B746869732E636F6E6669672E636F6C756D6E5F77696474682A746869732E636F';
wwv_flow_imp.g_varchar2_table(421) := '6E6669672E657874656E645F62795F756E6974732C73657454696D656F75742828293D3E6C3D21312C333030297D696628216C26265F2E63757272656E745461726765742E7363726F6C6C57696474682D285F2E63757272656E745461726765742E7363';
wwv_flow_imp.g_varchar2_table(422) := '726F6C6C4C6566742B5F2E63757272656E745461726765742E636C69656E745769647468293C3D70297B6C657420753D5F2E63757272656E745461726765742E7363726F6C6C4C6566743B6C3D21302C746869732E67616E74745F656E643D642E616464';
wwv_flow_imp.g_varchar2_table(423) := '28746869732E67616E74745F656E642C746869732E636F6E6669672E657874656E645F62795F756E6974732C746869732E636F6E6669672E756E6974292C746869732E73657475705F646174655F76616C75657328292C746869732E72656E6465722829';
wwv_flow_imp.g_varchar2_table(424) := '2C5F2E63757272656E745461726765742E7363726F6C6C4C6566743D752C73657454696D656F75742828293D3E6C3D21312C333030297D7D297D632E6F6E28746869732E24636F6E7461696E65722C227363726F6C6C222C6C3D3E7B6C6574205F3D5B5D';
wwv_flow_imp.g_varchar2_table(425) := '3B636F6E737420703D746869732E626172732E6D617028287B67726F75703A627D293D3E622E6765744174747269627574652822646174612D69642229293B6C657420753B69262628753D6C2E63757272656E745461726765742E7363726F6C6C4C6566';
wwv_flow_imp.g_varchar2_table(426) := '742D69292C746869732E63757272656E745F646174653D642E61646428746869732E67616E74745F73746172742C6C2E63757272656E745461726765742E7363726F6C6C4C6566742F746869732E636F6E6669672E636F6C756D6E5F77696474682A7468';
wwv_flow_imp.g_varchar2_table(427) := '69732E636F6E6669672E737465702C746869732E636F6E6669672E756E6974293B6C657420243D746869732E636F6E6669672E766965775F6D6F64652E75707065725F7465787428746869732E63757272656E745F646174652C6E756C6C2C746869732E';
wwv_flow_imp.g_varchar2_table(428) := '6F7074696F6E732E6C616E6775616765292C6D3D746869732E757070657254657874732E66696E6428623D3E622E74657874436F6E74656E743D3D3D24293B746869732E63757272656E745F646174653D642E61646428746869732E67616E74745F7374';
wwv_flow_imp.g_varchar2_table(429) := '6172742C286C2E63757272656E745461726765742E7363726F6C6C4C6566742B6D2E636C69656E745769647468292F746869732E636F6E6669672E636F6C756D6E5F77696474682A746869732E636F6E6669672E737465702C746869732E636F6E666967';
wwv_flow_imp.g_varchar2_table(430) := '2E756E6974292C243D746869732E636F6E6669672E766965775F6D6F64652E75707065725F7465787428746869732E63757272656E745F646174652C6E756C6C2C746869732E6F7074696F6E732E6C616E6775616765292C6D3D746869732E7570706572';
wwv_flow_imp.g_varchar2_table(431) := '54657874732E66696E6428623D3E622E74657874436F6E74656E743D3D3D24292C6D213D3D746869732E2463757272656E74262628746869732E2463757272656E742626746869732E2463757272656E742E636C6173734C6973742E72656D6F76652822';
wwv_flow_imp.g_varchar2_table(432) := '63757272656E742D757070657222292C6D2E636C6173734C6973742E616464282263757272656E742D757070657222292C746869732E2463757272656E743D6D292C693D6C2E63757272656E745461726765742E7363726F6C6C4C6566743B6C65745B48';
wwv_flow_imp.g_varchar2_table(433) := '2C422C6A5D3D746869732E6765745F73746172745F656E645F706F736974696F6E7328293B693E6A2B3130303F28746869732E2461646A7573742E696E6E657248544D4C3D22266C6172723B222C746869732E2461646A7573742E636C6173734C697374';
wwv_flow_imp.g_varchar2_table(434) := '2E72656D6F766528226869646522292C746869732E2461646A7573742E6F6E636C69636B3D28293D3E7B746869732E24636F6E7461696E65722E7363726F6C6C546F287B6C6566743A422C6265686176696F723A22736D6F6F7468227D297D293A692B6C';
wwv_flow_imp.g_varchar2_table(435) := '2E63757272656E745461726765742E6F666673657457696474683C482D3130303F28746869732E2461646A7573742E696E6E657248544D4C3D2226726172723B222C746869732E2461646A7573742E636C6173734C6973742E72656D6F76652822686964';
wwv_flow_imp.g_varchar2_table(436) := '6522292C746869732E2461646A7573742E6F6E636C69636B3D28293D3E7B746869732E24636F6E7461696E65722E7363726F6C6C546F287B6C6566743A482C6265686176696F723A22736D6F6F7468227D297D293A746869732E2461646A7573742E636C';
wwv_flow_imp.g_varchar2_table(437) := '6173734C6973742E61646428226869646522292C752626285F3D702E6D617028623D3E746869732E6765745F626172286229292C746869732E6F7074696F6E732E6175746F5F6D6F76655F6C6162656C26265F2E666F724561636828623D3E7B622E7570';
wwv_flow_imp.g_varchar2_table(438) := '646174655F6C6162656C5F706F736974696F6E5F6F6E5F686F72697A6F6E74616C5F7363726F6C6C287B783A752C73783A6C2E63757272656E745461726765742E7363726F6C6C4C6566747D297D29297D292C632E6F6E28746869732E247376672C226D';
wwv_flow_imp.g_varchar2_table(439) := '6F7573656D6F7665222C6C3D3E7B696628216828292972657475726E3B636F6E7374205F3D286C2E6F6666736574587C7C6C2E6C6179657258292D653B6F2E666F724561636828703D3E7B636F6E737420753D702E246261723B752E66696E616C64783D';
wwv_flow_imp.g_varchar2_table(440) := '746869732E6765745F736E61705F706F736974696F6E285F2C752E6F78292C746869732E686964655F706F70757028292C733F613D3D3D702E7461736B2E69643F702E7570646174655F6261725F706F736974696F6E287B783A752E6F782B752E66696E';
wwv_flow_imp.g_varchar2_table(441) := '616C64782C77696474683A752E6F77696474682D752E66696E616C64787D293A702E7570646174655F6261725F706F736974696F6E287B783A752E6F782B752E66696E616C64787D293A723F613D3D3D702E7461736B2E69642626702E7570646174655F';
wwv_flow_imp.g_varchar2_table(442) := '6261725F706F736974696F6E287B77696474683A752E6F77696474682B752E66696E616C64787D293A74262621746869732E6F7074696F6E732E726561646F6E6C79262621746869732E6F7074696F6E732E726561646F6E6C795F64617465732626702E';
wwv_flow_imp.g_varchar2_table(443) := '7570646174655F6261725F706F736974696F6E287B783A752E6F782B752E66696E616C64787D297D297D292C646F63756D656E742E6164644576656E744C697374656E657228226D6F7573657570222C28293D3E7B766172206C2C5F2C703B743D21312C';
wwv_flow_imp.g_varchar2_table(444) := '733D21312C723D21312C28703D285F3D286C3D746869732E24636F6E7461696E65722E717565727953656C6563746F7228222E76697369626C652229293D3D6E756C6C3F766F696420303A6C2E636C6173734C697374293D3D6E756C6C3F766F69642030';
wwv_flow_imp.g_varchar2_table(445) := '3A5F2E72656D6F7665293D3D6E756C6C7C7C702E63616C6C285F2C2276697369626C6522297D292C632E6F6E28746869732E247376672C226D6F7573657570222C6C3D3E7B746869732E6261725F6265696E675F647261676765643D6E756C6C2C6F2E66';
wwv_flow_imp.g_varchar2_table(446) := '6F7245616368285F3D3E7B5F2E246261722E66696E616C64782626285F2E646174655F6368616E67656428292C5F2E636F6D707574655F70726F677265737328292C5F2E7365745F616374696F6E5F636F6D706C657465642829297D297D292C74686973';
wwv_flow_imp.g_varchar2_table(447) := '2E62696E645F6261725F70726F677265737328297D62696E645F6261725F70726F677265737328297B6C657420743D302C653D6E756C6C2C693D6E756C6C2C733D6E756C6C2C723D6E756C6C3B632E6F6E28746869732E247376672C226D6F757365646F';
wwv_flow_imp.g_varchar2_table(448) := '776E222C222E68616E646C652E70726F6772657373222C286F2C68293D3E7B653D21302C743D6F2E6F6666736574587C7C6F2E6C61796572583B636F6E7374206C3D632E636C6F7365737428222E6261722D77726170706572222C68292E676574417474';
wwv_flow_imp.g_varchar2_table(449) := '7269627574652822646174612D696422293B693D746869732E6765745F626172286C292C733D692E246261725F70726F67726573732C723D692E246261722C732E66696E616C64783D302C732E6F77696474683D732E676574576964746828292C732E6D';
wwv_flow_imp.g_varchar2_table(450) := '696E5F64783D2D732E6F77696474682C732E6D61785F64783D722E676574576964746828292D732E676574576964746828297D293B636F6E737420613D746869732E636F6E6669672E69676E6F7265645F706F736974696F6E732E6D6170286F3D3E5B6F';
wwv_flow_imp.g_varchar2_table(451) := '2C6F2B746869732E636F6E6669672E636F6C756D6E5F77696474685D293B632E6F6E28746869732E247376672C226D6F7573656D6F7665222C6F3D3E7B69662821652972657475726E3B6C657420683D6F2E6F6666736574587C7C6F2E6C61796572583B';
wwv_flow_imp.g_varchar2_table(452) := '696628683E74297B6C6574205F3D612E66696E6428285B702C755D293D3E683E3D702626683C75293B666F72283B5F3B29683D5F5B315D2C5F3D612E66696E6428285B702C755D293D3E683E3D702626683C75297D656C73657B6C6574205F3D612E6669';
wwv_flow_imp.g_varchar2_table(453) := '6E6428285B702C755D293D3E683E702626683C3D75293B666F72283B5F3B29683D5F5B305D2C5F3D612E66696E6428285B702C755D293D3E683E702626683C3D75297D6C6574206C3D682D743B6C3E732E6D61785F64782626286C3D732E6D61785F6478';
wwv_flow_imp.g_varchar2_table(454) := '292C6C3C732E6D696E5F64782626286C3D732E6D696E5F6478292C732E73657441747472696275746528227769647468222C732E6F77696474682B6C292C632E6174747228692E2468616E646C655F70726F67726573732C226378222C732E676574456E';
wwv_flow_imp.g_varchar2_table(455) := '64582829292C732E66696E616C64783D6C7D292C632E6F6E28746869732E247376672C226D6F7573657570222C28293D3E7B653D21312C732626732E66696E616C6478262628732E66696E616C64783D302C692E70726F67726573735F6368616E676564';
wwv_flow_imp.g_varchar2_table(456) := '28292C692E7365745F616374696F6E5F636F6D706C6574656428292C693D6E756C6C2C733D6E756C6C2C723D6E756C6C297D297D6765745F616C6C5F646570656E64656E745F7461736B732874297B6C657420653D5B5D2C693D5B745D3B666F72283B69';
wwv_flow_imp.g_varchar2_table(457) := '2E6C656E6774683B297B636F6E737420733D692E7265647563652828722C61293D3E28723D722E636F6E63617428746869732E646570656E64656E63795F6D61705B615D292C72292C5B5D293B653D652E636F6E6361742873292C693D732E66696C7465';
wwv_flow_imp.g_varchar2_table(458) := '7228723D3E21692E696E636C75646573287229262621652E696E636C75646573287229297D72657475726E20652E66696C74657228426F6F6C65616E297D6765745F736E61705F706F736974696F6E28742C65297B6C657420693D313B636F6E73742073';
wwv_flow_imp.g_varchar2_table(459) := '3D746869732E6F7074696F6E732E736E61705F61747C7C746869732E636F6E6669672E766965775F6D6F64652E736E61705F61747C7C223164223B69662873213D3D22756E697422297B636F6E73747B6475726174696F6E3A6C2C7363616C653A5F7D3D';
wwv_flow_imp.g_varchar2_table(460) := '642E70617273655F6475726174696F6E2873293B693D642E636F6E766572745F7363616C657328746869732E636F6E6669672E766965775F6D6F64652E737465702C5F292F6C7D636F6E737420723D742528746869732E636F6E6669672E636F6C756D6E';
wwv_flow_imp.g_varchar2_table(461) := '5F77696474682F69293B6C657420613D742D722B28723C746869732E636F6E6669672E636F6C756D6E5F77696474682F692A323F303A746869732E636F6E6669672E636F6C756D6E5F77696474682F69292C6F3D652B613B636F6E737420683D613E303F';
wwv_flow_imp.g_varchar2_table(462) := '313A2D313B6C657420673D746869732E6765745F69676E6F7265645F726567696F6E286F2C68293B666F72283B672E6C656E6774683B296F2B3D746869732E636F6E6669672E636F6C756D6E5F77696474682A682C673D746869732E6765745F69676E6F';
wwv_flow_imp.g_varchar2_table(463) := '7265645F726567696F6E286F2C68292C672E6C656E6774687C7C286F2D3D746869732E636F6E6669672E636F6C756D6E5F77696474682A68293B72657475726E206F2D657D6765745F69676E6F7265645F726567696F6E28742C653D31297B7265747572';
wwv_flow_imp.g_varchar2_table(464) := '6E20653D3D3D313F746869732E636F6E6669672E69676E6F7265645F706F736974696F6E732E66696C74657228693D3E743E692626743C3D692B746869732E636F6E6669672E636F6C756D6E5F7769647468293A746869732E636F6E6669672E69676E6F';
wwv_flow_imp.g_varchar2_table(465) := '7265645F706F736974696F6E732E66696C74657228693D3E743E3D692626743C692B746869732E636F6E6669672E636F6C756D6E5F7769647468297D756E73656C6563745F616C6C28297B746869732E706F7075702626746869732E706F7075702E7061';
wwv_flow_imp.g_varchar2_table(466) := '72656E742E636C6173734C6973742E61646428226869646522292C746869732E24636F6E7461696E65722E717565727953656C6563746F72416C6C28222E646174652D72616E67652D686967686C6967687422292E666F724561636828743D3E742E636C';
wwv_flow_imp.g_varchar2_table(467) := '6173734C6973742E6164642822686964652229297D766965775F69732874297B72657475726E20747970656F6620743D3D22737472696E67223F746869732E636F6E6669672E766965775F6D6F64652E6E616D653D3D3D743A41727261792E6973417272';
wwv_flow_imp.g_varchar2_table(468) := '61792874293F742E736F6D6528766965775F6973293A746869732E636F6E6669672E766965775F6D6F64652E6E616D653D3D3D742E6E616D657D6765745F7461736B2874297B72657475726E20746869732E7461736B732E66696E6428653D3E652E6964';
wwv_flow_imp.g_varchar2_table(469) := '3D3D3D74297D6765745F6261722874297B72657475726E20746869732E626172732E66696E6428653D3E652E7461736B2E69643D3D3D74297D73686F775F706F7075702874297B746869732E6F7074696F6E732E706F707570213D3D2131262628746869';
wwv_flow_imp.g_varchar2_table(470) := '732E706F7075707C7C28746869732E706F7075703D6E6577204628746869732E24706F7075705F777261707065722C746869732E6F7074696F6E732E706F7075702C7468697329292C746869732E706F7075702E73686F77287429297D686964655F706F';
wwv_flow_imp.g_varchar2_table(471) := '70757028297B746869732E706F7075702626746869732E706F7075702E6869646528297D747269676765725F6576656E7428742C65297B746869732E6F7074696F6E735B226F6E5F222B745D2626746869732E6F7074696F6E735B226F6E5F222B745D2E';
wwv_flow_imp.g_varchar2_table(472) := '6170706C7928746869732C65297D766965775F69732874297B72657475726E20746869732E6F7074696F6E732E766965775F6D6F64652E6E616D653D3D3D747D6765744461746546726F6D436C69636B2874297B636F6E737420653D746869732E247376';
wwv_flow_imp.g_varchar2_table(473) := '672E676574426F756E64696E67436C69656E745265637428292C693D742E636C69656E74582D652E6C6566742C733D746869732E6C6F77657254657874733B69662821732E6C656E6774682972657475726E206E756C6C3B636F6E737420723D4D617468';
wwv_flow_imp.g_varchar2_table(474) := '2E666C6F6F7228692F746869732E636F6E6669672E636F6C756D6E5F7769647468292C613D735B725D3B69662821612972657475726E206E756C6C3B636F6E7374206F3D612E636C6173734E616D652E6D61746368282F646174655F285C647B347D2D5C';
wwv_flow_imp.g_varchar2_table(475) := '647B327D2D5C647B327D292F293B72657475726E206F3F6F5B315D3A6E756C6C7D6765745F6F6C646573745F7374617274696E675F6461746528297B72657475726E20746869732E7461736B732E6C656E6774683F746869732E7461736B732E6D617028';
wwv_flow_imp.g_varchar2_table(476) := '743D3E742E5F7374617274292E7265647563652828742C65293D3E653C3D743F653A74293A6E657720446174657D636C65617228297B76617220742C652C692C732C722C612C6F2C682C672C6C3B746869732E247376672E696E6E657248544D4C3D2222';
wwv_flow_imp.g_varchar2_table(477) := '2C28653D28743D746869732E24686561646572293D3D6E756C6C3F766F696420303A742E72656D6F7665293D3D6E756C6C7C7C652E63616C6C2874292C28733D28693D746869732E24736964655F686561646572293D3D6E756C6C3F766F696420303A69';
wwv_flow_imp.g_varchar2_table(478) := '2E72656D6F7665293D3D6E756C6C7C7C732E63616C6C2869292C28613D28723D746869732E2463757272656E745F686967686C69676874293D3D6E756C6C3F766F696420303A722E72656D6F7665293D3D6E756C6C7C7C612E63616C6C2872292C28683D';
wwv_flow_imp.g_varchar2_table(479) := '286F3D746869732E24657874726173293D3D6E756C6C3F766F696420303A6F2E72656D6F7665293D3D6E756C6C7C7C682E63616C6C286F292C286C3D28673D746869732E706F707570293D3D6E756C6C3F766F696420303A672E68696465293D3D6E756C';
wwv_flow_imp.g_varchar2_table(480) := '6C7C7C6C2E63616C6C2867297D7D532E564945575F4D4F44453D7B484F55523A775B305D2C515541525445525F4441593A775B315D2C48414C465F4441593A775B325D2C4441593A775B335D2C5745454B3A775B345D2C4D4F4E54483A775B355D2C5945';
wwv_flow_imp.g_varchar2_table(481) := '41523A775B365D7D3B66756E6374696F6E207A286E297B72657475726E206E2E6E616D652B225F222B4D6174682E72616E646F6D28292E746F537472696E67283336292E736C69636528322C3132297D66756E6374696F6E206B286E297B72657475726E';
wwv_flow_imp.g_varchar2_table(482) := '206E2E7265706C616365416C6C282220222C225F22292E7265706C616365416C6C28223A222C225F22292E7265706C616365416C6C28222E222C225F22297D72657475726E20537D293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6238961299952383)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_file_name=>'frappe-gantt.umd.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A2047616E747420436861727420726567696F6E20706C75672D696E202854656368526576582C207777772E74656368726576782E636F6D293A204672617070652047616E747420696E20556E6976657273616C205468656D6520636F6C6F7273202A';
wwv_flow_imp.g_varchar2_table(2) := '2F0A2E74782D47616E7474207B0A20202D2D74782D67742D62673A20766172282D2D75742D636F6D706F6E656E742D6261636B67726F756E642D636F6C6F722C2023666666293B0A20202D2D74782D67742D6C696E653A20766172282D2D75742D636F6D';
wwv_flow_imp.g_varchar2_table(3) := '706F6E656E742D626F726465722D636F6C6F722C207267626128302C20302C20302C202E313229293B0A20202D2D74782D67742D746578743A20766172282D2D75742D636F6D706F6E656E742D746578742D64656661756C742D636F6C6F722C20233166';
wwv_flow_imp.g_varchar2_table(4) := '32333333293B0A20202D2D74782D67742D6D757465643A20766172282D2D75742D636F6D706F6E656E742D746578742D6D757465642D636F6C6F722C2023366237303830293B0A20202D2D74782D67742D616363656E743A20766172282D2D75742D7061';
wwv_flow_imp.g_varchar2_table(5) := '6C657474652D7072696D6172792C2023333434326138293B0A0A20202F2A204672617070652047616E74742773206F776E207661726961626C6573202A2F0A20202D2D672D6261722D636F6C6F723A20636F6C6F722D6D697828696E20737267622C2076';
wwv_flow_imp.g_varchar2_table(6) := '6172282D2D74782D67742D616363656E7429203230252C20766172282D2D74782D67742D626729293B0A20202D2D672D6261722D626F726465723A207472616E73706172656E743B0A20202D2D672D70726F67726573732D636F6C6F723A20766172282D';
wwv_flow_imp.g_varchar2_table(7) := '2D74782D67742D616363656E74293B0A20202D2D672D65787065637465642D70726F67726573733A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D616363656E7429203435252C20766172282D2D74782D67742D626729';
wwv_flow_imp.g_varchar2_table(8) := '293B0A20202D2D672D6172726F772D636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D7465787429203535252C207472616E73706172656E74293B0A20202D2D672D68616E646C652D636F6C6F723A207661';
wwv_flow_imp.g_varchar2_table(9) := '72282D2D74782D67742D74657874293B0A20202D2D672D746578742D6461726B3A20766172282D2D74782D67742D74657874293B0A20202D2D672D746578742D6C696768743A20236666663B0A20202D2D672D746578742D6D757465643A20766172282D';
wwv_flow_imp.g_varchar2_table(10) := '2D74782D67742D6D75746564293B0A20202D2D672D6865616465722D6261636B67726F756E643A20766172282D2D74782D67742D6267293B0A20202D2D672D726F772D636F6C6F723A20766172282D2D74782D67742D6267293B0A20202D2D672D726F77';
wwv_flow_imp.g_varchar2_table(11) := '2D626F726465722D636F6C6F723A20766172282D2D74782D67742D6C696E65293B0A20202D2D672D626F726465722D636F6C6F723A20766172282D2D74782D67742D6C696E65293B0A20202D2D672D7469636B2D636F6C6F723A20636F6C6F722D6D6978';
wwv_flow_imp.g_varchar2_table(12) := '28696E20737267622C20766172282D2D74782D67742D74657874292036252C207472616E73706172656E74293B0A20202D2D672D7469636B2D636F6C6F722D746869636B3A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6774';
wwv_flow_imp.g_varchar2_table(13) := '2D7465787429203133252C207472616E73706172656E74293B0A20202D2D672D7765656B656E642D686967686C696768742D636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D746578742920332E35252C20';
wwv_flow_imp.g_varchar2_table(14) := '766172282D2D74782D67742D626729293B0A20202D2D672D7765656B656E642D6C6162656C2D636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D7465787429203130252C207472616E73706172656E74293B';
wwv_flow_imp.g_varchar2_table(15) := '0A20202D2D672D746F6461792D686967686C696768743A20236436343534353B0A20202D2D672D616374696F6E732D6261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D74657874292035252C20';
wwv_flow_imp.g_varchar2_table(16) := '766172282D2D74782D67742D626729293B0A20202D2D672D706F7075702D616374696F6E733A20766172282D2D74782D67742D6C696E65293B0A2020636F6C6F723A20766172282D2D74782D67742D74657874293B0A7D0A0A2E74782D47616E74742D62';
wwv_flow_imp.g_varchar2_table(17) := '6172207B20646973706C61793A20666C65783B20666C65782D777261703A20777261703B20616C69676E2D6974656D733A2063656E7465723B206761703A203870783B206D617267696E2D626F74746F6D3A20313070783B207D0A2E74782D47616E7474';
wwv_flow_imp.g_varchar2_table(18) := '2D7669657773207B0A2020646973706C61793A20696E6C696E652D666C65783B0A202070616464696E673A203370783B0A2020626F726465723A2031707820736F6C696420766172282D2D74782D67742D6C696E65293B0A2020626F726465722D726164';
wwv_flow_imp.g_varchar2_table(19) := '6975733A203970783B0A20206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D67742D74657874292033252C20766172282D2D74782D67742D626729293B0A7D0A2E74782D47616E74742D766965772C';
wwv_flow_imp.g_varchar2_table(20) := '0A2E74782D47616E74742D746F646179207B0A20206865696768743A20333070783B0A202070616464696E673A203020313270783B0A2020626F726465723A20303B0A2020626F726465722D7261646975733A203670783B0A20206261636B67726F756E';
wwv_flow_imp.g_varchar2_table(21) := '643A207472616E73706172656E743B0A2020636F6C6F723A20766172282D2D74782D67742D6D75746564293B0A2020666F6E743A20696E68657269743B0A2020666F6E742D73697A653A20313370783B0A2020666F6E742D7765696768743A203630303B';
wwv_flow_imp.g_varchar2_table(22) := '0A2020637572736F723A20706F696E7465723B0A7D0A2E74782D47616E74742D766965773A686F7665722C0A2E74782D47616E74742D746F6461793A686F766572207B20636F6C6F723A20766172282D2D74782D67742D74657874293B207D0A2E74782D';
wwv_flow_imp.g_varchar2_table(23) := '47616E74742D766965775B617269612D707265737365643D2274727565225D207B206261636B67726F756E643A20766172282D2D74782D67742D6267293B20636F6C6F723A20766172282D2D74782D67742D74657874293B20626F782D736861646F773A';
wwv_flow_imp.g_varchar2_table(24) := '2030203170782032707820726762612831362C2031392C2033342C202E3132293B207D0A2E74782D47616E74742D746F646179207B20646973706C61793A20696E6C696E652D666C65783B20616C69676E2D6974656D733A2063656E7465723B20676170';
wwv_flow_imp.g_varchar2_table(25) := '3A203670783B206865696768743A20333870783B20626F726465723A2031707820736F6C696420766172282D2D74782D67742D6C696E65293B20626F726465722D7261646975733A203970783B207D0A2E74782D47616E7474202E74782D47616E74742D';
wwv_flow_imp.g_varchar2_table(26) := '746F646179202E6661207B20666F6E742D73697A653A20313370783B207D0A2E74782D47616E74742D766965773A666F6375732D76697369626C652C0A2E74782D47616E74742D746F6461793A666F6375732D76697369626C65207B206F75746C696E65';
wwv_flow_imp.g_varchar2_table(27) := '3A2032707820736F6C696420766172282D2D74782D67742D616363656E74293B206F75746C696E652D6F66667365743A203170783B207D0A2E74782D47616E74742D737461747573207B206D617267696E2D6C6566743A206175746F3B20636F6C6F723A';
wwv_flow_imp.g_varchar2_table(28) := '20766172282D2D74782D67742D6D75746564293B20666F6E742D73697A653A20313370783B207D0A0A2E74782D47616E74742D6368617274202E67616E74742D636F6E7461696E6572207B0A2020626F726465723A2031707820736F6C69642076617228';
wwv_flow_imp.g_varchar2_table(29) := '2D2D74782D67742D6C696E65293B0A2020626F726465722D7261646975733A20313070783B0A20206261636B67726F756E643A20766172282D2D74782D67742D6267293B0A2020666F6E742D66616D696C793A20696E68657269743B0A7D0A2E74782D47';
wwv_flow_imp.g_varchar2_table(30) := '616E74742D63686172745B68696464656E5D2C202E74782D47616E74742D656D7074795B68696464656E5D207B20646973706C61793A206E6F6E653B207D0A2E74782D47616E74742D6368617274202E67616E7474202E6261722D6C6162656C207B2066';
wwv_flow_imp.g_varchar2_table(31) := '6F6E742D7765696768743A203630303B207D0A2E74782D47616E74742D6368617274202E67616E7474202E6261722D6C6162656C2E626967207B2066696C6C3A20766172282D2D74782D67742D74657874293B207D0A2E74782D47616E74742D63686172';
wwv_flow_imp.g_varchar2_table(32) := '74202E67616E7474202E6261722D777261707065723A666F637573207B206F75746C696E653A206E6F6E653B207D0A2E74782D47616E74742D6368617274202E67616E74742D636F6E7461696E6572202E706F7075702D77726170706572207B20626F72';
wwv_flow_imp.g_varchar2_table(33) := '6465723A2031707820736F6C696420766172282D2D74782D67742D6C696E65293B20626F726465722D7261646975733A20313070783B20636F6C6F723A20766172282D2D74782D67742D74657874293B207D0A0A2E74782D47616E74742D656D70747920';
wwv_flow_imp.g_varchar2_table(34) := '7B2070616464696E673A203332707820313670783B20626F726465723A203170782064617368656420766172282D2D74782D67742D6C696E65293B20626F726465722D7261646975733A20313070783B20636F6C6F723A20766172282D2D74782D67742D';
wwv_flow_imp.g_varchar2_table(35) := '6D75746564293B20746578742D616C69676E3A2063656E7465723B207D0A0A2F2A20746865207461736B207461626C6520697320666F722073637265656E2072656164657273206F6E6C79202A2F0A2E74782D47616E74742D73725461626C65207B0A20';
wwv_flow_imp.g_varchar2_table(36) := '20706F736974696F6E3A206162736F6C7574653B0A202077696474683A203170783B0A20206865696768743A203170783B0A20206F766572666C6F773A2068696464656E3B0A2020636C69703A20726563742830203020302030293B0A20207768697465';
wwv_flow_imp.g_varchar2_table(37) := '2D73706163653A206E6F777261703B0A7D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6239088732952383)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_file_name=>'gantt.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A0A202A2047616E747420436861727420726567696F6E20706C75672D696E20666F72204F7261636C652041504558202854656368526576582C207777772E74656368726576782E636F6D290A202A0A202A2074656368726576782E67616E74742E69';
wwv_flow_imp.g_varchar2_table(2) := '6E69742820726567696F6E496420292069732063616C6C6564206279207468652072656E6465722070726F6365647572652E204974207265616473207468652073657474696E677320616E6420746865207461736B732066726F6D0A202A20233C726567';
wwv_flow_imp.g_varchar2_table(3) := '696F6E49643E5F7461736B7320616E64206472617773207468656D20696E20233C726567696F6E49643E5F67616E74742077697468204672617070652047616E747420284D4954292C20706C7573206120746F6F6C62617220616E642061207461626C65';
wwv_flow_imp.g_varchar2_table(4) := '206F66207468650A202A207461736B7320666F722073637265656E20726561646572732E0A202A0A202A205461736B204A534F4E3A207B2069642C206E616D652C2073746172742C20656E642C2070726F67726573732C20646570656E64656E63696573';
wwv_flow_imp.g_varchar2_table(5) := '2C20636F6C6F722C206465736372697074696F6E207D3B20646174657320617320595959592D4D4D2D4444206F720A202A20595959592D4D4D2D444420484832343A4D492C20656E6420696E636C756465642E0A202A0A202A20617065782E726567696F';
wwv_flow_imp.g_varchar2_table(6) := '6E2820696420292E726566726573682829202F206368616E6765566965774D6F64652820224D6F6E7468222029202F207363726F6C6C546F546F6461792829202F206765745461736B7328290A202A204576656E7473206F6E2074686520726567696F6E';
wwv_flow_imp.g_varchar2_table(7) := '3A0A202A20202074782D67616E74742D636C69636B20207B2069642C207461736B207D202020202020202020202020202020202020202020202020202061207461736B2077617320636C69636B65640A202A20202074782D67616E74742D6368616E6765';
wwv_flow_imp.g_varchar2_table(8) := '207B2069642C2073746172742C20656E642C2070726F6772657373207D2020202020202020202061667465722061207461736B2773206461746573206F722070726F6772657373206368616E6765642028616E642077657265207361766564290A202A20';
wwv_flow_imp.g_varchar2_table(9) := '202074782D67616E74742D766965772020207B206D6F6465207D2020202020202020202020202020202020202020202020202020202020207468652074696D65207363616C65206368616E6765640A202A2F0A282066756E6374696F6E2820242C206170';
wwv_flow_imp.g_varchar2_table(10) := '65782029207B0A202020202275736520737472696374223B0A0A20202020636F6E7374206E73203D2077696E646F772E7465636872657678203D2077696E646F772E7465636872657678207C7C207B7D2C0A20202020202020204D4F444553203D207B20';
wwv_flow_imp.g_varchar2_table(11) := '686F75723A2022486F7572222C20717561727465724461793A20225175617274657220446179222C2068616C664461793A202248616C6620446179222C206461793A2022446179222C207765656B3A20225765656B222C206D6F6E74683A20224D6F6E74';
wwv_flow_imp.g_varchar2_table(12) := '68222C20796561723A20225965617222207D3B0A0A2020202066756E6374696F6E20656C28207461672C20636C732C20746578742029207B0A2020202020202020636F6E73742065203D20646F63756D656E742E637265617465456C656D656E74282074';
wwv_flow_imp.g_varchar2_table(13) := '616720293B0A20202020202020206966202820636C732029207B20652E636C6173734E616D65203D20636C733B207D0A202020202020202069662028207465787420213D206E756C6C2029207B20652E74657874436F6E74656E74203D20746578743B20';
wwv_flow_imp.g_varchar2_table(14) := '7D0A202020202020202072657475726E20653B0A202020207D0A0A20202020636F6E737420706164203D206E203D3E20537472696E6728206E20292E70616453746172742820322C2022302220293B0A0A202020202F2F2044617465202D3E2022595959';
wwv_flow_imp.g_varchar2_table(15) := '592D4D4D2D4444222C206F72207769746820223A48483A4D4922207768656E2069742068617320612074696D653B20616E20656E642061742032333A353920697320746861742077686F6C65206461790A2020202066756E6374696F6E20646174655465';
wwv_flow_imp.g_varchar2_table(16) := '78742820642C206973456E642029207B0A2020202020202020636F6E737420646179203D20642E67657446756C6C596561722829202B20222D22202B207061642820642E6765744D6F6E74682829202B20312029202B20222D22202B207061642820642E';
wwv_flow_imp.g_varchar2_table(17) := '67657444617465282920292C0A202020202020202020202020686D203D207061642820642E676574486F75727328292029202B20223A22202B207061642820642E6765744D696E75746573282920293B0A202020202020202072657475726E20686D203D';
wwv_flow_imp.g_varchar2_table(18) := '3D3D202230303A303022207C7C2028206973456E6420262620686D203D3D3D202232333A3539222029203F20646179203A20646179202B20222022202B20686D3B0A202020207D0A0A202020202F2F2061206C6967687465722062617220666F72202372';
wwv_flow_imp.g_varchar2_table(19) := '6762202F202372726767626220636F6C6F72733B206F746865722043535320636F6C6F72732061726520757365642061732074686579206172650A2020202066756E6374696F6E2074696E742820632029207B0A202020202020202069662028202F5E23';
wwv_flow_imp.g_varchar2_table(20) := '5B302D39612D665D7B337D242F692E7465737428206320292029207B2063203D20222322202B20632E736C69636528203120292E73706C69742820222220292E6D6170282078203D3E2078202B207820292E6A6F696E2820222220293B207D0A20202020';
wwv_flow_imp.g_varchar2_table(21) := '2020202072657475726E202F5E235B302D39612D665D7B367D242F692E746573742820632029203F2063202B2022333822203A20633B0A202020207D0A0A20202020636F6E7374206672617070654964203D206964203D3E20537472696E672820696420';
wwv_flow_imp.g_varchar2_table(22) := '292E7265706C61636528202F202F672C20225F2220293B0A0A202020202F2F207765656B656E64732061726520736861646564207768657265206120636F6C756D6E206973206120646179206F72206C6573733B20696E20776964657220636F6C756D6E';
wwv_flow_imp.g_varchar2_table(23) := '73207468657920776F756C64206265207468696E20737472697065730A20202020636F6E737420686F6C6964617973466F72203D206D6F6465203D3E205B2022486F7572222C20225175617274657220446179222C202248616C6620446179222C202244';
wwv_flow_imp.g_varchar2_table(24) := '617922205D2E696E636C7564657328206D6F64652029203F207B2022766172282D2D672D7765656B656E642D686967686C696768742D636F6C6F7229223A20227765656B656E6422207D203A207B7D3B0A0A20202020636C617373204368617274207B0A';
wwv_flow_imp.g_varchar2_table(25) := '2020202020202020636F6E7374727563746F722820726567696F6E49642029207B0A202020202020202020202020746869732E726567696F6E4964203D20726567696F6E49643B0A202020202020202020202020746869732E656C203D20646F63756D65';
wwv_flow_imp.g_varchar2_table(26) := '6E742E676574456C656D656E74427949642820726567696F6E4964202B20225F67616E74742220293B0A202020202020202020202020746869732E636667203D204A534F4E2E70617273652820646F63756D656E742E676574456C656D656E7442794964';
wwv_flow_imp.g_varchar2_table(27) := '2820726567696F6E4964202B20225F7461736B732220292E74657874436F6E74656E7420293B0A202020202020202020202020746869732E6665617475726573203D20537472696E672820746869732E6366672E6665617475726573207C7C2022222029';
wwv_flow_imp.g_varchar2_table(28) := '2E73706C69742820223A2220293B0A202020202020202020202020746869732E6D6F646573203D20537472696E672820746869732E6366672E766965774D6F646573207C7C20226461793A7765656B3A6D6F6E74682220292E73706C69742820223A2220';
wwv_flow_imp.g_varchar2_table(29) := '292E66696C74657228206D203D3E204D4F4445535B206D205D20293B0A202020202020202020202020696620282021746869732E6D6F6465732E6C656E6774682029207B20746869732E6D6F646573203D205B20227765656B22205D3B207D0A20202020';
wwv_flow_imp.g_varchar2_table(30) := '2020202020202020746869732E6D6F6465203D204D4F4445535B20746869732E6366672E64656661756C7456696577205D20262620746869732E6D6F6465732E696E636C756465732820746869732E6366672E64656661756C74566965772029203F204D';
wwv_flow_imp.g_varchar2_table(31) := '4F4445535B20746869732E6366672E64656661756C7456696577205D203A204D4F4445535B20746869732E6D6F6465735B2030205D205D3B0A202020202020202020202020746869732E7175657565203D20242E446566657272656428292E7265736F6C';
wwv_flow_imp.g_varchar2_table(32) := '766528292E70726F6D69736528293B0A202020202020202020202020746869732E6275696C6428293B0A202020202020202020202020746869732E7365745461736B732820746869732E6366672E7461736B73207C7C205B5D20293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(33) := '207D0A0A20202020202020206861732820662029207B2072657475726E20746869732E66656174757265732E696E636C7564657328206620293B207D0A0A20202020202020206275696C642829207B0A202020202020202020202020746869732E656C2E';
wwv_flow_imp.g_varchar2_table(34) := '74657874436F6E74656E74203D2022223B0A2020202020202020202020206966202820746869732E686173282022746F6F6C626172222029207C7C20746869732E686173282022746F6461792220292029207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(35) := '636F6E737420626172203D20656C282022646976222C202274782D47616E74742D6261722220293B0A202020202020202020202020202020206966202820746869732E686173282022746F6F6C62617222202920262620746869732E6D6F6465732E6C65';
wwv_flow_imp.g_varchar2_table(36) := '6E677468203E20312029207B0A2020202020202020202020202020202020202020636F6E7374207669657773203D20656C282022646976222C202274782D47616E74742D76696577732220293B0A20202020202020202020202020202020202020207669';
wwv_flow_imp.g_varchar2_table(37) := '6577732E736574417474726962757465282022726F6C65222C202267726F75702220293B0A202020202020202020202020202020202020202076696577732E736574417474726962757465282022617269612D6C6162656C222C202254696D6520736361';
wwv_flow_imp.g_varchar2_table(38) := '6C652220293B0A2020202020202020202020202020202020202020746869732E7669657742746E73203D20746869732E6D6F6465732E6D617028206D203D3E207B0A202020202020202020202020202020202020202020202020636F6E73742062203D20';
wwv_flow_imp.g_varchar2_table(39) := '656C282022627574746F6E222C202274782D47616E74742D76696577222C204D4F4445535B206D205D20293B0A202020202020202020202020202020202020202020202020622E74797065203D2022627574746F6E223B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(40) := '202020202020202020202020622E646174617365742E6D6F6465203D204D4F4445535B206D205D3B0A202020202020202020202020202020202020202020202020622E6164644576656E744C697374656E6572282022636C69636B222C202829203D3E20';
wwv_flow_imp.g_varchar2_table(41) := '746869732E6368616E6765566965774D6F646528204D4F4445535B206D205D202920293B0A20202020202020202020202020202020202020202020202076696577732E617070656E6428206220293B0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(42) := '2020202072657475726E20623B0A20202020202020202020202020202020202020207D20293B0A20202020202020202020202020202020202020206261722E617070656E642820766965777320293B0A202020202020202020202020202020207D0A2020';
wwv_flow_imp.g_varchar2_table(43) := '20202020202020202020202020206966202820746869732E686173282022746F6461792220292029207B0A2020202020202020202020202020202020202020636F6E737420746F646179203D20656C282022627574746F6E222C202274782D47616E7474';
wwv_flow_imp.g_varchar2_table(44) := '2D746F6461792220292C0A20202020202020202020202020202020202020202020202069636F6E203D20656C2820227370616E222C202266612066612D63616C656E6461722D636865636B2D6F2220293B0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(45) := '202069636F6E2E736574417474726962757465282022617269612D68696464656E222C2022747275652220293B0A2020202020202020202020202020202020202020746F6461792E74797065203D2022627574746F6E223B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(46) := '202020202020202020746F6461792E617070656E64282069636F6E2C20656C2820227370616E222C206E756C6C2C2022546F64617922202920293B0A2020202020202020202020202020202020202020746F6461792E6164644576656E744C697374656E';
wwv_flow_imp.g_varchar2_table(47) := '6572282022636C69636B222C202829203D3E20746869732E7363726F6C6C546F546F646179282920293B0A20202020202020202020202020202020202020206261722E617070656E642820746F64617920293B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(48) := '7D0A20202020202020202020202020202020746869732E737461747573203D20656C2820227370616E222C202274782D47616E74742D7374617475732220293B0A20202020202020202020202020202020746869732E7374617475732E73657441747472';
wwv_flow_imp.g_varchar2_table(49) := '6962757465282022726F6C65222C20227374617475732220293B0A202020202020202020202020202020206261722E617070656E642820746869732E73746174757320293B0A20202020202020202020202020202020746869732E656C2E617070656E64';
wwv_flow_imp.g_varchar2_table(50) := '282062617220293B0A2020202020202020202020207D0A202020202020202020202020746869732E686F7374203D20656C282022646976222C202274782D47616E74742D63686172742220293B0A2020202020202020202020202F2F2046726170706520';
wwv_flow_imp.g_varchar2_table(51) := '7265706F727473206120636C69636B207768656E2061206472616720656E64733B206F6E6C79206120707265737320616E642072656C6561736520696E206F6E6520706C616365206973206120636C69636B0A202020202020202020202020746869732E';
wwv_flow_imp.g_varchar2_table(52) := '686F73742E6164644576656E744C697374656E65722820226D6F757365646F776E222C2065203D3E207B20746869732E646F776E203D205B20652E636C69656E74582C20652E636C69656E7459205D3B20746869732E64726167676564203D2066616C73';
wwv_flow_imp.g_varchar2_table(53) := '653B207D2C207472756520293B0A202020202020202020202020746869732E686F73742E6164644576656E744C697374656E65722820226D6F7573657570222C2065203D3E207B0A20202020202020202020202020202020746869732E64726167676564';
wwv_flow_imp.g_varchar2_table(54) := '203D202121746869732E646F776E202626204D6174682E6162732820652E636C69656E7458202D20746869732E646F776E5B2030205D2029202B204D6174682E6162732820652E636C69656E7459202D20746869732E646F776E5B2031205D2029203E20';
wwv_flow_imp.g_varchar2_table(55) := '343B0A2020202020202020202020207D2C207472756520293B0A202020202020202020202020746869732E656D707479203D20656C282022646976222C202274782D47616E74742D656D707479222C20746869732E6366672E6E6F44617461466F756E64';
wwv_flow_imp.g_varchar2_table(56) := '207C7C20224E6F207461736B732E2220293B0A202020202020202020202020746869732E656D7074792E68696464656E203D20747275653B0A202020202020202020202020746869732E7461626C65203D20656C2820227461626C65222C202274782D47';
wwv_flow_imp.g_varchar2_table(57) := '616E74742D73725461626C652220293B0A202020202020202020202020746869732E656C2E617070656E642820746869732E686F73742C20746869732E656D7074792C20746869732E7461626C6520293B0A20202020202020207D0A0A20202020202020';
wwv_flow_imp.g_varchar2_table(58) := '202F2F20746865207461736B73206173204672617070652047616E74742077616E7473207468656D3B20467261707065206164647320697473206F776E206669656C647320746F207468657365206F626A656374730A2020202020202020667261707065';
wwv_flow_imp.g_varchar2_table(59) := '5461736B732829207B0A20202020202020202020202072657475726E20746869732E7461736B732E6D6170282074203D3E207B0A20202020202020202020202020202020636F6E7374207461736B203D207B0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(60) := '20202069643A2066726170706549642820742E696420292C0A20202020202020202020202020202020202020206E616D653A20742E6E616D65207C7C20537472696E672820742E696420292C0A2020202020202020202020202020202020202020737461';
wwv_flow_imp.g_varchar2_table(61) := '72743A20742E73746172742C0A2020202020202020202020202020202020202020656E643A20742E656E64207C7C20742E73746172742C0A202020202020202020202020202020202020202070726F67726573733A204D6174682E6D61782820302C204D';
wwv_flow_imp.g_varchar2_table(62) := '6174682E6D696E28203130302C204E756D6265722820742E70726F67726573732029207C7C2030202920292C0A2020202020202020202020202020202020202020646570656E64656E636965733A20742E646570656E64656E6369657320213D206E756C';
wwv_flow_imp.g_varchar2_table(63) := '6C203F20537472696E672820742E646570656E64656E636965732029203A2022222C0A20202020202020202020202020202020202020206465736372697074696F6E3A20742E6465736372697074696F6E207C7C2022220A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(64) := '202020207D3B0A202020202020202020202020202020206966202820742E636F6C6F722029207B0A20202020202020202020202020202020202020207461736B2E636F6C6F72203D2074696E742820742E636F6C6F7220293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(65) := '202020202020202020207461736B2E636F6C6F725F70726F6772657373203D20742E636F6C6F723B0A202020202020202020202020202020207D0A2020202020202020202020202020202072657475726E207461736B3B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(66) := '7D20293B0A20202020202020207D0A0A20202020202020207365745461736B7328207461736B732029207B0A202020202020202020202020746869732E7461736B73203D207461736B732E66696C746572282074203D3E20742E696420213D206E756C6C';
wwv_flow_imp.g_varchar2_table(67) := '20262620742E737461727420292E6D6170282074203D3E204F626A6563742E61737369676E28207B7D2C20742C207B2069643A20537472696E672820742E69642029207D202920293B0A202020202020202020202020746869732E627946726170706549';
wwv_flow_imp.g_varchar2_table(68) := '64203D206E6577204D61702820746869732E7461736B732E6D6170282074203D3E205B2066726170706549642820742E696420292C2074205D202920293B0A202020202020202020202020746869732E656D7074792E68696464656E203D20746869732E';
wwv_flow_imp.g_varchar2_table(69) := '7461736B732E6C656E677468203E20303B0A202020202020202020202020746869732E686F73742E68696464656E203D2021746869732E7461736B732E6C656E6774683B0A202020202020202020202020746869732E646573637269626528293B0A2020';
wwv_flow_imp.g_varchar2_table(70) := '20202020202020202020696620282021746869732E7461736B732E6C656E6774682029207B20746869732E67616E7474203D206E756C6C3B20746869732E686F73742E74657874436F6E74656E74203D2022223B20746869732E7072657373656428293B';
wwv_flow_imp.g_varchar2_table(71) := '2072657475726E3B207D0A0A202020202020202020202020636F6E73742068203D20746869732E6366672E6865696768742C0A202020202020202020202020202020206F7074696F6E73203D207B0A202020202020202020202020202020202F2F204672';
wwv_flow_imp.g_varchar2_table(72) := '617070652073746172747320696E207468652066697273742076696577206D6F6465206F6620746865206C6973740A20202020202020202020202020202020766965775F6D6F6465733A205B20746869732E6D6F6465205D2E636F6E6361742820746869';
wwv_flow_imp.g_varchar2_table(73) := '732E6D6F6465732E6D617028206D203D3E204D4F4445535B206D205D20292E66696C74657228206D203D3E206D20213D3D20746869732E6D6F6465202920292C0A202020202020202020202020202020206261725F6865696768743A20746869732E6366';
wwv_flow_imp.g_varchar2_table(74) := '672E626172486569676874207C7C2032382C0A2020202020202020202020202020202070616464696E673A2031362C0A20202020202020202020202020202020636F6E7461696E65725F6865696768743A2068203E2030203F2068203A20226175746F22';
wwv_flow_imp.g_varchar2_table(75) := '2C0A20202020202020202020202020202020726561646F6E6C795F64617465733A2021746869732E68617328202264617465732220292C0A20202020202020202020202020202020726561646F6E6C795F70726F67726573733A2021746869732E686173';
wwv_flow_imp.g_varchar2_table(76) := '28202270726F67726573732220292C0A20202020202020202020202020202020726561646F6E6C793A2021746869732E68617328202264617465732220292026262021746869732E68617328202270726F67726573732220292C0A202020202020202020';
wwv_flow_imp.g_varchar2_table(77) := '2020202020202073686F775F65787065637465645F70726F67726573733A2066616C73652C202F2F207475726E6564206F6E2062656C6F772C206F6E6365206974206973207361666520666F7220667574757265207461736B730A202020202020202020';
wwv_flow_imp.g_varchar2_table(78) := '2020202020202069676E6F72653A20746869732E6861732820227765656B656E6473222029203F205B20227765656B656E6422205D203A205B5D2C0A20202020202020202020202020202020686F6C69646179733A20686F6C6964617973466F72282074';
wwv_flow_imp.g_varchar2_table(79) := '6869732E6D6F646520292C0A20202020202020202020202020202020706F7075705F6F6E3A2022636C69636B222C0A20202020202020202020202020202020746F6461795F627574746F6E3A2066616C73652C0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(80) := '766965775F6D6F64655F73656C6563743A2066616C73652C0A202020202020202020202020202020207363726F6C6C5F746F3A2022746F646179222C0A202020202020202020202020202020206C616E67756167653A20646F63756D656E742E646F6375';
wwv_flow_imp.g_varchar2_table(81) := '6D656E74456C656D656E742E6C616E67207C7C2022656E222C0A202020202020202020202020202020206F6E5F636C69636B3A207461736B203D3E20746869732E636C69636B656428207461736B20292C0A202020202020202020202020202020206F6E';
wwv_flow_imp.g_varchar2_table(82) := '5F646174655F6368616E67653A2028207461736B2C2073746172742C20656E642029203D3E20746869732E6368616E67656428207461736B2C2073746172742C20656E6420292C0A202020202020202020202020202020206F6E5F70726F67726573735F';
wwv_flow_imp.g_varchar2_table(83) := '6368616E67653A207461736B203D3E20746869732E6368616E67656428207461736B2C207461736B2E5F73746172742C206E6577204461746528207461736B2E5F656E642E67657454696D652829202D2031303030202920292C0A202020202020202020';
wwv_flow_imp.g_varchar2_table(84) := '202020202020206F6E5F766965775F6368616E67653A206D6F6465203D3E207B0A2020202020202020202020202020202020202020746869732E6D6F6465203D206D6F64652E6E616D653B0A202020202020202020202020202020202020202074686973';
wwv_flow_imp.g_varchar2_table(85) := '2E7072657373656428293B0A2020202020202020202020202020202020202020696620282021746869732E73696C656E742029207B20617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D67';
wwv_flow_imp.g_varchar2_table(86) := '616E74742D76696577222C207B206D6F64653A206D6F64652E6E616D65207D20293B207D0A202020202020202020202020202020207D0A2020202020202020202020207D3B0A2020202020202020202020202F2F20776974686F757420746865206B6579';
wwv_flow_imp.g_varchar2_table(87) := '20467261707065207573657320697473206F776E20706F7075703B20756E646566696E656420776F756C64207265706C6163652069742077697468206E6F7468696E670A202020202020202020202020696620282021746869732E686173282022706F70';
wwv_flow_imp.g_varchar2_table(88) := '75702220292029207B206F7074696F6E732E706F707570203D2066616C73653B207D0A0A202020202020202020202020746869732E73696C656E74203D20747275653B0A202020202020202020202020746869732E686F73742E74657874436F6E74656E';
wwv_flow_imp.g_varchar2_table(89) := '74203D2022223B0A202020202020202020202020746869732E67616E7474203D206E65772077696E646F772E47616E74742820746869732E686F73742C20746869732E6672617070655461736B7328292C206F7074696F6E7320293B0A20202020202020';
wwv_flow_imp.g_varchar2_table(90) := '20202020206966202820746869732E68617328202265787065637465642220292029207B0A202020202020202020202020202020202F2F204672617070652047616E747420312E322E32206769766573207461736B732074686174207374617274206166';
wwv_flow_imp.g_varchar2_table(91) := '74657220746F6461792061206E656761746976652065787065637465642070726F67726573732028616E64207468652062726F777365720A202020202020202020202020202020202F2F2061206E65676174697665207769647468293B20697420697320';
wwv_flow_imp.g_varchar2_table(92) := '636C616D7065642061742030206F6E206974732062617220636C6173732C207468656E2074686520636861727420697320647261776E20616761696E20776974682069740A20202020202020202020202020202020636F6E73742070726F746F203D2074';
wwv_flow_imp.g_varchar2_table(93) := '6869732E67616E74742E6261727320262620746869732E67616E74742E626172735B2030205D202626204F626A6563742E67657450726F746F747970654F662820746869732E67616E74742E626172735B2030205D20293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(94) := '2020202020696620282070726F746F202626202170726F746F2E7478436C616D7065642029207B0A2020202020202020202020202020202020202020636F6E737420636F6D70757465203D2070726F746F2E636F6D707574655F65787065637465645F70';
wwv_flow_imp.g_varchar2_table(95) := '726F67726573733B0A202020202020202020202020202020202020202070726F746F2E636F6D707574655F65787065637465645F70726F6772657373203D2066756E6374696F6E2829207B0A202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(96) := '636F6D707574652E63616C6C28207468697320293B0A202020202020202020202020202020202020202020202020746869732E65787065637465645F70726F6772657373203D204D6174682E6D61782820302C20746869732E65787065637465645F7072';
wwv_flow_imp.g_varchar2_table(97) := '6F6772657373207C7C203020293B0A20202020202020202020202020202020202020207D3B0A202020202020202020202020202020202020202070726F746F2E7478436C616D706564203D20747275653B0A202020202020202020202020202020207D0A';
wwv_flow_imp.g_varchar2_table(98) := '20202020202020202020202020202020746869732E67616E74742E6F7074696F6E732E73686F775F65787065637465645F70726F6772657373203D20747275653B0A20202020202020202020202020202020746869732E67616E74742E6368616E67655F';
wwv_flow_imp.g_varchar2_table(99) := '766965775F6D6F64652820746869732E6D6F64652C207472756520293B0A2020202020202020202020207D0A202020202020202020202020746869732E73696C656E74203D2066616C73653B0A202020202020202020202020746869732E707265737365';
wwv_flow_imp.g_varchar2_table(100) := '6428293B0A20202020202020202020202072657175657374416E696D6174696F6E4672616D6528202829203D3E20746869732E7363726F6C6C546F546F646179282920293B0A20202020202020207D0A0A20202020202020202F2F2061207461626C6520';
wwv_flow_imp.g_varchar2_table(101) := '6F6620746865207461736B7320666F722073637265656E20726561646572732C2077686963682063616E6E6F74207573652074686520647261776E2063686172740A202020202020202064657363726962652829207B0A20202020202020202020202074';
wwv_flow_imp.g_varchar2_table(102) := '6869732E7461626C652E74657874436F6E74656E74203D2022223B0A202020202020202020202020636F6E737420636170203D20656C28202263617074696F6E222C206E756C6C2C20225461736B732220292C2068656164203D20656C28202274722220';
wwv_flow_imp.g_varchar2_table(103) := '292C20626F6479203D20656C28202274626F64792220293B0A2020202020202020202020205B20225461736B222C20225374617274222C2022456E64222C202250726F677265737322205D2E666F7245616368282068203D3E20686561642E617070656E';
wwv_flow_imp.g_varchar2_table(104) := '642820656C2820227468222C206E756C6C2C20682029202920293B0A202020202020202020202020636F6E7374207468656164203D20656C28202274686561642220293B0A20202020202020202020202074686561642E617070656E6428206865616420';
wwv_flow_imp.g_varchar2_table(105) := '293B0A202020202020202020202020746869732E7461736B732E666F7245616368282074203D3E207B0A20202020202020202020202020202020636F6E7374207472203D20656C28202274722220293B0A202020202020202020202020202020205B2074';
wwv_flow_imp.g_varchar2_table(106) := '2E6E616D652C20742E73746172742C20742E656E642C2028204E756D6265722820742E70726F67726573732029207C7C20302029202B20222522205D2E666F7245616368282076203D3E2074722E617070656E642820656C2820227464222C206E756C6C';
wwv_flow_imp.g_varchar2_table(107) := '2C20762029202920293B0A20202020202020202020202020202020626F64792E617070656E642820747220293B0A2020202020202020202020207D20293B0A202020202020202020202020746869732E7461626C652E617070656E6428206361702C2074';
wwv_flow_imp.g_varchar2_table(108) := '686561642C20626F647920293B0A20202020202020207D0A0A2020202020202020707265737365642829207B0A2020202020202020202020202820746869732E7669657742746E73207C7C205B5D20292E666F7245616368282062203D3E20622E736574';
wwv_flow_imp.g_varchar2_table(109) := '417474726962757465282022617269612D70726573736564222C20537472696E672820622E646174617365742E6D6F6465203D3D3D20746869732E6D6F64652029202920293B0A20202020202020207D0A0A2020202020202020636C69636B6564282074';
wwv_flow_imp.g_varchar2_table(110) := '61736B2029207B0A202020202020202020202020636F6E73742074203D20746869732E627946726170706549642E67657428207461736B2E696420293B0A20202020202020202020202069662028202174207C7C20746869732E64726167676564202920';
wwv_flow_imp.g_varchar2_table(111) := '7B2072657475726E3B207D0A2020202020202020202020206966202820746869732E6366672E636C69636B4974656D2029207B20617065782E6974656D2820746869732E6366672E636C69636B4974656D20292E73657456616C75652820742E69642029';
wwv_flow_imp.g_varchar2_table(112) := '3B207D0A202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D67616E74742D636C69636B222C207B2069643A20742E69642C207461736B3A204F626A6563742E';
wwv_flow_imp.g_varchar2_table(113) := '61737369676E28207B7D2C20742029207D20293B0A20202020202020207D0A0A20202020202020202F2F20412062617220776173206D6F7665642C20726573697A6564206F72206974732070726F677265737320647261676765642E20446570656E6461';
wwv_flow_imp.g_varchar2_table(114) := '6E74732074686174206D6F766520616C6F6E67207265706F7274206865726520746F6F2C20616C736F207768696C650A20202020202020202F2F20746865206472616720697320676F696E67206F6E2C20736F20746865206C617374207374617465206F';
wwv_flow_imp.g_varchar2_table(115) := '662065616368207461736B206973206B65707420616E64207361766564206F6E636520746865206368616E6765732073746F702E0A20202020202020206368616E67656428207461736B2C2073746172742C20656E642029207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(116) := '202020636F6E73742074203D20746869732E627946726170706549642E67657428207461736B2E696420293B0A202020202020202020202020696620282021742029207B2072657475726E3B207D0A202020202020202020202020746869732E70656E64';
wwv_flow_imp.g_varchar2_table(117) := '696E67203D20746869732E70656E64696E67207C7C206E6577204D617028293B0A202020202020202020202020746869732E70656E64696E672E7365742820742E69642C207B20742C206E6F773A207B2073746172743A20646174655465787428207374';
wwv_flow_imp.g_varchar2_table(118) := '61727420292C20656E643A2064617465546578742820656E642C207472756520292C2070726F67726573733A204D6174682E726F756E6428207461736B2E70726F6772657373207C7C20302029207D207D20293B0A202020202020202020202020636C65';
wwv_flow_imp.g_varchar2_table(119) := '617254696D656F75742820746869732E70656E64696E6754696D657220293B0A202020202020202020202020746869732E70656E64696E6754696D6572203D2073657454696D656F757428202829203D3E207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(120) := '636F6E7374206C697374203D2041727261792E66726F6D2820746869732E70656E64696E672E76616C756573282920293B0A20202020202020202020202020202020746869732E70656E64696E672E636C65617228293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(121) := '202020206C6973742E666F7245616368282070203D3E20746869732E736176652820702E742C20702E6E6F77202920293B0A2020202020202020202020207D2C2032353020293B0A20202020202020207D0A0A2020202020202020736176652820742C20';
wwv_flow_imp.g_varchar2_table(122) := '6E6F772029207B0A20202020202020202020202069662028206E6F772E7374617274203D3D3D20742E7374617274202626206E6F772E656E64203D3D3D20742E656E64202626206E6F772E70726F6772657373203D3D3D204D6174682E726F756E642820';
wwv_flow_imp.g_varchar2_table(123) := '4E756D6265722820742E70726F67726573732029207C7C203020292029207B2072657475726E3B207D0A202020202020202020202020636F6E73742064617461203D207B2069643A20742E69642C2073746172743A206E6F772E73746172742C20656E64';
wwv_flow_imp.g_varchar2_table(124) := '3A206E6F772E656E642C2070726F67726573733A206E6F772E70726F6772657373207D3B0A202020202020202020202020636F6E737420636F6D6D6974203D202829203D3E207B0A202020202020202020202020202020204F626A6563742E6173736967';
wwv_flow_imp.g_varchar2_table(125) := '6E2820742C206E6F7720293B0A20202020202020202020202020202020746869732E646573637269626528293B0A20202020202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49';
wwv_flow_imp.g_varchar2_table(126) := '642C202274782D67616E74742D6368616E6765222C206461746120293B0A2020202020202020202020207D3B0A202020202020202020202020696620282021746869732E6366672E63616E536176652029207B20636F6D6D697428293B2072657475726E';
wwv_flow_imp.g_varchar2_table(127) := '3B207D0A0A2020202020202020202020202F2F2073617665732072756E206F6E6520616674657220746865206F746865722C20696E20746865206F7264657220746865206368616E6765732068617070656E65640A202020202020202020202020746869';
wwv_flow_imp.g_varchar2_table(128) := '732E7175657565203D20746869732E71756575652E7468656E28202829203D3E207B0A20202020202020202020202020202020746869732E736574537461747573282022536176696E672220293B0A202020202020202020202020202020207265747572';
wwv_flow_imp.g_varchar2_table(129) := '6E20617065782E7365727665722E706C7567696E2820746869732E6366672E616A61784964656E7469666965722C207B0A20202020202020202020202020202020202020207830313A202253415645222C207830323A20742E69642C207830333A206E6F';
wwv_flow_imp.g_varchar2_table(130) := '772E73746172742C207830343A206E6F772E656E642C207830353A20537472696E6728206E6F772E70726F677265737320292C20706167654974656D733A20746869732E6366672E6974656D73546F5375626D69740A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(131) := '20207D2C207B2064617461547970653A20226A736F6E22207D20292E7468656E2820726573203D3E207B0A20202020202020202020202020202020202020206966202820726573202626207265732E7361766564203D3D3D2066616C73652029207B2074';
wwv_flow_imp.g_varchar2_table(132) := '6869732E72657665727428207265732E6D65737361676520293B207D20656C7365207B20636F6D6D697428293B20746869732E73657453746174757328202253617665642220293B207D0A202020202020202020202020202020207D2C2028206A715848';
wwv_flow_imp.g_varchar2_table(133) := '522C20746578745374617475732C206572726F722029203D3E207B0A202020202020202020202020202020202020202077696E646F772E636F6E736F6C652E7761726E28202247616E74742043686172743A2073617665206661696C6564222C20657272';
wwv_flow_imp.g_varchar2_table(134) := '6F7220293B0A2020202020202020202020202020202020202020746869732E72657665727428293B0A202020202020202020202020202020202020202072657475726E20242E446566657272656428292E7265736F6C766528293B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(135) := '20202020202020207D20293B0A2020202020202020202020207D20293B0A20202020202020207D0A0A20202020202020202F2F20647261777320746865206C617374207361766564207461736B7320616761696E2C206174207468652073616D65207363';
wwv_flow_imp.g_varchar2_table(136) := '726F6C6C20706F736974696F6E0A202020202020202072657665727428206D6573736167652029207B0A202020202020202020202020746869732E7365745374617475732820222220293B0A2020202020202020202020206966202820746869732E6761';
wwv_flow_imp.g_varchar2_table(137) := '6E74742029207B0A20202020202020202020202020202020746869732E73696C656E74203D20747275653B0A20202020202020202020202020202020746869732E67616E74742E73657475705F7461736B732820746869732E6672617070655461736B73';
wwv_flow_imp.g_varchar2_table(138) := '282920293B0A20202020202020202020202020202020746869732E67616E74742E6368616E67655F766965775F6D6F64652820746869732E6D6F64652C207472756520293B0A20202020202020202020202020202020746869732E73696C656E74203D20';
wwv_flow_imp.g_varchar2_table(139) := '66616C73653B0A2020202020202020202020207D0A202020202020202020202020617065782E6D6573736167652E636C6561724572726F727328293B0A202020202020202020202020617065782E6D6573736167652E73686F774572726F727328205B20';
wwv_flow_imp.g_varchar2_table(140) := '7B20747970653A20226572726F72222C206C6F636174696F6E3A202270616765222C206D6573736167653A206D657373616765207C7C2022546865207461736B20636F756C64206E6F742062652073617665642E222C20756E736166653A2066616C7365';
wwv_flow_imp.g_varchar2_table(141) := '207D205D20293B0A20202020202020207D0A0A20202020202020207365745374617475732820746578742029207B0A202020202020202020202020696620282021746869732E7374617475732029207B2072657475726E3B207D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(142) := '202020636C65617254696D656F75742820746869732E73746174757354696D657220293B0A202020202020202020202020746869732E7374617475732E74657874436F6E74656E74203D20746578743B0A20202020202020202020202069662028207465';
wwv_flow_imp.g_varchar2_table(143) := '7874203D3D3D20225361766564222029207B20746869732E73746174757354696D6572203D2073657454696D656F757428202829203D3E207B20746869732E7374617475732E74657874436F6E74656E74203D2022223B207D2C203135303020293B207D';
wwv_flow_imp.g_varchar2_table(144) := '0A20202020202020207D0A0A20202020202020206368616E6765566965774D6F646528206D6F64652029207B0A202020202020202020202020636F6E7374206E616D65203D204D4F4445535B206D6F6465205D207C7C206D6F64653B0A20202020202020';
wwv_flow_imp.g_varchar2_table(145) := '2020202020746869732E6D6F6465203D206E616D653B0A2020202020202020202020206966202820746869732E67616E74742029207B0A20202020202020202020202020202020746869732E67616E74742E6F7074696F6E732E686F6C6964617973203D';
wwv_flow_imp.g_varchar2_table(146) := '20686F6C6964617973466F7228206E616D6520293B0A20202020202020202020202020202020746869732E67616E74742E6368616E67655F766965775F6D6F646528206E616D652C207472756520293B0A20202020202020202020202020202020746869';
wwv_flow_imp.g_varchar2_table(147) := '732E7363726F6C6C546F546F64617928293B0A2020202020202020202020207D0A202020202020202020202020746869732E7072657373656428293B0A20202020202020207D0A0A20202020202020202F2F20746F6461792061626F7574206120746869';
wwv_flow_imp.g_varchar2_table(148) := '726420696E746F207468652076697369626C6520706172742C20736F20746865207461736B73206A75737420646F6E65206172652076697369626C652061732077656C6C0A20202020202020207363726F6C6C546F546F6461792829207B0A2020202020';
wwv_flow_imp.g_varchar2_table(149) := '20202020202020696620282021746869732E67616E74742029207B2072657475726E3B207D0A202020202020202020202020636F6E73742063203D20746869732E67616E74742E24636F6E7461696E65722C206C696E65203D20746869732E67616E7474';
wwv_flow_imp.g_varchar2_table(150) := '2E2463757272656E745F686967686C696768743B0A20202020202020202020202069662028206C696E6520262620632029207B0A20202020202020202020202020202020632E7363726F6C6C4C656674203D204D6174682E6D61782820302C2070617273';
wwv_flow_imp.g_varchar2_table(151) := '65466C6F617428206C696E652E7374796C652E6C6566742029202D20632E636C69656E745769647468202F203320293B0A2020202020202020202020207D20656C7365207B0A20202020202020202020202020202020746869732E67616E74742E736372';
wwv_flow_imp.g_varchar2_table(152) := '6F6C6C5F63757272656E7428293B0A2020202020202020202020207D0A20202020202020207D0A0A2020202020202020726566726573682829207B0A202020202020202020202020617065782E6576656E742E747269676765722820222322202B207468';
wwv_flow_imp.g_varchar2_table(153) := '69732E726567696F6E49642C2022617065786265666F7265726566726573682220293B0A20202020202020202020202072657475726E20617065782E7365727665722E706C7567696E2820746869732E6366672E616A61784964656E7469666965722C20';
wwv_flow_imp.g_varchar2_table(154) := '7B207830313A20224C495354222C20706167654974656D733A20746869732E6366672E6974656D73546F5375626D6974207D2C207B2064617461547970653A20226A736F6E22207D20290A202020202020202020202020202020202E646F6E6528206461';
wwv_flow_imp.g_varchar2_table(155) := '7461203D3E20746869732E7365745461736B732820646174612E7461736B73207C7C205B5D202920290A202020202020202020202020202020202E616C7761797328202829203D3E20617065782E6576656E742E747269676765722820222322202B2074';
wwv_flow_imp.g_varchar2_table(156) := '6869732E726567696F6E49642C20226170657861667465727265667265736822202920293B0A20202020202020207D0A202020207D0A0A20202020636F6E737420636861727473203D207B7D3B0A202020206E732E67616E7474203D207B0A2020202020';
wwv_flow_imp.g_varchar2_table(157) := '202020696E69742820726567696F6E49642029207B0A202020202020202020202020636F6E73742063203D206E65772043686172742820726567696F6E496420293B0A2020202020202020202020206368617274735B20726567696F6E4964205D203D20';
wwv_flow_imp.g_varchar2_table(158) := '633B0A202020202020202020202020617065782E726567696F6E2E6372656174652820726567696F6E49642C207B0A20202020202020202020202020202020747970653A2022546563685265765847616E7474222C0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(159) := '2020726566726573683A202829203D3E20632E7265667265736828292C0A202020202020202020202020202020206368616E6765566965774D6F64653A206D6F6465203D3E20632E6368616E6765566965774D6F646528206D6F646520292C0A20202020';
wwv_flow_imp.g_varchar2_table(160) := '2020202020202020202020207363726F6C6C546F546F6461793A202829203D3E20632E7363726F6C6C546F546F64617928292C0A202020202020202020202020202020206765745461736B733A202829203D3E20632E7461736B732E6D6170282074203D';
wwv_flow_imp.g_varchar2_table(161) := '3E204F626A6563742E61737369676E28207B7D2C2074202920292C0A2020202020202020202020202020202067657447616E74743A202829203D3E20632E67616E74742C0A202020202020202020202020202020207769646765743A202829203D3E2024';
wwv_flow_imp.g_varchar2_table(162) := '2820632E656C20290A2020202020202020202020207D20293B0A20202020202020207D2C0A20202020202020206765743A20726567696F6E4964203D3E206368617274735B20726567696F6E4964205D0A202020207D3B0A7D20292820617065782E6A51';
wwv_flow_imp.g_varchar2_table(163) := '756572792C206170657820293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6239101234952383)
,p_plugin_id=>wwv_flow_imp.id(6234579290952371)
,p_file_name=>'gantt.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
