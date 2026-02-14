using JFBostonAdminAPI.Configuration;

namespace JFBostonAdminAPI.Extensions;

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
            var context = provider.GetRequiredService<IHttpContextAccessor>().HttpContext;

            var options = new Supabase.SupabaseOptions
            {
                AutoConnectRealtime = true,
                AutoRefreshToken = false
            };

            var client = new Supabase.Client(settings.Url, settings.AnonKey, options);
            var authHeader = context?.Request.Headers["Authorization"].ToString();

            Console.WriteLine(authHeader);

            if (!string.IsNullOrEmpty(authHeader) && authHeader.StartsWith("Bearer "))
            {
                var token = authHeader.Replace("Bearer ", "").Trim();
                client.Auth.SetSession(token, "", false);

                client.Postgrest.Options.Headers["Authorization"] = $"Bearer {token}";
            }

            return client;
        });
    }
}