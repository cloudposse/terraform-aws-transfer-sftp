# Migration from 0.6.0 to 0.7.x+

Change the following

- `security_group_enabled` to `create_security_group`
- `security_group_use_name_prefix` to `security_group_create_before_destroy`
- `security_group_rules` to `additional_security_group_rules` and omit the port `22` rules since those are added by the new version of the module.
- `security_group_description` may need to be set to `The Security Group description.` which was the original description in version 0.6.0.
- `vpc_security_group_ids` to `associated_security_group_ids`

A terraform state move may be needed in case the security group resource has moved between versions.
