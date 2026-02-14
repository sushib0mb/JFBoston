using Microsoft.AspNetCore.Mvc;
using JFBostonAdminAPI.Services; // Also add this to find your interface
using JFBostonAdminAPI.Models;   // Also add this to find Performance

[ApiController]
[Route("api/[controller]")]
public class ScheduleController : ControllerBase
{
    private readonly IScheduleService _scheduleService;

    public ScheduleController(IScheduleService scheduleService)
    {
        _scheduleService = scheduleService;
    }

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string? stageName)
    {
        var data = await _scheduleService.GetScheduleAsync(stageName);
        return Ok(data);
    }

    [HttpPost("add")]
    public async Task<IActionResult> Add([FromBody] Performance performance)
    {
        var success = await _scheduleService.AddPerformanceAsync(performance);

        if (!success)
        {
            return BadRequest("Could not add performance. Check RLS policies.");
        }

        return Ok("Performance added successfully");
    }

    [HttpPost("delay/{id}")]
    public async Task<IActionResult> Delay(int id, [FromQuery] int minutes)
    {
        var message = await _scheduleService.DelayPerformanceAsync(id, minutes);

        if (message == null)
        {
            return NotFound($"No performance found with ID {id}");
        }

        if (message == "Error updating performance")
        {
            return Problem(message);
        }

        return Ok(message);
    }

    [HttpPost("shuffle/{id}")]
    public async Task<IActionResult> Shuffle(int id, [FromQuery] int minutes)
    {
        var message = await _scheduleService.ShuffleScheduleAsync(id, minutes);

        if (message == null)
        {
            return NotFound($"No performance found with ID {id}");
        }

        if (message == "Error updating performance")
        {
            return Problem(message);
        }

        return Ok(message);
    }
}