USE moodle;
SELECT
    value
FROM
    mdl_config_plugins
WHERE
    name = 'test_server';

SELECT
    value
FROM
    mdl_config_plugins
WHERE
    name = 'test_serializer';
