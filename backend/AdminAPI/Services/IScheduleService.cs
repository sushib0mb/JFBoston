using JFBostonAdminAPI.Models; // Tells the interface what a "Performance" is
using System.Collections.Generic; // For IEnumerable
using System.Threading.Tasks; // For Task

namespace JFBostonAdminAPI.Services; // Tells the rest of the app where this interface lives

public interface IScheduleService
{
    Task<IEnumerable<object>> GetScheduleAsync(string? stageName);
    Task<bool> AddPerformanceAsync(Performance performance);
    Task<string> DelayPerformanceAsync(int id, int minutes);
    Task<string> ShuffleScheduleAsync(int id, int minutes);
}