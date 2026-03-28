using System.Text.Json.Serialization;
using Postgrest.Attributes;
using Postgrest.Models;

namespace JFBostonAdminAPI.Models;

[Table("stage_events")]
public class Performance : BaseModel
{
    [PrimaryKey("id")]
    [JsonPropertyName("Id")]
    public int Id { get; set; }

    [Column("performance_name")] // Supabase column name
    [JsonPropertyName("Name")] // Property name from frontend
    public string Name { get; set; } = null!;

    [Column("time")]
    [JsonPropertyName("StartTime")]
    public TimeSpan StartTime { get; set; }

    [Column("stage")]
    [JsonPropertyName("StageName")]
    public string StageName { get; set; } = null!;

    [Column("duration")]
    [JsonPropertyName("Duration")]
    public int Duration { get; set; }

    [Column("description")]
    [JsonPropertyName("Description")]
    public string Description { get; set; } = null!;

    [Column("event_image")]
    [JsonPropertyName("EventImage")]
    public string EventImage { get; set; } = null!;

    [Column("icon_image")]
    [JsonPropertyName("IconImage")]
    public string IconImage { get; set; } = null!;

    [Column("day")]
    [JsonPropertyName("Day")]
    public int Day { get; set; }
}