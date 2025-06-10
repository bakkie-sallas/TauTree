namespace tauTree.Interfaces;

public interface IAuditItem<TEnum> where TEnum : struct, Enum
{
    string Name {get;set;}
    IPatternMatch<TEnum> Pattern {get;}    

    string[] NameParts{get;set;}
    AuditItemType Type {get;set;}
}
