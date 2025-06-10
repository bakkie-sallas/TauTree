namespace tauTree.Interfaces;

public interface IPatternMatch<TEnum> where TEnum : struct, Enum
{
   PatternTypeStruct<TEnum> PatternTypeStruct { get; set; }
   Dictionary<string,string> Descriptors { get; set; }
   bool TryResolve(string name);
}
