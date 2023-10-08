<?php
return array(
  'utf_mode' =>
  array(
    'value' => true,
    'readonly' => true,
  ),
  'analytics_counter' =>
      array(
          'value' =>
              array(
                  'enabled' => false,
              ),
      ),
  'cache_flags' =>
  array(
    'value' =>
    array(
      'config_options' => 3600.0,
      'site_domain' => 3600.0,
    ),
    'readonly' => false,
  ),
  'cookies' =>
  array(
    'value' =>
    array(
      'secure' => true,
      'http_only' => false,
    ),
    'readonly' => false,
  ),
    'exception_handling' =>
        array(
            'value' =>
                array(
                    'debug' => true,
                    'handled_errors_types' => E_ALL & ~E_NOTICE & ~E_STRICT & ~E_USER_NOTICE & ~E_DEPRECATED,
                    'exception_errors_types' => E_ALL & ~E_NOTICE & ~E_WARNING & ~E_STRICT & ~E_USER_WARNING & ~E_USER_NOTICE & ~E_COMPILE_WARNING,
                    'ignore_silence' => false,
                    'assertion_throws_exception' => true,
                    'assertion_error_type' => 256,
                    'log' =>
                        array(
                            'settings' =>
                                array(
                                    'file' => 'bitrix/err.log',
                                    'log_size' => 1000000,
                                ),
                        ),
                ),
            'readonly' => false,
        ),
  'connections' =>
  array(
    'value' =>
    array(
      'default' =>
      array(
        'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
        'host' => 'tica-db-1',
        'database' => 'wordpress',
        'login' => 'wordpress',
        'password' => 'wordpress',
        'options' => 2.0,
      ),
    ),
    'readonly' => true,
  ),
  'crypto' =>
  array(
    'value' =>
    array(
      'crypto_key' => '5ff202c69bed3a91f743867fd32ba5f9',
    ),
    'readonly' => true,
  ),
);
