namespace SCH1.Interfaces;

// -------------------------------------------------------------------------
// Pattern enumeration describing the supported naming conventions.
// -------------------------------------------------------------------------
public enum PatternType
{
    unknown,    
    deploy_service_environment_Deploy_version,  // <service>-<environment>-Deploy-<version>
    build_service_CI_branch_buildnumber,        // <service>_CI_<branch>_<buildNumber>
    release_date,                               // <name>-YYYY-MM-DD or similar
    release_yearly,                             // <name> YYYY
    release_versioned,                          // <name> v<major>.<minor>.<patch>
    deploy_Deploy_service_environment_version   // Deploy_<service>_<environment>_<version>
}