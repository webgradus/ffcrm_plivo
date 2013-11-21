ffcrm_plivo
===========

Integration of FatFreeCRM with Plivo voice calls

# Usage

Specify "plivo_endpoint_username" and "plivo_endpoint_password" settings in config/settings.yml of your FatFreeCRM instance.

Also specify "plivo_auth_id" and "plivo_auth_token" settings in config/settings.yml of your FatFreeCRM instance for sending SMS messages.

That's all. On each Contact page (i.e., "/contacts/:id") you will have "Call" button in left block (fields "Phone" and "Mobile").
