# Production activation checklist

1. Create the university-owned Supabase project in an EU region.
2. Run `supabase/schema.sql` in SQL Editor and run Database Security Advisor.
3. Register a single-tenant application in Microsoft Entra ID.
4. Add `https://<project-ref>.supabase.co/auth/v1/callback` as the Web redirect URI.
5. Enable Azure provider in Supabase Auth using Entra Client ID and secret.
6. Restrict sign-in to the Doğuş tenant and validate `@dogus.edu.tr` server-side.
7. Copy `config.example.js` to `config.js`; use only the publishable key in the browser.
8. Deploy QR verification and reward claim endpoints in a trusted server runtime.
9. Configure custom SMTP, rate limiting, CAPTCHA, log retention and backups.
10. Complete KVKK approval, data inventory, retention periods and incident procedure.

Never place an Entra client secret, database password, Supabase secret key or service-role key in GitHub Pages.
