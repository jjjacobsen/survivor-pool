# Backend Notes

- Email verification uses Resend. Set `RESEND_API_KEY` in the environment (see `.env.example`)
- The verification link is sent from the Resend domain configured in the account. The address can be updated in `src/app/core/email.py` (`from` field). The project was onboarded with Resend’s Cloudflare instructions, so the custom domain is already validated there
- New user signup sends the Resend HTML plus a verify link to `/users/verify/{token}`. Signup does not log in; the UI prompts users to check email and then log in after verifying
- [This](https://resend.com/docs/knowledge-base/cloudflare) documentation is incredibly helpful and exactly what you need
