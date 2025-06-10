namespace tauTree.Interfaces;

public interface IMatchResult<TEnum>:IAuditItem<TEnum> where TEnum : struct, Enum
{
    IAuditItem<TEnum> Item1{get;set;}
    IAuditItem<TEnum> Item2{get;set;}
    float  Result {get;set;}
}
