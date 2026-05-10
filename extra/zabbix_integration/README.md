# Zabbix-Oxidized Integration

**Status: Experimental/Embryonic** ⚠️

This is an early-stage integration between Zabbix and Oxidized that enables dynamic device discovery and configuration backup management. It works but is not yet battle-tested in large production environments.

## Overview

This integration allows you to:
- **Dynamically discover** network devices in Oxidized based on Zabbix host tags
- **Manage backup strategies** through Zabbix host inventory and device groups
- **Monitor backup status** with Zabbix alerts and historical data
- **Reload device lists** automatically without restarting Oxidized

### How It Works

```
┌─────────────────────────┐
│  Zabbix Database        │
│  (Host inventory,       │
│   Tags, Credentials)    │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  get-nodes.php          │
│  (Zabbix API Client)    │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Oxidized Web API       │
│  (http://localhost:8888)│
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│  Device Configs         │
│  (Git Repository)       │
└─────────────────────────┘
```

## Requirements

### System Requirements
- **Single server deployment**: Oxidized and Zabbix must run on **the same machine**
  - Both services accessible via `127.0.0.1`
  - No remote Zabbix API access (token-based only)
- **OS**: Linux (Ubuntu/Debian recommended)
- **PHP**: 7.4+ with `file_get_contents()` enabled
- **Apache**: 2.4+ with mod_proxy enabled
- **Oxidized**: Latest stable version with `oxidized-web` gem installed

### Software Versions Tested
- Zabbix 6.0 LTS
- Oxidized 0.29.x
- Apache 2.4.x
- PHP 7.4, 8.0, 8.1

## Installation

### Step 1: Create API Directory Structure

```bash
# Create the directory for the PHP API script
sudo mkdir -p /usr/local/share/oxidized-api

# Ensure proper ownership (adjust user/group if different)
sudo chown www-data:www-data /usr/local/share/oxidized-api
sudo chmod 755 /usr/local/share/oxidized-api
```

### Step 2: Install the PHP API Script

```bash
# Copy the get-nodes.php script
sudo cp get-nodes.php /usr/local/share/oxidized-api/

# Secure the script
sudo chmod 640 /usr/local/share/oxidized-api/get-nodes.php
sudo chown www-data:www-data /usr/local/share/oxidized-api/get-nodes.php
```

### Step 3: Configure Apache

```bash
# Copy the Apache configuration
sudo cp oxidized-get.conf /etc/apache2/conf-available/

# Enable the configuration
sudo a2enconf oxidized-get

# Verify configuration syntax (important!)
sudo apache2ctl configtest
# Should output: Syntax OK

# Create the password file for web UI access
# You'll be prompted to enter a password
sudo htpasswd -c /etc/apache2/.oxidized_pwd oxidized

# Reload Apache
sudo systemctl reload apache2
```

### Step 4: Configure Oxidized

```bash
# Copy the Oxidized configuration
sudo cp config /home/oxidized/.config/oxidized/config

# Adjust permissions
sudo chown oxidized:oxidized /home/oxidized/.config/oxidized/config
sudo chmod 600 /home/oxidized/.config/oxidized/config

# **IMPORTANT**: Edit the configuration and replace:
# - `ZabbixTokenHere` with your actual Zabbix API token (see Step 6)
# - Default credentials to match your environment
sudo nano /home/oxidized/.config/oxidized/config
```

Minimum configuration changes:
```yaml
url: http://127.0.0.1/oxidized-api/get-nodes.php?token=YOUR_ZABBIX_TOKEN_HERE
username: oxidized
password: your_device_password
```

### Step 5: Set Up Automatic Node Reload

Add to the **oxidized** user's crontab to reload the device list every hour:

```bash
# Edit oxidized user's crontab
sudo -u oxidized crontab -e

# Add this line:
0 * * * * /usr/bin/curl -s http://127.0.0.1:8888/oxidized/reload.json > /dev/null
```

**Why is this needed?**
- Without this cron job, Oxidized only reads the device list at startup
- Any changes to devices in Zabbix won't take effect until Oxidized restarts
- The reload endpoint forces Oxidized to re-fetch the device list from the API

### Step 6: Configure Zabbix API Token

**Create an API token in Zabbix:**

1. Log in to Zabbix as an **Admin** user
2. Navigate to **Administration** → **Users** → **API tokens**
3. Click **Create API token**
4. Fill in:
   - **Name**: `Oxidized API Token` (or similar)
   - **User**: Select a user with API access (create a dedicated user if desired)
   - **Auth token**: Let Zabbix generate one or provide your own
   - **Enabled**: ✓ (checked)
5. Click **Create**
6. Copy the token value
7. Update the Oxidized config:
   ```bash
   sudo nano /home/oxidized/.config/oxidized/config
   # Change: token=ZabbixTokenHere
   # To:     token=1234567890abcdef...
   ```

### Step 7: Import the Zabbix Template

The included template monitors the Oxidized server itself and provides visibility into backup status.

**Note:** The YAML template file is intentionally clean without comments (Zabbix import compatibility). Detailed documentation of all items, triggers, and preprocessing rules can be found in this README under the "How It Works" sections.

1. Log in to Zabbix
2. Navigate to **Data collection** → **Templates**
3. Click **Import**
4. Select file: `zbx_template_oxidized_server.yaml`
5. Click **Import**
6. Find the template "Template Oxidized Server"
7. Link it to your Oxidized server host in Zabbix (or Zabbix server entry)

### Template Items & Triggers Overview

Once imported, the template creates the following monitoring:

**Main Item:**
- **Oxd nodes-raw** (HTTP_AGENT, key: `nodes-raw`)
  - Fetches JSON list of all devices from Oxidized
  - Update interval: 1 hour
  - Serves as data source for all dependent items

**Discovered Items (per device):**
- **Epoch** - Timestamp of last backup (unix time)
  - Trigger: Fires if backup is older than `$OXIDIZED_MAX_AGE` (default 86400 = 1 day)
- **Status** - Backup status (success/failed)
  - Trigger: Fires if status ≠ "success"
- **Model** - Device model/driver used
- **Group** - Oxidized group assignment
- **Name** - Device hostname
- **Time** - Human-readable last backup timestamp
- **Mtime** - File modification timestamp

**Macros (customizable per host):**
- `{$OXIDIZEDPORT}` - Port for Oxidized web API (default 8888)
- `{$OXIDIZED_MAX_AGE}` - Max backup age before alert in seconds (default 86400)

### Step 8: Tag Devices for Backup

For each host you want Oxidized to back up:

1. Navigate to **Inventory** → **Hosts** (or **Data collection** → **Hosts**)
2. Edit each host
3. Add the tag:
   - **Name**: `Backup`
   - **Value**: `Oxidized`
4. In the **Inventory** section, set the **software_app_a** field to the device driver/model:
   - Common values: `dlinknextgen`, `ios`, `junos`, `iosxr`, `etc`
   - This is the Oxidized driver name for this device
5. Click **Update**

### Step 9: Verify Integration

```bash
# Test the API endpoint directly (requires valid token)
curl -s 'http://127.0.0.1/oxidized-api/get-nodes.php?token=YOUR_TOKEN' | jq .

# Expected output: JSON array of devices
# [
#   {
#     "name": "switch-01",
#     "model": "dxs",
#     "group": "DXS",
#     "ip": "192.168.1.100"
#   },
#   ...
# ]

# Check Oxidized logs
sudo -u oxidized tail -f /home/oxidized/.config/oxidized/logs/oxidized.log

# Wait for the next cron run or manually trigger reload:
curl -s http://127.0.0.1:8888/oxidized/reload.json
```

## Device-Specific Credentials and Groups

### Why Different Devices Need Different Credentials

Network devices often have different:
- **SSH/login requirements**: Some use specific user accounts
- **Authentication methods**: Key-based vs password-based
- **Connection timeouts**: Some devices respond slowly
- **Command sets**: Different OSes support different commands

Instead of creating one Oxidized account for all devices (bad practice), use **Oxidized groups** to define device-type-specific settings.

### Setting Up Groups in Oxidized Config

Define device groups in your Oxidized `config` file:

```yaml
groups:
  # DXS Group: For D-Link DXS switches
  DXS:
    username: oxidized_dxs
    password: dxs_special_password    # Dedicated account for DXS devices
    timeout: 45                        # Longer timeout for DXS devices
    
    
  # Default Group: Fallback for devices without specific group
  # (inherits from top-level username/password)
  default:
    timeout: 20
```

### How Groups Are Assigned

The PHP script assigns devices to groups based on their hardware **model** field in Zabbix inventory:

1. Device is queried from Zabbix
2. PHP script checks the **model** field (auto-populated by device templates)
3. If model contains "DXS" → assigned to `DXS` group → uses DXS credentials
4. If no match → falls back to `default` group

**Key benefit**: One Oxidized account per device type = better security, easier auditing, easier rotation.

### Example: Adding a New Device Group

To add support for a new device type:

1. **In Zabbix**: Ensure device templates populate the `model` field (usually automatic)
2. **In get-nodes.php**: Add logic to recognize the device:
   ```php
   elseif (strpos($host['inventory']['model'], 'NewDeviceModel') !== false) {
       $node['group'] = 'NewDevices';
   }
   ```
3. **In Oxidized config**: Add the group with its credentials:
   ```yaml
   NewDevices:
     username: oxidized_new
     password: new_device_password
     timeout: 35
   ```
4. **Restart/reload**: Trigger `curl -s http://127.0.0.1:8888/oxidized/reload.json`

## Customization

### Understanding Zabbix Inventory Fields in This Integration

Before customizing, understand how the integration uses Zabbix inventory fields:

- **software_app_a** → Oxidized driver/model (e.g., `dlinknextgen`, `ios`, `junos`)
  - How to set: Zabbix Inventory tab → select from Oxidized-supported drivers
  - Used for: Determining which protocol/parser Oxidized uses to connect to the device
  
- **model** → Hardware model auto-populated from device templates (e.g., `DXS-1210-28`)
  - How to set: Automatically via device templates (no manual entry needed)
  - Used for: Group assignment logic (which backup strategy/credentials to use)

**Key difference**: `software_app_a` tells Oxidized *how* to connect; `model` tells Oxidized *which group* to use.

### Customizing Device Group Assignment

The `get-nodes.php` script uses the hardware **model** field to assign devices to Oxidized groups.

**Current logic:**
```php
if (!empty($host['inventory']['model']) && strpos($host['inventory']['model'], 'DXS') !== false) {
    $node['group'] = 'DXS';
}
```

This checks the device hardware model field. If it contains "DXS" (e.g., `DXS-1210-28`), the device is assigned to the DXS group in Oxidized.

**Why this matters - Device-Specific Credentials:**

Different device models often require different credentials and connection parameters. By assigning devices to different Oxidized groups, you can specify unique settings per group:

- **DXS switches** (example): May use different username/password, higher timeouts
- **Cisco switches**: Different protocol, different credentials
- **Juniper routers**: Different protocol and auth method

Define these group-specific settings in the Oxidized `config` file:
```yaml
groups:
  DXS:
    username: oxidized_dxs          # DXS-specific account
    password: dxs_special_password   # DXS-specific credentials
    timeout: 45                      # Longer timeout for DXS devices
  default:
    username: oxidized              # Default account for other devices
    password: default_password
```

⚠️ **Best Practice**: Create dedicated Oxidized user accounts for each device group when they require different credentials. This improves security and auditability.

**Common customization examples:**

**1. Assign groups based on hardware model pattern:**
```php
if (!empty($host['inventory']['model'])) {
    if (strpos($host['inventory']['model'], 'DXS') !== false) {
        $node['group'] = 'DXS';
    } elseif (strpos($host['inventory']['model'], 'Catalyst') !== false) {
        $node['group'] = 'Cisco';
    } elseif (strpos($host['inventory']['model'], 'MX') !== false) {
        $node['group'] = 'Juniper';
    }
}
```

**2. Assign groups based on hostname pattern:**
```php
if (preg_match('/^dxs-/', $host['host'])) {
    $node['group'] = 'DXS';
} elseif (preg_match('/^cisco-/', $host['host'])) {
    $node['group'] = 'Cisco';
}
```

**3. Assign groups based on a custom Zabbix inventory field:**
```php
// First, add the field to selectInventory: "backup_group" or similar
if (!empty($host['inventory']['backup_group'])) {
    $node['group'] = $host['inventory']['backup_group'];
}
```

**4. Manufacturer-based grouping:**
```php
$manufacturer = $host['inventory']['manufacturer'] ?? '';
$deviceModel = $host['inventory']['model'] ?? '';

if (strpos($manufacturer, 'D-Link') !== false || strpos($deviceModel, 'DXS') !== false) {
    $node['group'] = 'DXS';
} elseif (strpos($manufacturer, 'Cisco') !== false) {
    $node['group'] = 'Cisco';
}
```

**5. Use Zabbix tags for group assignment:**
Edit the `$data['params']` to fetch host tags, then:
```php
$tags = $host['tags'] ?? [];
foreach ($tags as $tag) {
    if ($tag['tag'] === 'OxidizedGroup') {
        $node['group'] = $tag['value'];
        break;
    }
}
```

### Changing Host Filter Criteria

Modify the `params` section of `get-nodes.php` to change which hosts are selected:

**Include disabled hosts:**
```php
// Remove or modify: "filter" => ["status" => "0"]
// status: 0 = enabled, 1 = disabled
"filter" => ["status" => "1"],  // Only disabled hosts
```

**Add additional Zabbix tags:**
```php
"tags" => [
    ["tag" => "Backup", "value" => "Oxidized", "operator" => 1],
    ["tag" => "Environment", "value" => "Production", "operator" => 0]
]
```

**Filter by host group:**
```php
"groups" => ["10"],  // Replace 10 with Zabbix host group ID
```

## Troubleshooting

### Issue: "No hosts returned" or empty device list

**Check 1: Verify Zabbix tags**
```bash
# In Zabbix, verify each host has the tag:
# Tag: Backup
# Value: Oxidized
# (Navigate to: Inventory → Hosts → Edit → Tags)
```

**Check 2: Test API token**
```bash
curl -s 'http://127.0.0.1/oxidized-api/get-nodes.php?token=YOUR_TOKEN' | jq .
# Should return JSON array, not error
```

**Check 3: Check Apache logs**
```bash
sudo tail -50 /var/log/apache2/error.log
sudo tail -50 /var/log/apache2/access.log
```

### Issue: Oxidized doesn't update device list

**Check 1: Verify cron is running**
```bash
# Check if cron exists
sudo -u oxidized crontab -l

# Monitor cron logs (Linux-dependent)
sudo grep CRON /var/log/syslog | tail -20
```

**Check 2: Manually reload**
```bash
curl -s http://127.0.0.1:8888/oxidized/reload.json
```

**Check 3: Check Oxidized logs**
```bash
sudo -u oxidized tail -100 /home/oxidized/.config/oxidized/logs/oxidized.log
# Look for connection errors or JSON parsing issues
```

### Issue: 401 Unauthorized or "Missing authentication token"

**Solution:**
- Verify the token in `/home/oxidized/.config/oxidized/config` matches the one created in Zabbix
- Check token is not expired (Zabbix tokens have optional expiration dates)
- Ensure token user has API access permissions in Zabbix

### Issue: 403 Forbidden - "Zabbix API Error"

**Common causes:**
- API token is invalid or revoked
- Token user lacks API permissions
- Zabbix API endpoint unreachable (should be `http://127.0.0.1/zabbix/api_jsonrpc.php`)

**Debug:**
```bash
# Test API directly with curl
TOKEN="your_token_here"
curl -X POST 'http://127.0.0.1/zabbix/api_jsonrpc.php' \
  -H 'Content-Type: application/json' \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"user.get\",\"auth\":\"$TOKEN\",\"id\":1}"
```

## Notes for Production Use

⚠️ **Before deploying to production:**

1. **Change default credentials** in the Oxidized config
2. **Test with a small set of devices** first
3. **Monitor backup status** via Zabbix alerts
4. **Set up log rotation** for Oxidized logs (can grow large)
5. **Use SSH keys** instead of passwords where possible (requires Oxidized config changes)
6. **Secure the API script** - it should only be accessible from localhost (enforced in Apache config)
7. **Review custom group assignment logic** - make sure it correctly categorizes your devices

## Files Included

- `config` - Oxidized configuration with HTTP dynamic source
- `oxidized-get.conf` - Apache configuration
- `get-nodes.php` - Zabbix API client and node mapper
- `zbx_template_oxidized_server.yaml` - Zabbix template for monitoring
- `README.md` - This file

## Limitations & Known Issues

- **Same-machine only**: Oxidized and Zabbix must be on the same server (both access via localhost)
- **No advanced group logic by default**: Group assignment is hardcoded for DXS devices (customize as needed)
- **Manual Zabbix configuration**: Each device requires manual tag addition and inventory setup
- **No automatic device removal**: If a host is removed from Zabbix, Oxidized won't automatically un-back it up (requires config changes or Oxidized restart)


## Author Notes

This integration was built to solve a specific use case: managing network device backups via Zabbix's existing infrastructure. It prioritizes simplicity and local-deployment reliability over advanced features. Feedback and improvements are welcome!

---

**Version**: 1.0 (Experimental)  
**Last Updated**: May 2026
