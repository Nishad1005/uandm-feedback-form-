# U&M Designs — Customer Feedback: going live

Two pages, one database, zero monthly cost at this volume.

| What | Where | Address |
|---|---|---|
| Customer form | `index.html` | `https://feedback.uandm.co.in/f/<CODE>` |
| MD dashboard | `admin.html` | `https://feedback.uandm.co.in/admin` |
| Database + login | Supabase (free tier) | — |
| Hosting | Cloudflare Pages (free) — or Vercel | — |

Total setup time: about 30 minutes. Steps 1–4 can be done today on a temporary address; step 5 (the U&M domain) can follow whenever the BigRock login is found.

---

## 1. Create the database (Supabase) — 10 min

1. Go to **supabase.com** → Sign up with the DBBS email → **New project**.
   - Name: `um-feedback`
   - Database password: generate one and save it in your password manager (you rarely need it again).
   - Region: **Mumbai (ap-south-1)**.
2. Wait ~2 minutes for the project to provision.
3. Left menu → **SQL Editor** → **New query** → paste the whole of `supabase/schema.sql` → **Run**.
   You should see "Success. No rows returned".
4. Left menu → **Project Settings** → **API**. Copy two values:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon public** key (long string starting `eyJ…`)
5. Open `config.js` in this folder and paste them in:
   ```js
   SUPABASE_URL: "https://abcdefgh.supabase.co",
   SUPABASE_ANON_KEY: "eyJ…",
   ```
   Leave `SITE_URL` for now — you'll set it in step 3.

> The anon key is designed to be public. The database rules in `schema.sql` are what protect the data: an anonymous visitor can only fetch one link by its exact code and submit one response against it. Reading anything requires a login.

## 2. Create the MD's login — 2 min

Supabase → **Authentication** → **Users** → **Add user** → **Create new user**.
- Email: the MD's email
- Password: set a strong one and share it with him privately (he can't self-register; that's deliberate)
- Tick **Auto Confirm User**

Repeat for anyone else who should see the dashboard. Nobody else can log in.

Optional but recommended: **Authentication → Providers → Email → turn OFF "Enable email signups"** so no one can create an account from outside.

## 3. Put the site online (Cloudflare Pages) — 10 min

1. Go to **pages.cloudflare.com** → sign up with the DBBS email → **Create a project** → **Upload assets** (direct upload, no Git needed).
2. Project name: `um-feedback` → this gives you `https://um-feedback.pages.dev`.
3. Before uploading, set `SITE_URL` in `config.js` to that address, e.g. `"https://um-feedback.pages.dev"` (no trailing slash). This is what the generated links will start with.
4. Drag the **whole folder** in (every file here, including `_redirects`, `logo.png`, `app.css`, `questionnaire.js`, `config.js`, `index.html`, `admin.html`). → **Deploy site**.
5. Open `https://um-feedback.pages.dev/admin` → sign in with the MD's login → **Send questionnaire** → create a test customer and a test link → click **Preview** → fill it in → go back and check **By customer**.

If you prefer Vercel: `vercel.com` → Add New Project → upload the folder. `vercel.json` already contains the same routing rules.

To update the site later (a wording change, say), repeat the upload — it replaces the previous version; the data is in Supabase and untouched.

## 4. Hand over to the MD — 5 min

Send him:
- the dashboard address (`…/admin`) and his login
- this routine:
  1. **Send questionnaire** tab → pick the customer (or add a new one) → enter each contact's name, email and tick the U&M department(s) they deal with → **Generate links**
  2. For each contact click **Email** — his own mail program opens with the link and a note from him already written; he edits if he likes and sends
  3. The status next to each link moves from *Created* → *Opened* → *Answered* on its own
  4. Scores appear under **Overview**, **By customer** and **Comparison** as responses arrive; **Export CSV** gives the raw data for Excel

## 5. Move to feedback.uandm.co.in — 5 min once you have DNS access

`uandm.co.in` is managed through **BigRock** (nameservers dns1–4.bigrock.in). Whoever renews the domain or built the website has the login.

1. Cloudflare Pages → your project → **Custom domains** → **Set up a custom domain** → `feedback.uandm.co.in`. It shows you a CNAME target (looks like `um-feedback.pages.dev`).
2. In BigRock → Manage DNS for `uandm.co.in` → **Add CNAME record**:
   - Host / Name: `feedback`
   - Value / Points to: the target Cloudflare showed
   - TTL: default
3. Wait up to an hour. Cloudflare issues the HTTPS certificate automatically.
4. Change `SITE_URL` in `config.js` to `"https://feedback.uandm.co.in"` and re-upload the folder so new links use the proper address. Links already sent keep working on the old address too.

This adds one record and touches nothing else — the website and email on uandm.co.in are unaffected.

---

## Things worth knowing

- **One link, one response.** Once submitted, the link shows "already received". If someone needs to redo theirs, remove the old link in the dashboard and create a new one.
- **Remove** on a link only works before it is answered; answered links (and their responses) stay for the record.
- **Scores.** A face stores 1–5. Section % = average of that person's answers ÷ 5. Customer overall = average of the sections that have been answered. Company-wide = average across customers. "Doesn't apply" is left out of every average.
- **Traffic-light thresholds** (70 / 55) live in `questionnaire.js` → `band()`; the questions themselves live in the same file. Change, re-upload.
- **Backups.** Supabase keeps daily backups on the free tier for 7 days; **Export CSV** from the dashboard is the simple way to keep your own copy monthly.
- **Cost.** Free tiers cover roughly 50,000 responses and 500 MB of data. Far beyond what this needs.
