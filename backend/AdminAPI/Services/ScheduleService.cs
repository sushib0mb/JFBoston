using JFBostonAdminAPI.Models;   // This fixes the 'Performance' error
using Supabase;
using Postgrest;

namespace JFBostonAdminAPI.Services;

public class ScheduleService : IScheduleService
{
    private readonly Supabase.Client _client;
    public ScheduleService(Supabase.Client client) => _client = client;

    public async Task<IEnumerable<object>> GetScheduleAsync(string? stageName)
    {
        var query = _client.From<Performance>();
        var result = !string.IsNullOrEmpty(stageName)
            ? await query.Where(x => x.StageName == stageName).Get()
            : await query.Get();

        return result.Models.Select(p => new { p.Id, p.Name, p.StartTime, p.StageName })
                            .OrderBy(p => p.StartTime);
    }

    public async Task<bool> AddPerformanceAsync(Performance performance)
    {
        try
        {
            // Insert the performance
            var response = await _client.From<Performance>().Insert(performance);

            if (response.Models.Count == 0)
            {
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"CRITICAL ERROR: {ex.Message}");
            return false;
        }
    }

    public async Task<string> DelayPerformanceAsync(int id, int minutes)
    {
        try
        {
            var result = await _client.From<Performance>().Where(x => x.Id == id).Single();
            if (result == null) return null;

            var oldTime = result.StartTime;
            result.StartTime = result.StartTime.Add(TimeSpan.FromMinutes(minutes));

            await result.Update<Performance>();

            return $"Performance {id} updated from {oldTime} to {result.StartTime}";
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
            return "Error handling response";
        }
    }

    public async Task<string> ShuffleScheduleAsync(int id, int minutes)
    {
        try
        {
            var result = await _client.From<Performance>().Where(x => x.Id == id).Single();
            if (result == null) return null;

            // Simple comparison works for TimeSpan
            var thresholdTime = result.StartTime;

            var futurePerformances = await _client.From<Performance>()
                .Where(x => x.StartTime >= thresholdTime)
                .Where(x => x.StageName == result.StageName)
                .Get();

            var listToUpdate = futurePerformances.Models;

            foreach (var p in listToUpdate)
            {
                p.StartTime = p.StartTime.Add(TimeSpan.FromMinutes(minutes));
            }

            await _client.From<Performance>().Upsert(listToUpdate);

            return $"Shifted {listToUpdate.Count} performances";
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
            return "Error handling response";
        }
    }
}