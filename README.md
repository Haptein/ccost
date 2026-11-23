# cc-cost

What your [Claude Code](https://claude.com/claude-code) usage would have cost at public API prices.

It reads the session transcripts Claude Code keeps locally, counts each API response once, and prices every token type at its own rate. Single Python file, standard library only, nothing leaves your machine.

```
 cc-cost    Today   7 days   30 days   All time                               $42.10
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
git clone https://github.com/Haptein/cc-cost
ln -s "$PWD/cc-cost/cc-cost" ~/.local/bin/cc-cost
```

## Usage

```sh
cc-cost              # interactive view
cc-cost --print      # static report (also what you get when piping)
cc-cost --session    # only the current session (latest transcript for $PWD)
```

Static report options: `--full` adds token columns, `--days N` sets the daily chart length, `--no-color`.

### Keys

| Key | Action |
|---|---|
| `←` `→` / Tab | Cycle period: Today, 7 days, 30 days, All time |
| `↑` `↓` / PgUp PgDn / `g` `G` | Move through the daily chart |
| Enter | Show the selected day's sessions, most expensive first (Enter or Esc to go back) |
| `f` | Swap the cost split for token columns |
| `q` | Quit |

## How it counts

- **Source:** `~/.claude/projects/**/*.jsonl` (or `$CLAUDE_CONFIG_DIR/projects`), subagent transcripts included.
- **One response, counted once:** Claude Code writes one transcript line per content block (thinking, text, each tool call), and every line repeats the usage of the whole response. Resumed sessions also copy earlier lines. Responses are de-duplicated by message ID, so totals are lower than a naive sum of every line.
- **Priced per token type:** input, output, cache reads, and cache writes split into 5-minute and 1-hour where the transcript records it. Fast mode, Haiku 5.5's long-prompt rate and web searches are applied.
- **Periods** are calendar days in local time.

## Limits

- Prices are a table at the top of the script (first-party API list prices as of November 2026). Update it when prices change; models missing from the table are flagged as unpriced rather than skipped.
- Only what is in your local transcripts is counted. Deleted sessions and usage on other machines are not included.
- It is an estimate of API-equivalent cost, not a bill.
