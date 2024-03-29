<?php

/**
 * SAML 1.1 IdP configuration for SimpleSAMLphp.
 *
 * Note that SAML 1.1 support has been deprecated and will be removed in SimpleSAMLphp 2.0.
 *
 * See: https://simplesamlphp.org/docs/stable/simplesamlphp-reference-idp-hosted
 */

$metadata['__DYNAMIC:1__'] = [
    /*
     * The hostname of the server (VHOST) that will use this SAML entity.
     *
     * Can be '__DEFAULT__', to use this entry by default.
     */
    'host' => '__DEFAULT__',

    // X.509 key and certificate. Relative to the cert directory.
    'privatekey' => 'saml.pem',
    'certificate' => 'saml.crt',

    /*
     * Authentication source to use. Must be one that is configured in
     * 'config/authsources.php'.
     */
    'auth' => 'example-usersql',
];


$metadata['http://localhost:8082/simplesaml/saml2/idp/metadata.php'] = [
    'host' => '__DEFAULT__',
    'privatekey' => 'saml.pem',
    'certificate' => 'saml.crt',
    'auth' => 'example-sql',
];