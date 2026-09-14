# How to Use Accomplishment Tracker

This is the workflow guide. `README.md` covers what the app is and how it's built; this covers what to actually click, in what order, and why.

## Quick start (30 seconds)

The fastest way to get your first entry in:

1. Look for the small pencil icon in your menu bar (top of the screen, near the clock).
2. Click it. A tiny popup appears asking for a title and a note — that's it, nothing else.
3. Type what you just did (e.g. "Fixed the printer VLAN issue for the 3rd floor") and hit **Save**.

That's a real accomplishment record now, sitting under the "Other" category, waiting for you to come back and flesh it out later. No pressure to fill in six fields right after you did the work — that's the whole point of Quick Capture.

## Two ways to capture

**Menu bar Quick Capture** — for the moment right after something happens. One click, a title, maybe a note, done. Use this by default. If you want to keep going immediately, click **Save & Open** instead of **Save** and it drops you straight into the full editor for that entry.

**New Accomplishment (⌘N, or the + button)** — for when you already have time and want to build a complete, review-ready record from scratch: full context, action, outcome, impact, and metrics in one sitting.

Neither is "more correct" than the other. Quick Capture now + polish later is the intended normal path — most of what makes an entry actually useful for a review (metrics, evidence files, AI analysis) can be added at any time, not just at creation.

## The Evidence Framework

When you open an entry in the full editor, you'll see six fields. They map to what a manager or a review committee actually wants to know:

| Field | What goes here |
|---|---|
| **1. Situation / Context** | What problem, request, outage, or opportunity existed before you acted? |
| **2. What I Did** | Your specific actions — decisions, troubleshooting, coordination, implementation. |
| **3. Outcome** | What changed as a direct result? What got fixed, shipped, prevented, or improved? |
| **4. Organizational Impact** | Why did this matter beyond you? Reliability, security, cost, risk, user experience. |
| **5. Metrics** | Anything countable: users affected, hours saved, incidents avoided, dollars saved. |
| **6. Supporting Evidence Notes** | Ticket numbers, project names, thread references — anything that lets someone verify this later. |

None of these are enforced as mandatory — the app will never block you from saving an incomplete entry. But a record with only a title is a reminder to yourself; a record with all six is something you can actually hand to a reviewer.

**Tags** and **Stakeholders** (bottom of the editor) are just for search and filtering later — comma-separated, informal, no wrong answers.

## Attaching evidence files

Click **Attach Files** in the editor to pull in screenshots, PDFs, exported tickets, or change records. Files are copied into the app's local storage — your originals aren't touched or moved. There's no size limit on attaching, but see the export section below for how large attachments are handled when you generate a review packet.

## Using the on-device AI features

Everything AI-related here runs locally via Apple Intelligence — nothing leaves your Mac (the app has no network access at all, enforced by macOS, not just a policy). Every AI button needs Apple Intelligence turned on in System Settings and the on-device model downloaded; if a button is greyed out, that's why — hover it or check **Settings** for the exact reason.

- **Analyze Human Value** (in the entry editor): explains where your judgment, accountability, or hands-on work added value beyond what AI alone could have done. Needs at least a few sentences of context/action/outcome filled in first — it won't run on an empty entry.
- **Infer Scope & Career Signal**: compares this entry against your **Role Baseline** (set once in Settings → Role Baseline) and classifies it as Core Role or Other/Scope Drift, with reasoning. This is how the app builds the "am I doing more than my job description says" case over time.
- **Analyze Attached Evidence**: reads the text out of your attached files (OCR for images, text extraction for PDFs/docs) and reports what they actually corroborate — it's deliberately skeptical, and will tell you when a file doesn't prove what you think it proves.
- **Build Professional Intelligence**: the most thorough pass — scores claim strength (0–100), assigns a work level (Routine through Strategic/Leadership), and includes a "Challenge My Case" section that argues against your own entry. This is meant to stress-test a claim before you rely on it, not to flatter you.

Run these whenever it's convenient — right after writing the entry, or in a batch during your weekly review pass.

## Automatic capture paths

You don't have to type every entry by hand:

- **Evidence Inbox**: Settings → Reveal Evidence Inbox opens a folder in Finder. Drop screenshots, PDFs, text notes, Markdown, logs, or structured JSON in there, and the app turns each one into a draft entry the next time it's active (or on demand via **Scan Evidence Inbox Now**). Processed files move to a `Processed` subfolder so you know what's been picked up.
- **Apple Mail integration** (optional, off by default): Settings → Apple Mail Integration → turn it on, pick one dedicated mailbox, and the app will read new messages there and turn them into draft accomplishment entries. It only reads that one mailbox and remembers what it's already imported. Turn on "Automatically run local Apple Intelligence on imported mail" if you want each import auto-enriched.
- **Request Intelligence** (experimental, separate from evidence): a second, separate mailbox where incoming *work requests* land. The app can digest each one, pull up relevant prior accomplishments, and draft a response for you to review — useful for a shared IT-request inbox, distinct from your evidence trail.
- **`accomplishmenttracker://capture` URL scheme**: for scripting/Shortcuts automation. Anything captured this way is automatically tagged `source:external-url,needs-review` and flagged as unverified in the notes — by design, since this endpoint is reachable by any app or webpage on your Mac, not just ones you trust. Review these before treating them as real evidence.

## Reading the Professional Insights dashboard

Sidebar → **Professional Insights**. A few numbers worth knowing how to read:

- **Evidence Health** is a documentation-quality score (0–100) — it measures how well-supported your records are, not your performance as an employee. It's a blend of average claim strength, evidence coverage, and how much Professional Intelligence analysis you've run.
- **Scope Drift** compares your "Expected Other/Adjacent Work %" (set in Settings) against what your actual classified entries show. A gap here is the concrete evidence for a "my role has grown" conversation.
- **Claim Strength** bands show how many of your entries would hold up under scrutiny versus how many are thin.

## Exporting

Export menu (toolbar, top right):

- **Export \<Year\> Review Packet…** — a self-contained HTML file with every entry for the year, evidence images/PDFs embedded inline. This is what you hand to a reviewer or print. If your attached evidence for the year is large (>150 MB), the app warns you before exporting; any single file over 20 MB is referenced rather than embedded, so the packet doesn't balloon to an unopenable size.
- **Generate AI Brag Document…** — a shorter, narrative summary written by the on-device model, meant to be skimmed in two minutes before a review or 1:1.
- **Generate Professional Value Model…** — the deepest longitudinal analysis: role reality vs. role description, skill trajectory, recurring patterns, and weaknesses in your own case. Best generated right before a formal review cycle, not weekly.

All three are AI *inference* over your records, not a substitute for them — the exports themselves say so. Skim before you send anything external.

## A workflow that actually sticks

- **In the moment**: menu bar Quick Capture. Ten seconds, no excuses.
- **Weekly**: open the app, look at whatever landed in "Other" category from Quick Capture / Mail / Evidence Inbox, flesh out the ones worth keeping, attach evidence, run AI analysis.
- **Before a review**: run Professional Intelligence on anything you plan to cite, then generate the Review Packet or Brag Document.

## Settings reference

| Setting | What it controls |
|---|---|
| Role Baseline | The plain-language description of your "official" job, used for all Scope Drift comparisons. |
| Expected Other/Adjacent Work % | Your own estimate of how much "extra" work is normal, for comparison against observed drift. |
| Show quick-capture icon in the menu bar | Toggles the menu bar popover on/off. |
| Scan Evidence Inbox when active | Auto-imports from the Evidence Inbox folder whenever you switch back to the app. |
| Apple Mail Integration | Mailbox selection, scan interval, and whether imports auto-run AI analysis. |
| Request Intelligence | Separate mailbox + auto-analyze toggle for incoming work requests. |

## Troubleshooting

- **AI buttons are greyed out**: Apple Intelligence isn't enabled, your Mac isn't eligible, or the on-device model is still downloading. Check System Settings → Apple Intelligence & Siri.
- **Apple Mail button asks for permission**: the first time you use Mail integration, macOS will prompt for Automation access. If you decline by accident, re-enable it in System Settings → Privacy & Security → Automation.
- **An entry has a "needs-review" tag you didn't expect**: it was captured through the external URL scheme, not typed by you — verify before trusting it as evidence.
