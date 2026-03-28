using JFBostonAdminAPI.Extensions;
using JFBostonAdminAPI.Services;

var builder = WebApplication.CreateBuilder(args);

// Setup Infrastructure
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

// Add Supabase
builder.Services.AddSupabaseClient(builder.Configuration);

// Register your Application Services
builder.Services.AddScoped<IScheduleService, ScheduleService>();

// Add controllers
builder.Services.AddControllers();

var app = builder.Build();

app.UseCors();
app.MapControllers();
app.Run();