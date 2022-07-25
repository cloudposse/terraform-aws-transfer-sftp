# Migration from 0.6.0 to 0.7.x+

Change the following

- `security_group_enabled` to `create_security_group`
- `security_group_use_name_prefix` to `security_group_name`
- `security_group_rules` to `additional_security_group_rules` and omit the port `22` rules since those are added by the new version of the module.

A terraform state move may be needed in case the security group resource has moved between 0.3.1 and 1.0.1 security group module versions.