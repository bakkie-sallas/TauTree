using SCH1.Interfaces;
using SCH1.Objects;

namespace SCH1.Tests;

public class UnitTest1
{
    [Fact]
    public void Given_ThreeSortedLists_Should_LoadAndMatch()
    {
        var releases = new List<AuditItem>().AddRange(
            LoadedTestValues.ReleaseNames.ForEach(
                x=>new AuditItem(x.)
    }
}