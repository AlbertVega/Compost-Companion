# compost_companion

A new Flutter project.

## Web (Google Maps)

The Map screen uses a Google Maps API key.

### Local key via `.env` (optional)

1) Create a local `.env` file (ignored by git):

`cp .env.example .env`

2) Start the web build:

`flutter run -d web-server --dart-define-from-file=.env --web-port=7357`

If you are not using `.env`, this also works:

`flutter run -d web-server --web-port=7357`

Or use the helper script (it uses `.env` only when present):

`./tool/run_web.sh`

Then open `http://127.0.0.1:7357` in Firefox/Edge.

### Important note

On web, the API key is delivered to the browser (it is not a secret). Use HTTP referrer restrictions in Google Cloud Console.
