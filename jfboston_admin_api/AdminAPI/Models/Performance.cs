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

    [Column("start_time")]
    public DateTime StartTime { get; set; }

    [Column("stage_name")]

    public string StageName { get; set; } = null!;
}