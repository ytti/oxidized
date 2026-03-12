## 📘 Dynamic Model Selection with `model_rules`

If your devices are sourced from NetBox, CSV, or another external system, they often carry useful fields like `vendor`, `group`, `type`, `ip`, etc.  
With `model_rules` you can **automatically assign the correct Oxidized model** based on those fields.

### Enabling the Feature

Add to your Oxidized configuration file:

```yaml
model_rules_enable: true
model_rules:
  # your rules here
```

When `model_rules_enable` is set to `false` (the default), the old behaviour is used – only an explicit `model` field or the global `model` setting.

### How Rules Work (Step by Step)

1. If the device data already contains a **`model`** field (e.g., `model: ios`), it is used immediately – rules are ignored.
2. Otherwise, Oxidized goes through the list of rules **in the order you defined them**.
3. For each rule, **all specified fields** (except `model`) are compared against the device data. Comparison is **case‑insensitive** and strips leading/trailing spaces.
4. The **first rule** where **all fields match** wins – its `model` is assigned to the device.
5. If no rule matches, the global `model` setting (or the built‑in `junos` fallback if nothing is set) is used.

---

## 📊 Examples with Tables

### Sample Device Data (from NetBox/CSV)

| Name    | Vendor   | Type  | Group   | IP            |
|---------|----------|-------|---------|---------------|
| gw-001  | Mikrotik | RB750 | ro_ud   | 192.168.0.167 |
| gw-002  | Mikrotik | RB750 | ro_ud   | 192.168.0.177 |
| gw-003  | Mikrotik | RB750 | ro_bd   | 192.168.0.178 |
| gw-004  | Mikrotik | RB750 | switch  | 192.168.0.181 |
| gw-005  | Cisco    | 2960  | switch  | 192.168.0.179 |
| gw-006  | Mikrotik | RB750 | switch  | 192.168.0.180 |
| gw-007  | Juniper  | MX480 | core    | 192.168.1.1   |

---

### Example 1: Simple Rules by Vendor and Group

**Configuration:**
```yaml
model_rules_enable: true
model_rules:
  - vendor: Mikrotik
    model: routeros
  - vendor: Cisco
    group: switch
    model: ios
  - vendor: Juniper
    model: junos
```

**Result:**

| Device | Which rule matched?                                          | Model     |
|--------|--------------------------------------------------------------|-----------|
| gw-001 | Rule 1: `vendor: Mikrotik` → `routeros`                     | routeros  |
| gw-002 | Rule 1: `vendor: Mikrotik` → `routeros`                     | routeros  |
| gw-003 | Rule 1: `vendor: Mikrotik` → `routeros`                     | routeros  |
| gw-004 | Rule 1: `vendor: Mikrotik` → `routeros`                     | routeros  |
| gw-005 | Rule 2: `vendor: Cisco` + `group: switch` → `ios`           | ios       |
| gw-006 | Rule 1: `vendor: Mikrotik` → `routeros`                     | routeros  |
| gw-007 | Rule 3: `vendor: Juniper` → `junos`                         | junos     |

All MikroTik devices (regardless of group) get `routeros`, Cisco in group `switch` get `ios`, Juniper gets `junos`.

---

### Example 2: More Precise Rules (with Group, Type, and IP)

We want to differentiate MikroTik by group:  
- In group `ro_bd` with type `RB750` → `routeros`  
- In group `ro_ud` → `routeros`  
- In group `switch` for a specific IP → a special model `eltex`, other MikroTik in `switch` → `routeros`.

**Configuration:**
```yaml
model_rules_enable: true
model_rules:
  - vendor: Mikrotik
    type: RB750
    group: ro_bd
    model: routeros
  - vendor: Mikrotik
    group: ro_ud
    model: routeros
  - vendor: Cisco
    group: switch
    model: ios
  - vendor: Mikrotik
    group: switch
    ip: 192.168.0.180/24
    model: eltex
  - vendor: Mikrotik
    group: switch
    model: routeros
  - vendor: Juniper
    model: junos
```

**Result:**

| Device | Which rule matched?                                                                 | Model     |
|--------|--------------------------------------------------------------------------------------|-----------|
| gw-001 | Rule 2: `vendor: Mikrotik, group: ro_ud` → `routeros`                               | routeros  |
| gw-002 | Rule 2: `vendor: Mikrotik, group: ro_ud` → `routeros`                               | routeros  |
| gw-003 | Rule 1: `vendor: Mikrotik, type: RB750, group: ro_bd` → `routeros`                  | routeros  |
| gw-004 | Rule 5: `vendor: Mikrotik, group: switch` (IP didn't match) → `routeros`            | routeros  |
| gw-005 | Rule 3: `vendor: Cisco, group: switch` → `ios`                                      | ios       |
| gw-006 | Rule 4: `vendor: Mikrotik, group: switch, ip: 192.168.0.180/24` → `eltex`          | eltex     |
| gw-007 | Rule 6: `vendor: Juniper` → `junos`                                                 | junos     |

Notice that for `gw-006` the **fourth rule** matched because it appears before the generic MikroTik‑in‑switch rule. **Order matters!**

---

### Example 3: What If a Rule Contains a Non‑Existent Model?

If you mistype the model name, e.g.:

```yaml
- vendor: Mikrotik
  model: routeros_typo
```

Oxidized will attempt to load that model and fail with:

```
ModelNotFound: routeros_typo not found for node 192.168.0.167
```

This is intentional – it helps you catch configuration errors quickly.

---

### Example 4: Explicit `model` Field Overrides Everything

If your source data already contains a `model` column (e.g., `model: ios`), that value is used and rules are ignored:

| Name    | Vendor   | Group | Explicit model | Result |
|---------|----------|-------|----------------|--------|
| gw-100  | Mikrotik | switch| ios            | ios    |
| gw-101  | Cisco    | core  | (empty)        | (rules)|

---

## 🔧 How to Enable and Test

1. Open your Oxidized configuration file (usually `~/.config/oxidized/config`).
2. Add `model_rules_enable: true` and your list of `model_rules`.
3. Restart Oxidized.
4. (Optional) Set `debug: true` to see in the logs which rule matched.

If you need to temporarily disable the new logic, simply set `model_rules_enable: false` – everything reverts to the old behaviour.

---
