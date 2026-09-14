  @application_endpoint_discovery
Feature: CAMARA Application Endpoint Discovery API, v0.2.0-rc.1 - Operation getOptimalAppEndpoints
  # Input to be provided by the implementation to the tester
  #
  # Implementation indications:
  # * apiRoot: API root of the server URL
  # * List of device identifier types which are supported, among: phoneNumber, ipv4Address, ipv6Address.
  #   For this version, CAMARA does not allow the use of networkAccessIdentifier, so it is considered by default as not supported.
  #
  # Testing assets:
  # * A device object which location is known by the network when connected.
  # * An appId identifying an application with at least one running instance.
  # * An appId identifying an application with running instances in more than one Edge Cloud Zone.
  # * An applicationEndpointsId identifying registered endpoints of the application identified by the appId above.
  # * An applicationEndpointsId identifying registered endpoints of a different application.
  #
  # References to OAS spec schemas refer to schemas specified in application-endpoint-discovery.yaml

  Background: Common getOptimalAppEndpoints setup
    Given an environment at "apiRoot"
    And the resource "/application-endpoint-discovery/v0.2rc1/retrieve-optimal-app-endpoints"
    And the header "Content-Type" is set to "application/json"
    And the header "Authorization" is set to a valid access token
    And the header "x-correlator" complies with the schema at "#/components/schemas/XCorrelator"
    And the request body is set by default to a request body compliant with the schema at "/components/schemas/EndpointDiscoveryInfo"

  # Success scenarios

  @application_endpoint_discovery_success_scenario_01_appid
  Scenario: Successful retrieval of the optimal application endpoint for a given device and application
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is set to a value identifying an application deployed on the platform with instances up and running
    And the request body property "$.applicationEndpointsId" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EndpointDiscoveryResult"
    And the response property "$.applicationEndpoints" contains at least one element, each complying with the OAS schema at "/components/schemas/ApplicationEndpoint"
    And the response property "$.appId" has same value as the request property "$.appId"
    And the response property "$.device" exists only if more than one device identifier was provided in the request body, and contains a single device identifier that was included in the request

  @application_endpoint_discovery_success_scenario_02_applicationEndpointsId
  Scenario: Successful retrieval of the optimal application endpoint for a given device and applicationEndpointsId
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationEndpointsId" is set to a value identifying application endpoints registered in the platform with instances up and running
    And the request body property "$.appId" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EndpointDiscoveryResult"
    And the response property "$.applicationEndpoints" contains at least one element, each complying with the OAS schema at "/components/schemas/ApplicationEndpoint"
    And the response property "$.applicationEndpointsId" has same value as the request property "$.applicationEndpointsId"

  @application_endpoint_discovery_success_scenario_03_appid_multiple_endpoints
  Scenario: Successful retrieval of multiple optimal application endpoints for a given device and application, ordered by optimality
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is set to a value identifying an application with instances up and running in more than one Edge Cloud Zone reachable from the testing device
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EndpointDiscoveryResult"
    And the response property "$.applicationEndpoints" contains more than one element, each complying with the OAS schema at "/components/schemas/ApplicationEndpoint"
    And the response property "$.applicationEndpoints" is ordered by optimality in descending order
    And the response property "$.applicationEndpoints[0]" is the endpoint with the shortest network path to the testing device

  @application_endpoint_discovery_success_scenario_04_multiple_device_identifiers
  Scenario: Device identifier echoed in response when using a 2-legged access token with multiple identifiers
    Given the header "Authorization" is set to a valid 2-legged access token which does not identify a single device
    And at least 2 types of device identifiers are supported by the implementation
    And the request body property "$.device" includes multiple valid device identifiers
    And the request body property "$.appId" is set to a value identifying an application deployed on the platform with instances up and running
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EndpointDiscoveryResult"
    And the response property "$.applicationEndpoints" contains at least one element, each complying with the OAS schema at "/components/schemas/ApplicationEndpoint"
    And the response property "$.device" exists
    And the response property "$.device" complies with the OAS schema at "/components/schemas/DeviceResponse"
    And the response property "$.device" contains a single device identifier that was included in the request

  @application_endpoint_discovery_success_scenario_05_appid_and_applicationEndpointsId
  Scenario: Successful retrieval when both appId and an associated applicationEndpointsId are provided
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is set to a value identifying an application deployed on the platform with instances up and running
    And the request body property "$.applicationEndpointsId" is set to a value identifying application endpoints registered for the same application
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 200
    And the response header "Content-Type" is "application/json"
    And the response header "x-correlator" has same value as the request header "x-correlator"
    And the response body complies with the OAS schema at "/components/schemas/EndpointDiscoveryResult"
    And the response property "$.applicationEndpoints" contains at least one element, each complying with the OAS schema at "/components/schemas/ApplicationEndpoint"
    And the response property "$.appId" has same value as the request property "$.appId"
    And the response property "$.applicationEndpointsId" has same value as the request property "$.applicationEndpointsId"

  # Error scenarios for management of input parameter device

  @application_endpoint_discovery_C01.01_device_empty
  Scenario: The device value is an empty object
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is set to: {}
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_C01.02_device_identifiers_not_schema_compliant
  Scenario Outline: Some device identifier value does not comply with the schema
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "<device_identifier>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | device_identifier                | oas_spec_schema                             |
      | $.device.phoneNumber             | /components/schemas/PhoneNumber             |
      | $.device.ipv4Address             | /components/schemas/DeviceIpv4Address       |
      | $.device.ipv6Address             | /components/schemas/DeviceIpv6Address       |
      | $.device.networkAccessIdentifier | /components/schemas/NetworkAccessIdentifier |

  # This scenario may happen e.g. with 2-legged access tokens, which do not identify a single device.
  @application_endpoint_discovery_C01.03_device_not_found
  Scenario: Some identifier cannot be matched to a device
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is compliant with the schema but does not identify a valid device
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "IDENTIFIER_NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_C01.04_unnecessary_device
  Scenario: Device not to be included when it can be deduced from the access token
    Given the header "Authorization" is set to a valid access token identifying a device
    And the request body property "$.device" is set to a valid device
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "UNNECESSARY_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_C01.05_missing_device
  Scenario: Device not included and cannot be deduced from the access token
    Given the header "Authorization" is set to a valid access token which does not identify a single device
    And the request body property "$.device" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "MISSING_IDENTIFIER"
    And the response property "$.message" contains a user friendly text

  # Error code 400

  @application_endpoint_discovery_400.1_no_request_body
  Scenario: Missing request body
    Given the request body is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_400.2_empty_request_body
  Scenario: Empty object as request body
    Given the request body is set to "{}"
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_400.3_other_input_properties_schema_not_compliant
  # Test other input properties in addition to device
  Scenario Outline: Input property values do not comply with the schema
    Given the request body property "<input_property>" does not comply with the OAS schema at "<oas_spec_schema>"
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

    Examples:
      | input_property           | oas_spec_schema                            |
      | $.appId                  | /components/schemas/AppId                  |
      | $.applicationEndpointsId | /components/schemas/ApplicationEndpointsId |

  @application_endpoint_discovery_400.4_no_application_identifier
  Scenario: Neither appId nor applicationEndpointsId is included in the request body
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is not included
    And the request body property "$.applicationEndpointsId" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_400.5_invalid_x-correlator
  Scenario: Invalid x-correlator value
    Given the header "x-correlator" does not comply with the OAS schema at "/components/schemas/XCorrelator"
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 400
    And the response property "$.status" is 400
    And the response property "$.code" is "INVALID_ARGUMENT"
    And the response property "$.message" contains a user friendly text

  # Error code 401

  @application_endpoint_discovery_401.1_no_authorization_header
  Scenario: No Authorization header
    Given the header "Authorization" is removed
    And the request body is set to a valid request body
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_401.2_expired_access_token
  Scenario: Expired access token
    Given the header "Authorization" is set to an expired access token
    And the request body is set to a valid request body
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 401
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_401.3_invalid_access_token
  Scenario: Invalid access token
    Given the header "Authorization" is set to an invalid access token
    And the request body is set to a valid request body
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 401
    And the response header "Content-Type" is "application/json"
    And the response property "$.status" is 401
    And the response property "$.code" is "UNAUTHENTICATED"
    And the response property "$.message" contains a user friendly text

  # Error code 403

  @application_endpoint_discovery_403_missing_scope
  Scenario: Missing scope in the access token
    Given the header "Authorization" is set to an access token without the required scope "application-endpoint-discovery:app-endpoints:read"
    And the request body is set to a valid request body
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 403
    And the response property "$.status" is 403
    And the response property "$.code" is "PERMISSION_DENIED"
    And the response property "$.message" contains a user friendly text

  # Error code 404

  @application_endpoint_discovery_404.1_application_not_found
  Scenario: The appId does not identify a valid application
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is compliant with the schema but does not identify a valid application on the Edge Cloud
    And the request body property "$.applicationEndpointsId" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  @application_endpoint_discovery_404.2_application_endpoints_id_not_found
  Scenario: The applicationEndpointsId does not identify any registered application endpoints
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.applicationEndpointsId" is compliant with the schema but does not identify any registered application endpoints on the Edge Cloud
    And the request body property "$.appId" is not included
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 404
    And the response property "$.status" is 404
    And the response property "$.code" is "NOT_FOUND"
    And the response property "$.message" contains a user friendly text

  # Error code 422

  @application_endpoint_discovery_422.1_identifier_mismatch
  Scenario: The applicationEndpointsId is not associated with the application identified by appId
    Given a valid testing device supported by the service, identified by the token or provided in the request body
    And the request body property "$.appId" is set to a value identifying an application deployed on the platform
    And the request body property "$.applicationEndpointsId" is set to a value identifying application endpoints registered for a different application
    When the request "getOptimalAppEndpoints" is sent
    Then the response status code is 422
    And the response property "$.status" is 422
    And the response property "$.code" is "APPLICATION_ENDPOINT_DISCOVERY.IDENTIFIER_MISMATCH"
    And the response property "$.message" contains a user friendly text
