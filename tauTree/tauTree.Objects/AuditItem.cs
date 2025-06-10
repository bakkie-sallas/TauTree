using tauTree.Interfaces;
using tauTree.Extensions;
namespace tauTree.Objects;

public class  AuditItem<TEnum>:IAuditItem<TEnum> where TEnum : struct, Enum
{
   
   public AuditItem(string name, AuditItemType type, ICollection<IPatternMatch<TEnum>> patterns)
   {
      Name = name;
      Type = type;
      Patterns = patterns;
   }
   private ICollection<IPatternMatch<TEnum>> Patterns;
   public string Name {get;set;}
   public IPatternMatch<TEnum> Pattern => Patterns.Resolve<TEnum>(Name);

   public string[] NameParts{get;set;}
   public AuditItemType Type {get;set;}
}
