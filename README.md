# AADRemoveSkypeParams

When Organization have on-premis skype for bussiness and cloud teams, and both of them are using distinct domains, we may be tempted to switch to Teams-Only mode.

This will allow for federation to work on teams, while still allowing federation to work on s4b.

##Script logic
* Verifies if any customization are done on aadconnect, and calulates lowes precedence to insert new customizations
* Insert proxyaddresses customization that removes sip: type addresses from flow
* Overrides lync parameters, and construct new sip address based on upn


##Prereq
* Verify if federation settings are properly configured in DNS for Teams
* Run following script on aadconnect
* Either remove or _disable-csonlinesipdomain_ for S4B domain

