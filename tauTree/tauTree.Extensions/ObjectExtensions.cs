using System;
using System.Collections.Generic;
using tauTree.Interfaces;

namespace tauTree.Extensions
{
    public static class ObjectExtensions
    {
        public static IPatternMatch<TEnum> Resolve<TEnum>(this ICollection<IPatternMatch<TEnum>>  patterns , string name)  where TEnum : struct, Enum     
        {
            foreach (var pattern in patterns)
            {
                if (pattern.TryResolve(name))
                    return pattern;
            }
            throw new Exception($"Searched {patterns.Count} patterns. No Possible matches found");
        }
    }
}