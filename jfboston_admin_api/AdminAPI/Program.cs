using System.Reflection.Metadata.Ecma335;
using JFBostonAdminAPI.Models;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using Supabase;

var builder = WebApplication.CreateBuilder(args);

// Setup supabase as a service
var url = builder.Configuration["SUPABASE_URL"];
var key = builder.Configuration["SUPABASE_ANON_KEY"];
var options = new Supabase.SupabaseOptions { AutoConnectRealtime = true };

builder.Services.AddSingleton(provider => new Supabase.Client(url, key, options));

var app = builder.Build();

// By default fetches all peformances across all stages, or fetches all performances belonging to a stage based on the stagename param
app.MapGet("/api/schedule", async (Supabase.Client client, string? stagename = null) =>
{
    var query = client.From<Performance>();

    var result = !string.IsNullOrEmpty(stagename)
    ? await query.Where(x => x.StageName == stagename).Get()
    : await query.Get();

    // This "Select" maps your complex model to a simple list of values
    var cleanData = result.Models.Select(p => new
    {
        p.Id,
        p.Name,
        p.StartTime,
        p.StageName
    }).OrderBy(p => p.StartTime);

    return Results.Ok(cleanData);
});

// Adds a new performance to the database
app.MapPost("/api/schedule/add", async (Performance newPerformance, Supabase.Client client) =>
{
    try
    {
        // Specifies the datetime's timezone to ensure Supabase doesn't get confused
        newPerformance.StartTime = DateTime.SpecifyKind(newPerformance.StartTime, DateTimeKind.Utc);
        var response = await client.From<Performance>().Insert(newPerformance);

        var created = response.Models[0];

        // Map to object to avoid serialization error
        return Results.Ok(new
        {
            id = created.Id,
            name = created.Name,
            stageName = created.StageName,
            startTime = created.StartTime
        });
    }
    catch (Exception e)
    {
        Console.WriteLine($"Error: {e.Message}");
        return Results.Problem("Failed to add performance.");
    }
});

app.MapPost("/api/schedule/delay/{id}", async (int id, int minutes, Supabase.Client client) =>
{
    try
    {
        // Fetches the performance according to id
        var result = await client.From<Performance>().Where(x => x.Id == id).Single();

        // Delays the startTime variable by the inputted minutes if the id exists
        if (result == null)
        {
            return Results.NotFound($"No performance found with ID {id}");
        }

        result.StartTime = result.StartTime.AddMinutes(minutes);
        await result.Update<Performance>();

        return Results.Ok($"Performance {id} updated from {result.StartTime.AddMinutes(-minutes)} to {result.StartTime}");
    }
    catch (Exception e)
    {
        return Results.Problem(e.Message);
    }
});

// Delays all performance by x minutes starting from the performance
app.MapPost("/api/schedule/shuffle/{id}", async (int id, int minutes, Supabase.Client client) =>
{
    try
    {
        // Fetch the performance with the id that starts the delay
        var result = await client.From<Performance>().Where(x => x.Id == id).Single();
        if (result == null) return Results.NotFound($"No performance found with ID {id}");

        // Convert to UTC, which is the timezone supabase uses for comparisons
        var safeStartTime = result.StartTime.ToUniversalTime().AddSeconds(-1);

        // Fetches all performances starting after or at the same time as the selected performance
        var futurePerformances = await client.From<Performance>()
        .Where(x => x.StartTime >= safeStartTime)
        .Where(x => x.StageName == result.StageName)
        .Get();

        var listToUpdate = futurePerformances.Models;

        foreach (var p in listToUpdate)
        {
            p.StartTime = p.StartTime.AddMinutes(minutes);
        }

        await client.From<Performance>().Upsert(listToUpdate);

        return Results.Ok($"Shifted {listToUpdate.Count} {(listToUpdate.Count > 1 ? "performances" : "performance")} by {minutes} minutes");
    }
    catch (Exception e)
    {
        return Results.Problem(e.Message);
    }
});

app.Run();
