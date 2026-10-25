# Giovani Enterprises website — Netlify + Supabase deployment

## Folder contents
- `index.html` — the website
- `netlify.toml` — Netlify build settings
- `netlify/functions/` — server functions (run on Netlify, never in the browser)
  - `claude-proxy.js` — AI chatbot, design brief, valuation, analysis
  - `design-image.js` — concept sketches (architecture, interior, landscape)
  - `verify-access.js` — paid-plan check (Supabase, or ACCESS_LIST fallback)
  - `enquiry.js` — saves enquiries, emails the firm, auto-acknowledges the client
  - `qs-estimate.js` — construction cost estimate (KES 60,000/m² base, East Africa conversion, ML model)
- `netlify/lib/` — shared code: Supabase client, image providers with fallback, email
- `supabase/schema.sql` — database tables and private sketch storage
- `test/` — `npm test` checks everything without needing live services

## 1. Supabase setup
1. Create a project at supabase.com.
2. Open **SQL Editor**, paste `supabase/schema.sql`, and click **Run**.
3. Open **Project Settings → API** and copy the **Project URL** and the **service_role** key.
4. Add them to Netlify as `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.

The service_role key bypasses row security. It must only ever be set in Netlify, never placed in `index.html`.

**Adding a paid client:** Supabase → Table Editor → `subscribers` → Insert row. Enter the email in lowercase and set `tier` to `Professional` or `Enterprise`. Set `active` to false to cancel access.

## 2. Image generation (use any one, or all three for automatic fallback)
| Variable | Purpose |
|---|---|
| `OPENAI_API_KEY` | OpenAI images. Optional model: `OPENAI_IMAGE_MODEL` (default `gpt-image-1`) |
| `STABILITY_API_KEY` | Stability AI. Optional endpoint: `STABILITY_ENDPOINT` |
| `REPLICATE_API_TOKEN` | Replicate. Optional model: `REPLICATE_MODEL`, e.g. `owner/model-name` |
| `IMAGE_PROVIDER_ORDER` | Order to try providers (default `openai,stability,replicate`) |
| `IMAGE_DAILY_LIMIT` | Maximum sketches per day (default 50) |
| `IMAGE_TIMEOUT_MS` | Per-provider timeout (default 20000) |

Providers without a key are skipped. If one fails, the next is tried automatically.

## 3. East Africa cost conversion
`KES 60,000/m²` is the Kenya base rate. Other countries are set with `EA_COST_INDEX_JSON`:

```
{"UG":{"index":0.95,"fx":28.4},"TZ":{"index":1.05,"fx":21.7}}
```
- `index` — construction cost relative to Kenya (Kenya = 1.0)
- `fx` — local currency units per 1 KES

Until you enter real values, every country uses index 1.0 with no exchange rate, so the estimator shows the KES figure and says that the rate is not yet set. Enter the current market values yourself, and check them against your own project data.

## 4. Other variables
| Variable | Purpose |
|---|---|
| `ANTHROPIC_API_KEY` | AI chatbot and text tools |
| `RESEND_API_KEY` | Sends enquiry and design-review emails |
| `MAIL_FROM` | Sender address (domain must be verified in Resend) |
| `MAIL_TO` | Where enquiries go (default info@consultantgiovanienterprises.co.ke) |
| `PROFESSIONAL_REVIEW_EMAIL` | Every generated sketch is sent here for a registered professional's review |
| `ACCESS_LIST` | Paid-plan emails as JSON, used only when Supabase is not configured |
| `QS_TRAINING_JSON` | Project cost records that train the ML cost model (at least 8 needed) |

QS_TRAINING_JSON example: `[{"area_sqm":4200,"floors":6,"grade":"Premium","features":"Smart Building","cost_per_sqm_kes":84000}]`

## 5. Deploy
Connect this folder to a GitHub repository and import it into Netlify (Add new site → Import an existing project). Every push then redeploys with the functions. Alternatively, run `npx netlify-cli deploy --prod` from this folder. Dropping only `index.html` into Netlify will not run the functions.

## 6. Limits to know
- **Function time limits:** Netlify's standard limit for a synchronous function is about 10 seconds on the free plan and up to 26 seconds on paid plans. Image generation can take longer, so confirm your plan's limit and, if needed, upgrade or move image generation to a background function.
- **Sketches are concepts only.** Working drawings must be prepared and signed by a registered professional. In Kenya, architects and quantity surveyors register with BORAQS and engineers with the Engineers Board of Kenya. Confirm current requirements before launch.
- **Rate limits** on the AI proxy are per instance and best-effort. For strict limits, use Supabase counters.

## 7. Test
- `npm test` — 32 checks, all offline.
- After deploy: send a chatbot message, submit a profile request, generate a design concept, run the cost estimator with a country selected, and confirm that a paid email unlocks the AI Enterprise Suite.
