using Postgrest.Attributes;
using Postgrest.Models;

namespace JFBostonAdminAPI.Models;

// Name of supabase table holding stage events
[Table("stage_events")]
public class Performance : BaseModel
{
    [PrimaryKey("id")]
    public int Id { get; set; }

    [Column("performance_name")]
    public string Name { get; set; } = null!;

    [Column("time")]
    public TimeSpan StartTime { get; set; }

    [Column("stage")]

    public string StageName { get; set; } = null!;

    [Column("duration")]

    public int Duration { get; set; }

    [Column("description")]

    public string Description { get; set; } = null!;

    [Column("event_image")]

    public string EventImage { get; set; } = null!;

    [Column("icon_image")]

    public string IconImage { get; set; } = null!;

    [Column("day")]

    public string Day { get; set; } = null!;
}