using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using SCH1.Interfaces;
using tauTree.Interfaces;

namespace SCH1.Objects
{

    /// <summary>
    /// Attempts to recognise common naming conventions and expose the tokens as key/value pairs.
    /// Extend <see cref="Patterns"/> with additional Regex patterns to cover more cases.
    /// </summary>
    public class PatternMatch_V1<TEnum> : IPatternMatch<TEnum> where TEnum : struct, Enum
    {
    public  PatternTypeStruct<TEnum>  PatternTypeStruct { get; set; }
    
    public Dictionary<string, string> Descriptors { get; set; } = new();

    // ---------------------------------------------------------------------
    // Known regex patterns for each naming convention we want to support.
    // Add or adjust patterns to increase coverage.
    // ---------------------------------------------------------------------
    private static readonly List<PatternDefinition> Patterns = new()
    {
        // <service>-<environment>-Deploy-<version>
        new PatternDefinition(
            PatternType.deploy_service_environment_Deploy_version,
            new Regex(
                @"^(?<service>[A-Za-z0-9]+)-(?<environment>[A-Za-z0-9]+)-Deploy-(?<version>v?\d+(?:[._]\d+)*(?:[-+A-Za-z0-9._]*)?)$",
                RegexOptions.IgnoreCase)),

        // Deploy_<service>_<environment>_<version>
        new PatternDefinition(
            PatternType.deploy_Deploy_service_environment_version,
            new Regex(
                @"^Deploy_(?<service>[A-Za-z0-9]+)_(?<environment>[A-Za-z0-9]+)_(?<version>v?\d+(?:[._]\d+)*(?:[-+A-Za-z0-9._]*)?)$",
                RegexOptions.IgnoreCase)),

        // <service>_CI_<branch>_<buildNumber>
        new PatternDefinition(
            PatternType.build_service_CI_branch_buildnumber,
            new Regex(@"^(?<service>[A-Za-z0-9]+)_CI_(?<branch>[A-Za-z0-9\-]+)_(?<buildnumber>\d+)$",
                RegexOptions.IgnoreCase)),

        // <name> v<major>.<minor>.<patch>[...]
        new PatternDefinition(
            PatternType.release_versioned,
            new Regex(@"^(?<name>[A-Za-z0-9]+)[-_ ]v(?<version>\d+\.\d+\.\d+(?:[-+A-Za-z0-9._]*)?)$",
                RegexOptions.IgnoreCase)),

        // <name>-YYYY-MM-DD or <name>_YYYY.MM.DD
        new PatternDefinition(
            PatternType.release_date,
            new Regex(@"^(?<name>[A-Za-z0-9]+)[-_ ](?<year>\d{4})[-._]?(?<month>\d{2})[-._]?(?<day>\d{2})$",
                RegexOptions.IgnoreCase)),

        // <name> YYYY
        new PatternDefinition(
            PatternType.release_yearly,
            new Regex(@"^(?<name>[A-Za-z0-9]+)[-_ ]?(?<year>\d{4})$", RegexOptions.IgnoreCase))
    };

    /// <summary>
    /// Parse the supplied name, automatically selecting the first matching pattern.
    /// After construction, check <see cref="PatternType"/> to see what matched and
    /// <see cref="Descriptors"/> for the captured tokens.
    /// </summary>
    /// <param name="name">The build / release / deployment name to interrogate.</param>
    public bool TryResolve(string name)
    {
        foreach (var pattern in Patterns)
        {
            var match = pattern.Regex.Match(name);
            if (!match.Success) continue;

            PatternTypeStruct = new PatternTypeStruct<PatternType>(pattern);

            var descriptors = new List<(string key, string value)>();
            foreach (var groupName in pattern.Regex.GetGroupNames())
            {
                if (int.TryParse(groupName, out _)) continue; // skip numeric groups
                Descriptors.Add(groupName, match.Groups[groupName].Value);
            }

            return true;
        }

        PatternTypeStruct = default;
        return false;
    }

    // Internal helper record
    private record PatternDefinition(PatternType PatternType, Regex Regex);
    }


}
