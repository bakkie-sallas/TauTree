namespace tauTree.Interfaces;

public interface IRelease<TEnum>:IAuditItem<TEnum> where TEnum : struct, Enum
{
}
