using JFBostonAdminAPI.Models;

namespace JFBostonAdminAPI.Services;

// Sets interface for schedule service
public interface IScheduleService
{
    Task<IEnumerable<object>> GetScheduleAsync(string? stageName);
    Task<bool> UpdatePerformanceAsync(Performance performance);
    Task<bool> AddPerformanceAsync(Performance performance);
    Task<List<string>> DelayPerformancesAsync(int[] ids, int min);
    Task<string> ShuffleScheduleAsync(int id, int minutes);
}