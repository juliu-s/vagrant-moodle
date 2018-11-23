USE moodle;
UPDATE mdl_config_plugins
SET
    value = '192.168.100.100:6379'
WHERE
    id = 156;

UPDATE mdl_config_plugins
SET
    value = '2'
WHERE
    id = 158;
