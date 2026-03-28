using JFBostonAdminAPI.Models;

namespace JFBostonAdminAPI.Services;

public class ScheduleService : IScheduleService
{
    private readonly Supabase.Client _client;
    public ScheduleService(Supabase.Client client) => _client = client;

    // Fetches all performances or performances at a specific stage
    public async Task<IEnumerable<object>> GetScheduleAsync(string? stageName)
    {
        var query = _client.From<Performance>();
        var result = !string.IsNullOrEmpty(stageName)
            ? await query.Where(x => x.StageName == stageName).Get()
            : await query.Get();

        return result.Models.Select(p => new { p.Id, p.Name, p.StartTime, p.StageName })
                            .OrderBy(p => p.StartTime);
    }

    // Posts a new performance
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

    // Delays a single performance using id by min minutes
    public async Task<string> DelayPerformanceAsync(int id, int min)
    {
        try
        {
            // Fetches selected performance
            var result = await _client.From<Performance>().Where(x => x.Id == id).Single();
            if (result == null) return "nullError";

            // Adds $minutes to the fetched time and updates the object
            var oldTime = result.StartTime;
            result.StartTime = result.StartTime.Add(TimeSpan.FromMinutes(min));

            // Posts the new event object to database
            await result.Update<Performance>();

            return $"Performance {id} updated from {oldTime} to {result.StartTime}";
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
            return "postError";
        }
    }

    // Delays all performances at the same stage as the selected performance by minutes
    public async Task<string> ShuffleScheduleAsync(int id, int min)
    {
        try
        {
            // Fetches selected performance using id
            var result = await _client.From<Performance>().Where(x => x.Id == id).Single();
            if (result == null) return "nullError";

            // Sets the time from which to start delaying
            var thresholdTime = result.StartTime;

            // Fetches all performances at the same stage as the selected performance which start later than the selected performance
            var futurePerformances = await _client.From<Performance>()
                .Where(x => x.StartTime >= thresholdTime)
                .Where(x => x.StageName == result.StageName)
                .Get();

            var listToUpdate = futurePerformances.Models;

            // Add min minutes to all of the performances that need adjusting
            foreach (var p in listToUpdate)
            {
                p.StartTime = p.StartTime.Add(TimeSpan.FromMinutes(min));
            }

            // Updates the database using the new list
            await _client.From<Performance>().Upsert(listToUpdate);

            return $"Shifted {listToUpdate.Count} performances";
        }
        catch (Exception e)
        {
            Console.WriteLine(e.Message);
            return "postError";
        }
    }
}