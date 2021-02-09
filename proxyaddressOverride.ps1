
function create-proxyaddressOverwrite($precedence){
    New-ADSyncRule  `
    -Name 'In from AD - User proxyaddress - Teams override' `
    -Identifier '99d39707-0f7d-4876-b1ca-13fdf0688322' `
    -Description ' AD - ProxyAddress  override for teams' `
    -Direction 'Inbound' `
    -Precedence $precedence `
    -PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
    -PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
    -SourceObjectType 'user' `
    -TargetObjectType 'person' `
    -Connector 'a99122f7-7679-4ba9-bc86-9f6b70c0b93e' `
    -LinkType 'Join' `
    -SoftDeleteExpiryInterval 0 `
    -ImmutableTag '' `
    -OutVariable syncRule


    Add-ADSyncAttributeFlowMapping  `
    -SynchronizationRule $syncRule[0] `
    -Destination 'proxyAddresses' `
    -FlowType 'Expression' `
    -ValueMergeType 'Update' `
    -Expression 'IIF(InStr(RemoveDuplicates(UCase(Trim(ImportedValue("proxyAddresses")))),"SIP:")=1,NULL,RemoveDuplicates(Trim(ImportedValue("proxyAddresses"))))' `
    -OutVariable syncRule

    New-Object  `
    -TypeName 'Microsoft.IdentityManagement.PowerShell.ObjectModel.ScopeCondition' `
    -ArgumentList 'adminDescription','User_','NOTSTARTSWITH' `
    -OutVariable condition0


    Add-ADSyncScopeConditionGroup  `
    -SynchronizationRule $syncRule[0] `
    -ScopeConditions @($condition0[0]) `
    -OutVariable syncRule


    Add-ADSyncRule  `
    -SynchronizationRule $syncRule[0]


    Get-ADSyncRule  `
    -Identifier '99d39707-0f7d-4876-b1ca-13fdf0688322'
}
function create-LyncOverwrite($precedence){
New-ADSyncRule  `
-Name 'In from AD - User Lync - Teams override' `
-Identifier '43523483-fd42-456e-98aa-1e12e94ce4dd' `
-Description 'Lync attribute for a User object. Flow none values to AAD, zero optionflags and make sip on UPN' `
-Direction 'Inbound' `
-Precedence $precedence `
-PrecedenceAfter '00000000-0000-0000-0000-000000000000' `
-PrecedenceBefore '00000000-0000-0000-0000-000000000000' `
-SourceObjectType 'user' `
-TargetObjectType 'person' `
-Connector 'a99122f7-7679-4ba9-bc86-9f6b70c0b93e' `
-LinkType 'Join' `
-SoftDeleteExpiryInterval 0 `
-ImmutableTag '' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-ApplicationOptions' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-DeploymentLocator' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-Line' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-OriginatorSid' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-OwnerUrn' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-PrimaryUserAddress' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'IIF(IsPresent([msRTCSIP-PrimaryUserAddress]),IIF(IsPresent([userPrincipalName]),"sip:" & ImportedValue("userPrincipalName"),NULL),NULL)' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-UserEnabled' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'AuthoritativeNull' `
-OutVariable syncRule


Add-ADSyncAttributeFlowMapping  `
-SynchronizationRule $syncRule[0] `
-Destination 'msRTCSIP-OptionFlags' `
-FlowType 'Expression' `
-ValueMergeType 'Update' `
-Expression 'IIF(IsPresent([msRTCSIP-OptionFlags]),0,NULL)' `
-OutVariable syncRule


Add-ADSyncRule  `
-SynchronizationRule $syncRule[0]


Get-ADSyncRule  `
-Identifier '43523483-fd42-456e-98aa-1e12e94ce4dd'



}
function execute-aadlyncchange($proxyprecedence,$lyncprecedence)
{

    write-host -ForegroundColor Yellow ("Using {0} {1}" -f $proxyPrecedence,$lyncprecedence)
    $proxy=create-proxyaddressOverwrite $proxyPrecedence
    $lyncRule=(get-adsyncrule | where name -like "In from AD - User Lync")
    $lync=create-LyncOverwrite $lyncprecedence
   
    if ($proxy -ne $null -and $lync -ne $null){
    Write-Host -ForegroundColor Green "Succesfully created rules. starting fullsync"
    Start-ADSyncSyncCycle -PolicyType Initial
    }else{
    $proxy
    $lync
    Write-Host -ForegroundColor red "Something went wrong"}
}

#calulateprecedence
$precedencevalues=Get-ADSyncRule | where precedence -lt 100 |select -ExpandProperty precedence | measure-object -Maximum -Minimum
if ($precedencevalues.Minimum -eq $null)
{
    #no overrides
    $proxyPrecedence=10
    $lyncPrecedence=11
    write-host -ForegroundColor Yellow "Not detected any overrides"
    execute-aadlyncchange  $proxyPrecedence $lyncPrecedence
    } else {
    #let's find 2 precedence numbers
    $precArray=Get-ADSyncRule | where precedence -lt 100 |select -ExpandProperty precedence
    $proxyPrecedence=$null
    for ($i = 1; $i -lt 99; $i++)
        { 
            if ($i -notin $precArray ){$proxyPrecedence=$i;break}
        }
    "pf"
    #proxy found
    if ($proxyPrecedence -ne $null)
    {
        $lyncprecedence=$null
        for ($i = 1; $i -lt 99; $i++)
        { 
            if ($i -notin $precArray -and $i -ne $proxyPrecedence ){$lyncprecedence=$i;break}
        }
        if ($lyncprecedence -ne $null){
             write-host -ForegroundColor Yellow ("Following 2 precedences found {0} {1}" -f $proxyPrecedence,$lyncprecedence)
             execute-aadlyncchange  $proxyPrecedence $lyncPrecedence
        }else {Write-Host -ForegroundColor red "Only one precedence spot available"}
    }else {Write-Host -ForegroundColor red "No Valid precednece found"}
}