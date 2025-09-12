# Decision Log

## Event Attribution Methods

This dbt Klaviyo package supports two attribution approaches: direct event attribution and a session-based fallback. This log explains the rationale, usage, and configuration for each method.

### Primary Attribution Method — Native attribution

If available the package uses Klaviyo’s native `property_attribution` field (renamed to `event_attribution` during staging) from the EVENT source. This is the preferred method.

Why we prefer this option:
- **Accuracy**: Reflects Klaviyo’s platform logic
- **Consistency**: Matches reporting in the Klaviyo UI
- **Efficiency**: Faster than session-based calculations
- **Maintainability**: Avoids custom logic that could diverge from Klaviyo

#### Implementation
- Events with `property_attribution` are used directly
- Events without it inherit from parent events via `attributed_event_id`

### Session-Based Attribution Fallback

A session-based method can be enabled when `using_native_attribution: true` in `dbt_project.yml`, or if the package detects that `property_attribution` is unavailable.

Why we provide this option: 
- **Backward Compatibility**: Preserve compatibility with earlier package versions
- **Data Gaps**: Fill in when `property_attribution` is missing
- **Custom Needs**: Support attribution use cases not covered by Klaviyo 

Why we limit its use:
- **Performance Impact**: Requires window functions and complex logic
- **Potential Inconsistency**: Results may differ from Klaviyo’s native attribution
- **Not Needed**: Unnecessary when reliable `property_attribution` data exists

#### Implementation
When enabled, the session-based method:
- Groups events into "touch sessions" based on attributed campaign/flow events
- Applies configurable lookback windows (120 hours for email, 24 hours for SMS)
- Attributes only events within the lookback window to the session-starting event
- Filters attribution by `klaviyo__eligible_attribution_events` (defaults: email opens, clicks, SMS opens)

### Configuration Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `using_native_attribution` | `true` | Enable native or session based attribution |
| `klaviyo__email_attribution_lookback` | `120` | Lookback window (hours) for email attribution |
| `klaviyo__sms_attribution_lookback` | `24` | Lookback window (hours) for SMS attribution |
| `klaviyo__eligible_attribution_events` | `['email open', 'email click', 'sms open']` | Event types eligible for attribution |

### Recommendations

#### Use Direct Attribution (Default) When:
- Consistency with Klaviyo’s platform is required
- `property_attribution` data is present and reliable
- Performance and simplicity are priorities
- Starting a new implementation

#### Use Session-Based Fallback When:
- Migrating from an older package version
- Experiencing significant attribution data gaps
- Needing custom business-specific attribution logic
- Comparing attribution methods for validation

### Migration Notes
- **v1.0.0 → v1.1.0**: Preferred method changed from session-based to direct attribution
- **Enabling Fallback**: Set `using_native_attribution: true` in `dbt_project.yml` to restore prior behavior
- **Data Consistency**: Expect potential differences between methods; test thoroughly before production rollout

### References
- [Klaviyo Attribution Documentation](https://help.klaviyo.com/hc/en-us/articles/115005248128)