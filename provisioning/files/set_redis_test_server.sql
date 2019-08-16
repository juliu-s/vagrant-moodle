USE moodle;
UPDATE mdl_config_plugins
SET
    value = '192.168.100.100:6379'
WHERE
    name = 'test_server';

UPDATE mdl_config_plugins
SET
    value = '2'
WHERE
    name = 'test_serializer';
