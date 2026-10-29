/*
 * Gantt Chart region plug-in for Oracle APEX (TechRevX, www.techrevx.com)
 *
 * techrevx.gantt.init( regionId ) is called by the render procedure. It reads the settings and the tasks from
 * #<regionId>_tasks and draws them in #<regionId>_gantt with Frappe Gantt (MIT), plus a toolbar and a table of the
 * tasks for screen readers.
 *
 * Task JSON: { id, name, start, end, progress, dependencies, color, description }; dates as YYYY-MM-DD or
 * YYYY-MM-DD HH24:MI, end included.
 *
 * apex.region( id ).refresh() / changeViewMode( "Month" ) / scrollToToday() / getTasks()
 * Events on the region:
 *   tx-gantt-click  { id, task }                          a task was clicked
 *   tx-gantt-change { id, start, end, progress }          after a task's dates or progress changed (and were saved)
 *   tx-gantt-view   { mode }                              the time scale changed
 */
( function( $, apex ) {
    "use strict";

    const ns = window.techrevx = window.techrevx || {},
        MODES = { hour: "Hour", quarterDay: "Quarter Day", halfDay: "Half Day", day: "Day", week: "Week", month: "Month", year: "Year" };

    function el( tag, cls, text ) {
        const e = document.createElement( tag );
        if ( cls ) { e.className = cls; }
        if ( text != null ) { e.textContent = text; }
        return e;
    }

    const pad = n => String( n ).padStart( 2, "0" );

    // Date -> "YYYY-MM-DD", or with ":HH:MI" when it has a time; an end at 23:59 is that whole day
    function dateText( d, isEnd ) {
        const day = d.getFullYear() + "-" + pad( d.getMonth() + 1 ) + "-" + pad( d.getDate() ),
            hm = pad( d.getHours() ) + ":" + pad( d.getMinutes() );
        return hm === "00:00" || ( isEnd && hm === "23:59" ) ? day : day + " " + hm;
    }

    // a lighter bar for #rgb / #rrggbb colors; other CSS colors are used as they are
    function tint( c ) {
        if ( /^#[0-9a-f]{3}$/i.test( c ) ) { c = "#" + c.slice( 1 ).split( "" ).map( x => x + x ).join( "" ); }
        return /^#[0-9a-f]{6}$/i.test( c ) ? c + "38" : c;
    }

    const frappeId = id => String( id ).replace( / /g, "_" );

    // weekends are shaded where a column is a day or less; in wider columns they would be thin stripes
    const holidaysFor = mode => [ "Hour", "Quarter Day", "Half Day", "Day" ].includes( mode ) ? { "var(--g-weekend-highlight-color)": "weekend" } : {};

    class Chart {
        constructor( regionId ) {
            this.regionId = regionId;
            this.el = document.getElementById( regionId + "_gantt" );
            this.cfg = JSON.parse( document.getElementById( regionId + "_tasks" ).textContent );
            this.features = String( this.cfg.features || "" ).split( ":" );
            this.modes = String( this.cfg.viewModes || "day:week:month" ).split( ":" ).filter( m => MODES[ m ] );
            if ( !this.modes.length ) { this.modes = [ "week" ]; }
            this.mode = MODES[ this.cfg.defaultView ] && this.modes.includes( this.cfg.defaultView ) ? MODES[ this.cfg.defaultView ] : MODES[ this.modes[ 0 ] ];
            this.queue = $.Deferred().resolve().promise();
            this.build();
            this.setTasks( this.cfg.tasks || [] );
        }

        has( f ) { return this.features.includes( f ); }

        build() {
            this.el.textContent = "";
            if ( this.has( "toolbar" ) || this.has( "today" ) ) {
                const bar = el( "div", "tx-Gantt-bar" );
                if ( this.has( "toolbar" ) && this.modes.length > 1 ) {
                    const views = el( "div", "tx-Gantt-views" );
                    views.setAttribute( "role", "group" );
                    views.setAttribute( "aria-label", "Time scale" );
                    this.viewBtns = this.modes.map( m => {
                        const b = el( "button", "tx-Gantt-view", MODES[ m ] );
                        b.type = "button";
                        b.dataset.mode = MODES[ m ];
                        b.addEventListener( "click", () => this.changeViewMode( MODES[ m ] ) );
                        views.append( b );
                        return b;
                    } );
                    bar.append( views );
                }
                if ( this.has( "today" ) ) {
                    const today = el( "button", "tx-Gantt-today" ),
                        icon = el( "span", "fa fa-calendar-check-o" );
                    icon.setAttribute( "aria-hidden", "true" );
                    today.type = "button";
                    today.append( icon, el( "span", null, "Today" ) );
                    today.addEventListener( "click", () => this.scrollToToday() );
                    bar.append( today );
                }
                this.status = el( "span", "tx-Gantt-status" );
                this.status.setAttribute( "role", "status" );
                bar.append( this.status );
                this.el.append( bar );
            }
            this.host = el( "div", "tx-Gantt-chart" );
            // Frappe reports a click when a drag ends; only a press and release in one place is a click
            this.host.addEventListener( "mousedown", e => { this.down = [ e.clientX, e.clientY ]; this.dragged = false; }, true );
            this.host.addEventListener( "mouseup", e => {
                this.dragged = !!this.down && Math.abs( e.clientX - this.down[ 0 ] ) + Math.abs( e.clientY - this.down[ 1 ] ) > 4;
            }, true );
            this.empty = el( "div", "tx-Gantt-empty", this.cfg.noDataFound || "No tasks." );
            this.empty.hidden = true;
            this.table = el( "table", "tx-Gantt-srTable" );
            this.el.append( this.host, this.empty, this.table );
        }

        // the tasks as Frappe Gantt wants them; Frappe adds its own fields to these objects
        frappeTasks() {
            return this.tasks.map( t => {
                const task = {
                    id: frappeId( t.id ),
                    name: t.name || String( t.id ),
                    start: t.start,
                    end: t.end || t.start,
                    progress: Math.max( 0, Math.min( 100, Number( t.progress ) || 0 ) ),
                    dependencies: t.dependencies != null ? String( t.dependencies ) : "",
                    description: t.description || ""
                };
                if ( t.color ) {
                    task.color = tint( t.color );
                    task.color_progress = t.color;
                }
                return task;
            } );
        }

        setTasks( tasks ) {
            this.tasks = tasks.filter( t => t.id != null && t.start ).map( t => Object.assign( {}, t, { id: String( t.id ) } ) );
            this.byFrappeId = new Map( this.tasks.map( t => [ frappeId( t.id ), t ] ) );
            this.empty.hidden = this.tasks.length > 0;
            this.host.hidden = !this.tasks.length;
            this.describe();
            if ( !this.tasks.length ) { this.gantt = null; this.host.textContent = ""; this.pressed(); return; }

            const h = this.cfg.height,
                options = {
                // Frappe starts in the first view mode of the list
                view_modes: [ this.mode ].concat( this.modes.map( m => MODES[ m ] ).filter( m => m !== this.mode ) ),
                bar_height: this.cfg.barHeight || 28,
                padding: 16,
                container_height: h > 0 ? h : "auto",
                readonly_dates: !this.has( "dates" ),
                readonly_progress: !this.has( "progress" ),
                readonly: !this.has( "dates" ) && !this.has( "progress" ),
                show_expected_progress: false, // turned on below, once it is safe for future tasks
                ignore: this.has( "weekends" ) ? [ "weekend" ] : [],
                holidays: holidaysFor( this.mode ),
                popup_on: "click",
                today_button: false,
                view_mode_select: false,
                scroll_to: "today",
                language: document.documentElement.lang || "en",
                on_click: task => this.clicked( task ),
                on_date_change: ( task, start, end ) => this.changed( task, start, end ),
                on_progress_change: task => this.changed( task, task._start, new Date( task._end.getTime() - 1000 ) ),
                on_view_change: mode => {
                    this.mode = mode.name;
                    this.pressed();
                    if ( !this.silent ) { apex.event.trigger( "#" + this.regionId, "tx-gantt-view", { mode: mode.name } ); }
                }
            };
            // without the key Frappe uses its own popup; undefined would replace it with nothing
            if ( !this.has( "popup" ) ) { options.popup = false; }

            this.silent = true;
            this.host.textContent = "";
            this.gantt = new window.Gantt( this.host, this.frappeTasks(), options );
            if ( this.has( "expected" ) ) {
                // Frappe Gantt 1.2.2 gives tasks that start after today a negative expected progress (and the browser
                // a negative width); it is clamped at 0 on its bar class, then the chart is drawn again with it
                const proto = this.gantt.bars && this.gantt.bars[ 0 ] && Object.getPrototypeOf( this.gantt.bars[ 0 ] );
                if ( proto && !proto.txClamped ) {
                    const compute = proto.compute_expected_progress;
                    proto.compute_expected_progress = function() {
                        compute.call( this );
                        this.expected_progress = Math.max( 0, this.expected_progress || 0 );
                    };
                    proto.txClamped = true;
                }
                this.gantt.options.show_expected_progress = true;
                this.gantt.change_view_mode( this.mode, true );
            }
            this.silent = false;
            this.pressed();
            requestAnimationFrame( () => this.scrollToToday() );
        }

        // a table of the tasks for screen readers, which cannot use the drawn chart
        describe() {
            this.table.textContent = "";
            const cap = el( "caption", null, "Tasks" ), head = el( "tr" ), body = el( "tbody" );
            [ "Task", "Start", "End", "Progress" ].forEach( h => head.append( el( "th", null, h ) ) );
            const thead = el( "thead" );
            thead.append( head );
            this.tasks.forEach( t => {
                const tr = el( "tr" );
                [ t.name, t.start, t.end, ( Number( t.progress ) || 0 ) + "%" ].forEach( v => tr.append( el( "td", null, v ) ) );
                body.append( tr );
            } );
            this.table.append( cap, thead, body );
        }

        pressed() {
            ( this.viewBtns || [] ).forEach( b => b.setAttribute( "aria-pressed", String( b.dataset.mode === this.mode ) ) );
        }

        clicked( task ) {
            const t = this.byFrappeId.get( task.id );
            if ( !t || this.dragged ) { return; }
            if ( this.cfg.clickItem ) { apex.item( this.cfg.clickItem ).setValue( t.id ); }
            apex.event.trigger( "#" + this.regionId, "tx-gantt-click", { id: t.id, task: Object.assign( {}, t ) } );
        }

        // A bar was moved, resized or its progress dragged. Dependants that move along report here too, also while
        // the drag is going on, so the last state of each task is kept and saved once the changes stop.
        changed( task, start, end ) {
            const t = this.byFrappeId.get( task.id );
            if ( !t ) { return; }
            this.pending = this.pending || new Map();
            this.pending.set( t.id, { t, now: { start: dateText( start ), end: dateText( end, true ), progress: Math.round( task.progress || 0 ) } } );
            clearTimeout( this.pendingTimer );
            this.pendingTimer = setTimeout( () => {
                const list = Array.from( this.pending.values() );
                this.pending.clear();
                list.forEach( p => this.save( p.t, p.now ) );
            }, 250 );
        }

        save( t, now ) {
            if ( now.start === t.start && now.end === t.end && now.progress === Math.round( Number( t.progress ) || 0 ) ) { return; }
            const data = { id: t.id, start: now.start, end: now.end, progress: now.progress };
            const commit = () => {
                Object.assign( t, now );
                this.describe();
                apex.event.trigger( "#" + this.regionId, "tx-gantt-change", data );
            };
            if ( !this.cfg.canSave ) { commit(); return; }

            // saves run one after the other, in the order the changes happened
            this.queue = this.queue.then( () => {
                this.setStatus( "Saving" );
                return apex.server.plugin( this.cfg.ajaxIdentifier, {
                    x01: "SAVE", x02: t.id, x03: now.start, x04: now.end, x05: String( now.progress ), pageItems: this.cfg.itemsToSubmit
                }, { dataType: "json" } ).then( res => {
                    if ( res && res.saved === false ) { this.revert( res.message ); } else { commit(); this.setStatus( "Saved" ); }
                }, ( jqXHR, textStatus, error ) => {
                    window.console.warn( "Gantt Chart: save failed", error );
                    this.revert();
                    return $.Deferred().resolve();
                } );
            } );
        }

        // draws the last saved tasks again, at the same scroll position
        revert( message ) {
            this.setStatus( "" );
            if ( this.gantt ) {
                this.silent = true;
                this.gantt.setup_tasks( this.frappeTasks() );
                this.gantt.change_view_mode( this.mode, true );
                this.silent = false;
            }
            apex.message.clearErrors();
            apex.message.showErrors( [ { type: "error", location: "page", message: message || "The task could not be saved.", unsafe: false } ] );
        }

        setStatus( text ) {
            if ( !this.status ) { return; }
            clearTimeout( this.statusTimer );
            this.status.textContent = text;
            if ( text === "Saved" ) { this.statusTimer = setTimeout( () => { this.status.textContent = ""; }, 1500 ); }
        }

        changeViewMode( mode ) {
            const name = MODES[ mode ] || mode;
            this.mode = name;
            if ( this.gantt ) {
                this.gantt.options.holidays = holidaysFor( name );
                this.gantt.change_view_mode( name, true );
                this.scrollToToday();
            }
            this.pressed();
        }

        // today about a third into the visible part, so the tasks just done are visible as well
        scrollToToday() {
            if ( !this.gantt ) { return; }
            const c = this.gantt.$container, line = this.gantt.$current_highlight;
            if ( line && c ) {
                c.scrollLeft = Math.max( 0, parseFloat( line.style.left ) - c.clientWidth / 3 );
            } else {
                this.gantt.scroll_current();
            }
        }

        refresh() {
            apex.event.trigger( "#" + this.regionId, "apexbeforerefresh" );
            return apex.server.plugin( this.cfg.ajaxIdentifier, { x01: "LIST", pageItems: this.cfg.itemsToSubmit }, { dataType: "json" } )
                .done( data => this.setTasks( data.tasks || [] ) )
                .always( () => apex.event.trigger( "#" + this.regionId, "apexafterrefresh" ) );
        }
    }

    const charts = {};
    ns.gantt = {
        init( regionId ) {
            const c = new Chart( regionId );
            charts[ regionId ] = c;
            apex.region.create( regionId, {
                type: "TechRevXGantt",
                refresh: () => c.refresh(),
                changeViewMode: mode => c.changeViewMode( mode ),
                scrollToToday: () => c.scrollToToday(),
                getTasks: () => c.tasks.map( t => Object.assign( {}, t ) ),
                getGantt: () => c.gantt,
                widget: () => $( c.el )
            } );
        },
        get: regionId => charts[ regionId ]
    };
} )( apex.jQuery, apex );
