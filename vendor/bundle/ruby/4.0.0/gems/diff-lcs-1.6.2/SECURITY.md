# diff-lcs Security

## Supported Versions

Security reports are accepted for the most recent major release and the previous
version for a limited time after the initial major release version. After a
major release, the previous version will receive full support for six months and
security support for an additional six months (for a total of twelve months).

Because diff-lcs 1.x supports a wide range of Ruby versions, security reports
will only be accepted when they can be demonstrated on Ruby 3.1 or higher.

> [!information]
>
> There will be a diff-lcs 2.0 released in 2025 which narrows support to modern
> versions of Ruby only.
>
> | Release Date | Support Ends | Security Support Ends |
> | ------------ | ------------ | --------------------- |
> | 2025         | +6 months    | +12 months            |
>
> If the 2.0.0 release happens on 2025-07-01, regular support for diff-lcs 1.x
> will end on 2026-12-31 and security support for diff-lcs 1.x will end on
> 2026-06-30.

## Reporting a Vulnerability

By preference, use the [Tidelift security contact][tidelift]. Tidelift will
coordinate the fix and disclosure.

Alternatively, Send an email to [diff-lcs@halostatue.ca][email] with the text
`Diff::LCS` in the subject. Emails sent to this address should be encrypted
using [age][age] with the following public key:

```
age1fc6ngxmn02m62fej5cl30lrvwmxn4k3q2atqu53aatekmnqfwumqj4g93w
```

[tidelift]: https://tidelift.com/security
[email]: mailto:diff-lcs@halostatue.ca
[age]: https://github.com/FiloSottile/age
