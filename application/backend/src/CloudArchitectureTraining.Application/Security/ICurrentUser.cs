namespace CloudArchitectureTraining.Application.Security;

public sealed record ApplicationPrincipal(
    string Provider,
    string Subject,
    bool IsAdministrator);

public interface ICurrentUser
{
    ApplicationPrincipal Principal { get; }
}
