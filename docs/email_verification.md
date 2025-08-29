# One-Time Email Verification Implementation Plan

## Overview

Implementing one-time email verification using SendGrid in the FastAPI backend. Users receive a clickable verification link when they create an account.

## 1. Setup SendGrid

### Dependencies

- Add `sendgrid` dependency to backend pyproject.toml
- Configure `SENDGRID_API_KEY` environment variable
- Configure `FROM_EMAIL` environment variable

## 2. Update User Model in main.py

### New User Fields

- Add `email_verified: bool = False` to user creation
- Add `verification_token: str` field for unique verification links

## 3. Update Registration Flow in main.py

### Registration Process

- Generate unique verification token on user creation using `secrets.token_urlsafe(32)`
- Send verification email with clickable link
- Store user as unverified initially
- User receives email with link like: `http://localhost:8000/verify/{token}`

## 4. Add Email Sending Functionality in main.py

### SendGrid Integration

- Import SendGrid client and Mail helper
- Create email sending function
- Send HTML email with verification button/link
- Handle SendGrid API errors

## 5. Add Verification Endpoint in main.py

### New Endpoint

- `GET /verify/{token}` endpoint
- Looks up user by verification token
- Marks user as `email_verified: True` when clicked
- Returns HTML success page or redirects to frontend login

## 6. Update Login Logic in main.py

### Login Requirements

- Check `email_verified` status before allowing login
- Return specific error for unverified users
- Allow login only for verified accounts

## 7. Frontend Updates

### Registration Flow

- Show "verification email sent" message after successful registration
- Provide instructions to check email

### Login Updates

- Handle unverified user login attempts
- Show appropriate error message with resend option if needed

## Implementation Details

### Email Template

Simple HTML email with:

- Welcome message
- Verification button/link
- Instructions

### Environment Variables

```bash
SENDGRID_API_KEY=your_sendgrid_api_key
FROM_EMAIL=noreply@yourapp.com
```

### Verification Flow

1. User registers → account created (unverified)
2. Verification email sent automatically
3. User clicks email link → account verified
4. User can now log in normally
