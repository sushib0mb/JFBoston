using JFBostonAdminAPI.Extensions; // Import your extension
using JFBostonAdminAPI.Services; // Import your extension

var builder = WebApplication.CreateBuilder(args);

// 1. Setup Infrastructure
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// 2. Add Supabase (Calling your custom extension method)
builder.Services.AddSupabaseClient(builder.Configuration);

// 3. Register your Application Services
builder.Services.AddScoped<IScheduleService, ScheduleService>();

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors();
app.MapControllers();
app.Run();