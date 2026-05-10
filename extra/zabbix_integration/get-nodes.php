<?php
/**
 * /usr/local/share/oxidized-api/get-nodes.php
 * 
 * Zabbix-Oxidized Integration API
 * 
 * This script queries the Zabbix API to fetch devices marked for backup.
 * It returns a JSON array of devices that Oxidized will use to discover
 * and back up network configurations.
 * 
 * Security:
 * - Requires a valid Zabbix API token in the 'token' query parameter
 * - Should only be accessible from localhost (enforced in Apache config)
 * 
 * Device Discovery:
 * - Fetches hosts tagged with 'Backup: Oxidized' in Zabbix
 * - Only includes hosts with status = 0 (enabled)
 * - Maps Zabbix inventory fields to Oxidized node properties
 * 
 * Customization:
 * - Modify the $data['params'] array to change which hosts are selected
 * - Customize the device mapping logic to suit your environment
 * - Add additional inventory fields as needed
 */

// Retrieve the Zabbix API token from query string
// This token must be obtained from Zabbix (see README.md)
$token = $_GET['token'] ?? null;

// Validate token presence
if (!$token) {
    header('HTTP/1.1 401 Unauthorized');
    die("Missing authentication token.");
}

// Zabbix API endpoint (adjust if Zabbix is on a different server)
$zabbix_api = 'http://127.0.0.1/zabbix/api_jsonrpc.php';

// Prepare the API request to fetch hosts
$data = [
    "jsonrpc" => "2.0",
    "method" => "host.get",
    "params" => [
        // Return only the hostname
        "output" => ["host"],
        
        // Fetch inventory fields:
        // - software_app_a: Used to store the device model/driver (e.g., 'dxs', 'junos')
        // - model: Device hardware model (optional, for documentation)
        // CUSTOMIZE THESE FIELDS if your Zabbix inventory uses different field names!
        "selectInventory" => ["software_app_a", "model"],
        
        // Fetch interface IP addresses (first interface is used for SSH connection)
        "selectInterfaces" => ["ip"],
        
        // Filter only enabled hosts (status = 0)
        // Set to "1" if you want to include disabled hosts
        "filter" => ["status" => "0"],
        
        // IMPORTANT: Filter by tag 'Backup: Oxidized'
        // In Zabbix, add this tag to every host you want Oxidized to back up
        // If you use a different tag name, change 'Backup' and 'Oxidized' accordingly
        "tags" => [["tag" => "Backup", "value" => "Oxidized", "operator" => 1]]
    ],
    "auth" => $token,
    "id" => 1
];

// Configure HTTP stream context for the POST request
$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\n",
        'method'  => 'POST',
        'content' => json_encode($data),
        'ignore_errors' => true
    ],
];

$context = stream_context_create($options);
$result = file_get_contents($zabbix_api, false, $context);

// Decode Zabbix API response
$response = json_decode($result, true);

// Check for Zabbix API errors (e.g., invalid token, permission issues)
if (isset($response['error'])) {
    header('HTTP/1.1 403 Forbidden');
    echo json_encode([
        "error" => "Zabbix API Error",
        "details" => $response['error']['data']
    ]);
    exit;
}

// Transform Zabbix hosts into Oxidized node format
$nodes = [];
foreach ($response['result'] as $host) {
    // Build the basic node object
    $node = [
        "name"  => $host['host'],                                  // Hostname
        "model" => $host['inventory']['software_app_a'] ?? 'default', // Driver/model
        "ip"    => $host['interfaces'][0]['ip'] ?? $host['host']   // IP for SSH connection
    ];
    
    // CUSTOMIZATION POINT: Device Group Assignment Logic
    // This example assigns devices to the 'DXS' group if their hardware model contains 'DXS'
    // Use the 'model' field (Zabbix inventory) which is auto-populated by device templates
    // This allows different backup strategies (passwords, timeouts) per device group
    // 
    // Example: D-Link DXS-1210 switches need different credentials than other models
    // Modify this logic to match your device naming/classification scheme
    // 
    // Example alternatives:
    // 1. Check hardware model (current): if (strpos(...'inventory']['model'], 'DXS') !== false)
    // 2. Check hostname pattern: if (preg_match('/^dxs-/', $host['host']))
    // 3. Use a custom Zabbix field: if ($host['inventory']['custom_field'] === 'group_name')
    // 4. Multiple groups: assign different groups based on device type/manufacturer
    
    if (!empty($host['inventory']['model']) && strpos($host['inventory']['model'], 'DXS') !== false) {
        // Assign to DXS group (which must be defined in Oxidized config)
        // This group has different credentials suitable for D-Link DXS devices
        $node['group'] = 'DXS';
    }
    // If no group is assigned, Oxidized uses the 'default' group from its config
    
    $nodes[] = $node;
}

// Return JSON array of nodes
header('Content-Type: application/json');
echo json_encode($nodes);
