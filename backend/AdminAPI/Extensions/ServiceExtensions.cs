using JFBostonAdminAPI.Configuration;

namespace JFBostonAdminAPI.Extensions;

// Manages all intial configurations when connecting to services(Supabase)
public static class ServiceExtensions
{
    public static void AddSupabaseClient(this IServiceCollection services, IConfiguration configuration)
    {
        var settings = configuration.GetSection(SupabaseSettings.SectionName).Get<SupabaseSettings>();

        if (settings == null || string.IsNullOrEmpty(settings.Url))
            throw new Exception("Supabase configuration is missing!");

        services.AddHttpContextAccessor();

        services.AddScoped(provider =>
        {
            // Access http request information
            var context = provider.GetRequiredService<IHttpContextAccessor>().HttpContext;

            var options = new Supabase.SupabaseOptions
            {
                AutoConnectRealtime = true,
                AutoRefreshToken = false
            };

            var client = new Supabase.Client(settings.Url, settings.AnonKey, options);

            // Assign bearer token
            var authHeader = context?.Request.Headers["Authorization"].ToString();

            // Check that the bearer token is valid and 
            if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer "))
            {
                var token = authHeader.Replace("Bearer ", "").Trim();
                // Sets session with auth module
                client.Auth.SetSession(token, "", false);

                // Sets bearer token into header for database auth
                client.Postgrest.Options.Headers["Authorization"] = $"Bearer {token}";
            }

            return client;
        });
    }
}