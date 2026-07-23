using CloudArchitectureTraining.Application.Security;

namespace CloudArchitectureTraining.Api.Security;

public sealed class HttpContextCurrentUser(
    IHttpContextAccessor httpContextAccessor,
    IConfiguration configuration) : ICurrentUser
{
    public ApplicationPrincipal Principal
    {
        get
        {
            if (!configuration.GetValue("Authentication:Enabled", false))
            {
                return new("Local", "local-training-user", true);
            }

            var user = httpContextAccessor.HttpContext?.User;
            if (user?.Identity?.IsAuthenticated != true)
            {
                throw new InvalidOperationException("An authenticated application principal is required.");
            }

            var provider = configuration["Authentication:Provider"];
            if (string.IsNullOrWhiteSpace(provider))
            {
                throw new InvalidOperationException("Authentication:Provider is required.");
            }

            var normalizedProvider = provider.Equals("Entra", StringComparison.OrdinalIgnoreCase)
                ? "Entra"
                : provider.Equals("Cognito", StringComparison.OrdinalIgnoreCase)
                    ? "Cognito"
                    : throw new InvalidOperationException(
                        "Authentication:Provider must be Entra or Cognito.");

            var subject = normalizedProvider == "Entra"
                ? GetEntraSubject(user)
                : user.FindFirst("sub")?.Value;

            if (string.IsNullOrWhiteSpace(subject))
            {
                throw new InvalidOperationException("The access token does not contain an immutable subject.");
            }

            return new(normalizedProvider, subject, user.IsInRole(ApplicationRoles.Administrator));
        }
    }

    private static string? GetEntraSubject(System.Security.Claims.ClaimsPrincipal user)
    {
        var tenantId = user.FindFirst("tid")?.Value;
        var objectId = user.FindFirst("oid")?.Value;
        return string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(objectId)
            ? null
            : $"{tenantId}:{objectId}";
    }
}
