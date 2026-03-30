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

    [HttpPut("update/{id}")]
    public async Task<IActionResult> UpdatePerformance(int id, [FromBody] Performance performance)
    {
        try
        {
            // Ensure the ID in the URL matches the ID in the model (if your frontend sends it)
            // If your frontend doesn't send the ID in the body, map it here:
            performance.Id = id;

            bool isSuccess = await _scheduleService.UpdatePerformanceAsync(performance);

            if (isSuccess)
            {
                return Ok(new { message = "Performance updated successfully." });
            }
            else
            {
                return BadRequest(new { message = "Failed to update the performance." });
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Internal server error: {ex.Message}" });
        }
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