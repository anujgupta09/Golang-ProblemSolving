# ngrok Account Setup

Quick reference to get the domain and authtoken used to tunnel Jenkins for the
GitHub webhook (see [../../README.md](../../README.md)).

## Create the account and get your Dev Domain + authtoken

1. Sign up free at [ngrok.com](https://ngrok.com) — account/config only, no host install.
2. Every free account is automatically given one permanent "Dev Domain" that
   never changes — stable enough for our webhook URL (reserving a *custom-named*
   domain requires a paid plan, but isn't needed here). Note it down
   (`<your-dev-domain>.ngrok-free.dev`).
3. Grab your authtoken from the ngrok dashboard. Keep it private: put it only in your
   `.env` (`NGROK_AUTHTOKEN`, with the domain in `NGROK_DOMAIN`), which stays outside git; never share it in chat.
