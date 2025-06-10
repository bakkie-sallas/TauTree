namespace tauTree.Interfaces;

public readonly struct PatternTypeStruct<TEnum> where TEnum : struct, Enum
{
    public TEnum Value { get; }

    public PatternTypeStruct(TEnum value) => Value = value;

    // convenience cast so the box behaves like the enum itself
    public static implicit operator TEnum(PatternTypeStruct<TEnum> box) => box.Value;
    public static implicit operator PatternTypeStruct<TEnum>(TEnum value) => new(value);

    public override string ToString() => Value.ToString();
}