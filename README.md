# ccost

What your [Claude Code](https://claude.com/claude-code) usage would have cost at public API prices.

It reads the session transcripts Claude Code keeps locally, counts each API response once, and prices every token type at its own rate. Single Python file, standard library only, nothing leaves your machine.

```
 ccost    Today   7 days   30 days   All time                               $42.10
                                                      Nov 17 – Nov 23 · 412 requests

 Models                                  Where the money goes
 opus-5-5     301   $27.40 ███████████   cache writes   $18.20  43% ███████████
 fable-5-2     96   $14.10 █████▋        cache reads    $11.30  27% ██████▊
 haiku-5-5     15    $0.60 ▎             output         $12.58  30% ███████▋
                                         input           $0.02   0%

 Daily  ■ opus-5-5  ■ fable-5-2          Top projects
   Fri 11-20 ███████        $8.40        ~/code/webapp       $21.75 ██████████████
   Sat 11-21                $0.00        ~/code/cli-tool     $12.05 ███████▊
 › Sun 11-22 █████████████ $15.20        ~/notes              $8.30 █████▍
   Mon 11-23 █████          $6.10

 ←/→ period   ↑/↓ day   enter sessions   f tokens   q quit
```

## Install

Requires Python 3.9+ on Linux or macOS.

```sh
curl -fsSL https://raw.githubusercontent.com/Haptein/ccost/main/install.sh | sh
```

Or from a clone, which links to it so `git pull` updates the tool:

```sh
git clone https://github.com/Haptein/ccost && ./ccost/install.sh
```

The installer puts `ccost` in `~/.local/bin` and adds a session-end hook to Claude Code's `settings.json` (see [Keeping history](#keeping-history)); the previous settings are saved next to it as `settings.json.bak-ccost`. Use `--no-hook` to skip the hook and `--uninstall` to remove both.

## Usage

```sh
ccost              # interactive view
ccost --print      # static report (also what you get when piping)
ccost --session    # only the current session (latest transcript for $PWD)
ccost --sync       # update the ledger and exit (for the hook below)
```

Static report options: `--full` adds token columns, `--days N` sets the daily chart length, `--no-color`.

### Keys

| Key | Action |
|---|---|
| `←` `→` / Tab | Cycle period: Today, 7 days, 30 days, All time |
| `↑` `↓` / PgUp PgDn / `g` `G` | Move through the daily chart |
| Enter | Show the selected day's sessions, most expensive first (Enter or Esc to go back) |
| `t` | Swap the cost split for token columns |
| `r` | Refresh with the latest usage |
| `q` | Quit |

## Keeping history

Claude Code deletes old transcripts after a while, so `ccost` keeps its own ledger in `~/.local/share/ccost/` (or `$XDG_DATA_HOME/ccost/`): one line per API response with its token counts, project and session. Every run adds what is new and reports from the ledger, so history stays after the transcripts are gone. Token counts are stored rather than dollars, so a price-table update reprices everything.

To keep the ledger current without running `ccost` yourself, the installer adds a session-end hook to `~/.claude/settings.json`. To add it by hand:

```json
{
  "hooks": {
    "SessionEnd": [
      { "hooks": [{ "type": "command", "command": "~/.local/bin/ccost --sync >/dev/null 2>&1 || true" }] }
    ]
  }
}
```

`ccost --sync` only reads what was appended since the last run, so it takes a fraction of a second. The ledger holds project paths and session titles; it stays on your machine.

## Plan limits (optional)

```sh
ccost --limits on
```

Shows the same limits as `/usage` (the 5-hour session, the weekly limit and any per-model weekly limit, such as Fable's) with how much is used and when each resets. ccost reads them from the endpoint `/usage` uses, with the sign-in token Claude Code stores: `~/.claude/.credentials.json` on Linux, the Keychain on macOS.

- **Off by default**, because it reads that token. `ccost --limits off` turns it off again.
- **Never refreshes the token**, so it can't interfere with Claude Code's sign-in. While the token is expired, ccost keeps showing the last values with their age; opening Claude Code renews it.
- **Updated** when you open ccost and on `r`, at most once a minute. The session-end hook doesn't fetch them.
- The endpoint is internal to Claude Code and may change without notice.

## How it counts

- **Source:** `~/.claude/projects/**/*.jsonl` (or `$CLAUDE_CONFIG_DIR/projects`), subagent transcripts included.
- **One response, counted once:** Claude Code writes one transcript line per content block (thinking, text, each tool call), and every line repeats the usage of the whole response. Resumed sessions also copy earlier lines. Responses are de-duplicated by message ID, so totals are lower than a naive sum of every line.
- **Priced per token type:** input, output, cache reads, and cache writes split into 5-minute and 1-hour where the transcript records it. Fast mode, Haiku 5.5's long-prompt rate and web searches are applied.
- **Periods** are calendar days in local time.

## Limits

- Prices are a table at the top of the script (first-party API list prices as of November 2026). Update it when prices change; models missing from the table are flagged as unpriced rather than skipped.
- Only what your local transcripts held when the ledger last synced is counted. Sessions deleted before a sync and usage on other machines are not included.
- It is an estimate of API-equivalent cost, not a bill.

## License

[MIT](LICENSE)
