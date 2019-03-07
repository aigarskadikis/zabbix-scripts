-- Check orphaned alerts entries
SELECT count(*) FROM alerts WHERE NOT actionid IN (SELECT actionid FROM actions);
SELECT count(*) FROM alerts WHERE NOT eventid IN (SELECT eventid FROM events);
SELECT count(*) FROM alerts WHERE NOT userid IN (SELECT userid FROM users);
SELECT count(*) FROM alerts WHERE NOT mediatypeid IN (SELECT mediatypeid FROM media_type);

-- Check orphaned application entries that no longer map back to a host
SELECT count(*) FROM applications WHERE NOT hostid IN (SELECT hostid FROM hosts);

-- Check orphaned auditlog details (such as logins)
SELECT count(*) FROM auditlog_details WHERE NOT auditid IN (SELECT auditid FROM auditlog);
SELECT count(*) FROM auditlog WHERE NOT userid IN (SELECT userid FROM users);

-- Check orphaned conditions
SELECT count(*) FROM conditions WHERE NOT actionid IN (SELECT actionid FROM actions);

-- Check orphaned functions
SELECT count(*) FROM functions WHERE NOT itemid IN (SELECT itemid FROM items);
SELECT count(*) FROM functions WHERE NOT triggerid IN (SELECT triggerid FROM triggers);

-- Check orphaned graph items
SELECT count(*) FROM graphs_items WHERE NOT graphid IN (SELECT graphid FROM graphs);
SELECT count(*) FROM graphs_items WHERE NOT itemid IN (SELECT itemid FROM items);

-- Check orphaned host macro's
SELECT count(*) FROM hostmacro WHERE NOT hostid IN (SELECT hostid FROM hosts);

-- detect orphaned item data
SELECT count(*) FROM items WHERE hostid NOT IN (SELECT hostid FROM hosts);
SELECT count(*) FROM items_applications WHERE applicationid NOT IN (SELECT applicationid FROM applications);
SELECT count(*) FROM items_applications WHERE itemid NOT IN (SELECT itemid FROM items);

-- Check orphaned HTTP check data
SELECT count(*) FROM httpstep WHERE NOT httptestid IN (SELECT httptestid FROM httptest);
SELECT count(*) FROM httpstepitem WHERE NOT httpstepid IN (SELECT httpstepid FROM httpstep);
SELECT count(*) FROM httpstepitem WHERE NOT itemid IN (SELECT itemid FROM items);
SELECT count(*) FROM httptest WHERE applicationid NOT IN (SELECT applicationid FROM applications);

-- Check orphaned maintenance data
SELECT count(*) FROM maintenances_groups WHERE maintenanceid NOT IN (SELECT maintenanceid FROM maintenances);
SELECT count(*) FROM maintenances_groups WHERE groupid NOT IN (SELECT groupid FROM groups);
SELECT count(*) FROM maintenances_hosts WHERE maintenanceid NOT IN (SELECT maintenanceid FROM maintenances);
SELECT count(*) FROM maintenances_hosts WHERE hostid NOT IN (SELECT hostid FROM hosts);
SELECT count(*) FROM maintenances_windows WHERE maintenanceid NOT IN (SELECT maintenanceid FROM maintenances);
SELECT count(*) FROM maintenances_windows WHERE timeperiodid NOT IN (SELECT timeperiodid FROM timeperiods);

-- Check orphaned mappings
SELECT count(*) FROM mappings WHERE NOT valuemapid IN (SELECT valuemapid FROM valuemaps);

-- Check orphaned media items
SELECT count(*) FROM media WHERE NOT userid IN (SELECT userid FROM users);
SELECT count(*) FROM media WHERE NOT mediatypeid IN (SELECT mediatypeid FROM media_type);
SELECT count(*) FROM rights WHERE NOT groupid IN (SELECT usrgrpid FROM usrgrp);
SELECT count(*) FROM rights WHERE NOT id IN (SELECT groupid FROM groups);
SELECT count(*) FROM sessions WHERE NOT userid IN (SELECT userid FROM users);

-- Screens
SELECT count(*) FROM screens_items WHERE screenid NOT IN (SELECT screenid FROM screens);

-- detect Events & triggers
SELECT count(*) FROM trigger_depends WHERE triggerid_down NOT IN (SELECT triggerid FROM triggers);
SELECT count(*) FROM trigger_depends WHERE triggerid_up NOT IN (SELECT triggerid FROM triggers);

-- Check records in the history/trends table where items that no longer exist
SELECT count(*) FROM history WHERE itemid NOT IN (SELECT itemid FROM items);
SELECT count(*) FROM history_uint WHERE itemid NOT IN (SELECT itemid FROM items);
SELECT count(*) FROM history_log WHERE itemid NOT IN (SELECT itemid FROM items);
SELECT count(*) FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items);
SELECT count(*) FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items);

SELECT count(*) FROM trends WHERE itemid NOT IN (SELECT itemid FROM items);
SELECT count(*) FROM trends_uint WHERE itemid NOT IN (SELECT itemid FROM items);

-- detect records in the events table where triggers/items no longer exist
SELECT count(*) FROM events WHERE source = 0 AND object = 0 AND objectid NOT IN (SELECT triggerid FROM triggers);
SELECT count(*) FROM events WHERE source = 3 AND object = 0 AND objectid NOT IN (SELECT triggerid FROM triggers);
SELECT count(*) FROM events WHERE source = 3 AND object = 4 AND objectid NOT IN (SELECT itemid FROM items);

-- detect all orphaned acknowledge entries
SELECT count(*) FROM acknowledges WHERE eventid NOT IN (SELECT eventid FROM events);
SELECT count(*) FROM acknowledges WHERE userid NOT IN (SELECT userid FROM users);
