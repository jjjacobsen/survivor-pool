import resend

from .config import RESEND_API_KEY

resend.api_key = RESEND_API_KEY


def send_verification_email(recipient, verification_url):
    subject = "Verify your Survivor Pool account"
    html = f"""
    <div style="background:#f3f4f6;padding:32px;">
      <div
        style="
          max-width:560px;
          margin:0 auto;
          background:#ffffff;
          border:1px solid #e5e7eb;
          border-radius:12px;
          padding:28px;
          font-family:Arial,sans-serif;
          color:#0f172a;
        "
      >
        <div style="font-size:20px;font-weight:700;margin-bottom:12px;">
          Confirm your email
        </div>
        <p style="margin:0 0 12px 0;line-height:1.5;">
          Thanks for joining Survivor Pool. Please confirm your email to secure
          your account and start building your pools.
        </p>
        <a
          href="{verification_url}"
          style="
            display:inline-block;
            margin:8px 0 16px 0;
            padding:12px 18px;
            background:#0ea5e9;
            color:#ffffff;
            text-decoration:none;
            border-radius:8px;
            font-weight:600;
          "
        >
          Verify email
        </a>
        <p style="margin:0 0 8px 0;line-height:1.4;">
          If the button does not work, copy and paste this link:
        </p>
        <p style="margin:0 0 4px 0;word-break:break-all;">
          <a href="{verification_url}" style="color:#0ea5e9;text-decoration:none;">
            {verification_url}
          </a>
        </p>
        <p style="margin:12px 0 0 0;font-size:12px;color:#6b7280;">
          If you did not request this, you can safely ignore this email.
        </p>
      </div>
      <p
        style="
          text-align:center;
          margin:12px 0 0 0;
          font-size:12px;
          color:#94a3b8;
          font-family:Arial,sans-serif;
        "
      >
        Sent by Survivor Pool
      </p>
    </div>
    """
    text = (
        "Thanks for joining Survivor Pool. Confirm your email to secure your "
        f"account: {verification_url}"
    )
    resend.Emails.send(
        {
            "from": "no-reply@auth.survivorpoolapp.com",
            "to": recipient,
            "subject": subject,
            "html": html,
            "text": text,
        }
    )
