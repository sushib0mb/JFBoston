using Microsoft.AspNetCore.Mvc;
using JFBostonAdminAPI.Services;
using JFBostonAdminAPI.Models;

// Controller for modifying schedules
[ApiController]
[Route("api/[controller]")]
public class ScheduleController : ControllerBase
{
    private readonly IScheduleService _scheduleService;

    public ScheduleController(IScheduleService scheduleService)
    {
        _scheduleService = scheduleService;
    }

    // Call service to fetch the current schedule
    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] string? stageName)
    {
        var data = await _scheduleService.GetScheduleAsync(stageName);
        return Ok(data);
    }

    // Start service to post a new performance
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

    // Start service to delay a single performance
    [HttpPost("delay/{id}")]
    public async Task<IActionResult> Delay(int id, [FromQuery] int minutes)
    {
        var message = await _scheduleService.DelayPerformanceAsync(id, minutes);

        if (message == "nullError")
        {
            return NotFound($"No performance found with ID {id}");
        }

        if (message == "postError")
        {
            return Problem(message);
        }

        return Ok(message);
    }

    // Start service to delay all performances in the same stage starting from the specified performance
    [HttpPost("shuffle/{id}")]
    public async Task<IActionResult> Shuffle(int id, [FromQuery] int minutes)
    {
        var message = await _scheduleService.ShuffleScheduleAsync(id, minutes);

        if (message == "nullError")
        {
            return NotFound($"No performance found with ID {id}");
        }

        if (message == "postError")
        {
            return Problem(message);
        }

        return Ok(message);
    }
}