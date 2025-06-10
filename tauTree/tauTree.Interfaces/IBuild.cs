namespace tauTree.Interfaces;

public interface IBuild<TEnum>:IAuditItem<TEnum> where TEnum : struct, Enum
{

}
