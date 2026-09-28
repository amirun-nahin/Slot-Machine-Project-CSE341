# Terminal Casino & Slot Machine

> A console-based casino simulation written in 8086 assembly. Buy tokens, spin a slot machine, borrow from a loan shark, track your stats, and cash out with a final receipt.

## Overview

This project is a text-mode financial and gaming simulation for the Intel 8086 microprocessor. It manages a small virtual economy in which the player converts cash into tokens, gambles on a three-reel slot machine, can take out debt to keep playing, and eventually cashes out. Everything runs in the console using DOS interrupts, with no external libraries.

The project was built to practice core 8086 programming: arithmetic with `MUL`/`DIV`, stack usage, procedures, macros, conditional jumps, loops, and BIOS/DOS I/O.

## Features

| # | Feature | Description |
|---|---------|-------------|
| 1 | **Buy Tokens Kiosk** | Converts cash into tokens at 5 cash = 1 token, using division. Rejects amounts that exceed the player's cash or are not a multiple of 5. |
| 2 | **Manual Spin** | The player bets tokens, three pseudo-random symbols are generated, and a payout is added if all three match. |
| 3 | **Auto-Spin (5x Mode)** | Places the same bet and spins exactly five times in a row. Stops early if the player runs out of tokens. |
| 4 | **Loan Shark (Debt System)** | Lends 50 cash and increases a tracked debt variable so the player can keep playing after going broke. |
| 5 | **Statistics Dashboard** | Shows total games played, wins, losses, and current debt on demand. |
| 6 | **Cash Out & Exit** | Converts remaining tokens back to cash, settles outstanding debt from the balance, and prints a final receipt before exiting. |

## How the Game Works

- **Starting state:** 100 cash, 0 tokens, 0 debt.
- **Exchange rate:** 5 cash = 1 token (both when buying tokens and when cashing out).
- **Reels:** three reels, each showing one of three symbols: `A`, `B`, or `C`.
- **Winning:** a spin wins only when all three symbols match. A win pays **5x the bet** in tokens. Since the bet is deducted before the spin, a win nets 4x the bet and a loss costs 1x the bet. With three equally likely symbols per reel, about 1 spin in 9 is expected to win.
- **Loan shark:** each visit gives 50 cash and adds 50 to the debt counter.
- **Cash out:** all tokens are converted to cash. If the debt is greater than the cash, all cash is forfeited. Otherwise the debt is subtracted and the remainder is the final cash.

## Sample Screens

Main menu (the status line above it updates after every action):

```
[Cash: 100] [Tokens: 0] [Debt: 0]

=== TERMINAL SLOT MACHINE ===
1. Buy Tokens (5 Cash = 1 Token)
2. Manual Spin
3. Auto-Spin (5 Spins)
4. Visit Loan Shark (Borrow 50)
5. View Statistics
6. Cash Out & Exit
--------------------------------
Choice:
```

Example spins (symbols vary randomly):

```
[ A | C | B ] -> LOST
[ B | B | B ] -> WIN! Payout: 10
```

Statistics screen:

```
--- PLAYER STATS ---
Games Played: 12
Total Wins:   2
Total Losses: 10
Current Debt: 50
```

Cash out (example):

```
Debt fully repaid.

=== FINAL RECEIPT ===
Tokens cashed out.
Final Cash: 85
```

## Microprocessor Concepts Demonstrated

| Concept | Where it is used |
|---------|------------------|
| DOS interrupt `INT 21h` | Print strings (`AH=09h`), read a key with echo (`AH=01h`), read a key without echo (`AH=07h`), print a character (`AH=02h`), get system time (`AH=2Ch`), exit (`AH=4Ch`) |
| BIOS interrupt `INT 10h` | Clear the screen by resetting video mode 03h |
| `MUL` / `DIV` | Token conversion, payout calculation, random number range, decimal digit extraction |
| Stack (`PUSH` / `POP`) | Saving registers in procedures, collecting digits when printing numbers, preserving the loop counter in auto-spin |
| Procedures (`CALL` / `RET`) | Reusable helpers for input, output, RNG, and spin logic |
| Macros | `print` macro wraps the string-output interrupt |
| Conditional jumps and loops | Menu dispatch, input validation, the 5-spin loop, and `LOOP` for printing digits |
| Pseudo-random generation | 8-bit linear congruential generator mixed with the system clock, reduced with `DIV` |
| Data segment variables | Player state, statistics counters, and message strings |

## Code Structure

**Main program (`main`)** shows the menu, reads a keypress, and jumps to the selected feature.

**Procedures and macros**

| Name | Purpose |
|------|---------|
| `print` (macro) | Prints a `$`-terminated string |
| `do_spin_logic` | Generates three symbols, prints the reels, updates stats, and pays out on a win |
| `get_random` | Returns a value from 0 to (BX - 1) using the clock and an LCG seed |
| `read_number` | Reads a multi-digit number until ENTER, ignoring non-digit keys |
| `print_number` | Prints the value in AX as decimal |
| `print_char` | Prints a single character |
| `print_header` | Prints the `[Cash] [Tokens] [Debt]` status line |
| `clear_screen` | Clears the console |

**Key variables (`.data`)**

| Variable | Meaning |
|----------|---------|
| `cash`, `tokens`, `debt`, `bet` | Player state (`cash` starts at 100) |
| `g_played`, `g_wins`, `g_losses` | Statistics counters |
| `seed`, `sym1`, `sym2`, `sym3` | RNG seed and the three reel results |

## Running the Program

1. Open `341_s10_06.asm` in emu8086.
2. Click **Compile**, then **Emulate**, then **Run**.

### Playing

1. Press `1` and enter an amount of cash that is a multiple of 5 (for example `50`), then press ENTER to buy tokens.
2. Press `2` for a single spin or `3` for five automatic spins, then enter your bet in tokens and press ENTER.
3. Press `4` if you run out of cash and need a loan.
4. Press `5` any time to check your stats.
5. Press `6` to cash out and end the game.

## Known Limitations

- All values are 16-bit, and number input has no overflow check, so very large numbers will wrap around.
- The random generator is a simple 8-bit LCG mixed with the system clock, so it is pseudo-random and not suitable for anything beyond a game.
- Debt is tracked during play and settled from the player's cash at cash-out. Winnings are not reduced by debt while playing.
- If the debt is larger than the player's cash at cash-out, all remaining cash is forfeited.
