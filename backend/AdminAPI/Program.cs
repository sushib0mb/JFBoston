using System.Reflection.Metadata.Ecma335;
using JFBostonAdminAPI.Models;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using Supabase;
using JFBostonAdminAPI.Configuration;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Setup supabase as a service
var supabaseSettings = builder.Configuration
    .GetSection(SupabaseSettings.SectionName)
    .Get<SupabaseSettings>();

// 2. Guard against missing config immediately
if (supabaseSettings == null || string.IsNullOrEmpty(supabaseSettings.Url))
{
    throw new Exception("Supabase configuration is missing!");
}

var options = new Supabase.SupabaseOptions { AutoConnectRealtime = true };

builder.Services.AddSingleton(provider =>
    new Supabase.Client(supabaseSettings.Url, supabaseSettings.AnonKey, options));

var app = builder.Build();

app.UseCors();

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
        var response = await client.From<Performance>().Insert(newPerformance);

        var created = response.Models[0];
        Console.WriteLine($"Status Code: {response.ResponseMessage.StatusCode}");
        Console.WriteLine($"Content: {response.Content}");

        return Results.Ok(new
        {
            id = created.Id,
            name = created.Name,
            stageName = created.StageName,
            startTime = created.StartTime.ToString(@"hh\:mm\:ss") // Format for JSON
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
        var result = await client.From<Performance>().Where(x => x.Id == id).Single();
        if (result == null) return Results.NotFound($"No performance found with ID {id}");

        // Use .Add(TimeSpan) instead of .AddMinutes()
        var oldTime = result.StartTime;
        result.StartTime = result.StartTime.Add(TimeSpan.FromMinutes(minutes));

        await result.Update<Performance>();

        return Results.Ok($"Performance {id} updated from {oldTime} to {result.StartTime}");
    }
    catch (Exception e)
    {
        return Results.Problem(e.Message);
    }
});

app.MapPost("/api/schedule/shuffle/{id}", async (int id, int minutes, Supabase.Client client) =>
{
    try
    {
        var result = await client.From<Performance>().Where(x => x.Id == id).Single();
        if (result == null) return Results.NotFound($"No performance found with ID {id}");

        // Simple comparison works for TimeSpan
        var thresholdTime = result.StartTime;

        var futurePerformances = await client.From<Performance>()
            .Where(x => x.StartTime >= thresholdTime)
            .Where(x => x.StageName == result.StageName)
            .Get();

        var listToUpdate = futurePerformances.Models;

        foreach (var p in listToUpdate)
        {
            p.StartTime = p.StartTime.Add(TimeSpan.FromMinutes(minutes));
        }

        await client.From<Performance>().Upsert(listToUpdate);

        return Results.Ok($"Shifted {listToUpdate.Count} performances");
    }
    catch (Exception e)
    {
        return Results.Problem(e.Message);
    }
});

app.Run();
