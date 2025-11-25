import resend

from .config import RESEND_API_KEY

resend.api_key = RESEND_API_KEY


def send_verification_email(recipient, verification_url):
    html = (
        "<p>Congrats on sending your <strong>first email</strong>!</p>"
        f'<p><a href="{verification_url}">Verify email</a></p>'
    )
    resend.Emails.send(
        {
            "from": "no-reply@auth.survivorpoolapp.com",
            "to": recipient,
            "subject": "Hello World",
            "html": html,
        }
    )
