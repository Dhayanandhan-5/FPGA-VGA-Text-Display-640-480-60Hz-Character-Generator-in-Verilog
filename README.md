# FPGA-VGA-Text-Display-640-480-60Hz-Character-Generator-in-Verilog

# FPGA VGA Text Display (Verilog)

A from-scratch **VGA controller** in Verilog that generates a **640×480 @ 60 Hz** signal and draws large bitmap text on a monitor. It uses no IP cores and no frame buffer. Every pixel is computed on the fly from the current beam position.

Target board: **Digilent Arty S7** (100 MHz clock).

```
100 MHz clk ──► /4 pixel tick ──► H counter / V counter ──► HSYNC, VSYNC
                                        │
                                        └──► font ROM lookup ──► pixel bit ──► GREEN
```

## Features

- Standard 640×480 @ 60 Hz VGA timing (800×525 total, ~25 MHz pixel rate)
- Pixel clock made by a clock-enable tick from the 100 MHz clock, so the design stays in one clock domain
- Combinational character ROM (`case` statement) holding 8×8 glyphs
- Glyphs scaled 4× to 32×32 pixel cells
- Text shown in green, and the design is easy to extend to R/G/B
- About 100 lines of Verilog, with no memory and no IP

## Repository Structure

| File | Description |
|------|-------------|
| `top.v` | Entire design: pixel tick, sync generator, font ROM, colour output |
| `constraints.xdc` | Pin constraints for Arty S7 |

## Pin Mapping

| Signal | Pin | Direction | Description |
|--------|-----|-----------|-------------|
| `clk` | R2 | in | 100 MHz clock |
| `reset` | H14 | in | Active-high reset |
| `red` | U15 | out | Red (1-bit) |
| `green` | V16 | out | Green (1-bit) |
| `blue` | U17 | out | Blue (1-bit) |
| `hsync` | U16 | out | Horizontal sync |
| `vsync` | P13 | out | Vertical sync |

> **Wiring:** VGA colour inputs expect 0 to 0.7 V into 75 Ω, but the FPGA outputs 3.3 V. Put a series resistor of about **270 Ω** on each colour line (R, G, B) before the VGA connector. HSYNC and VSYNC can go straight to the connector. Always connect GND.

---

## How VGA Works

VGA is an analog video standard from 1987 and is still supported by most monitors. There is **no frame buffer or data bus**. The monitor just follows a signal in real time.

### The core idea: a beam scanning the screen

Picture an invisible beam that sweeps the screen **left to right, top to bottom**, one pixel at a time. The monitor needs only 5 signals:

| Signal | Purpose |
|--------|---------|
| `R`, `G`, `B` | Analog colour brightness for the pixel being drawn right now (0 to 0.7 V) |
| `HSYNC` | Pulse that says "end of line, go back to the left edge" |
| `VSYNC` | Pulse that says "end of frame, go back to the top" |

The FPGA keeps two counters (`h_c` for the horizontal position and `v_c` for the vertical position) that mirror where the beam is. At each position, the FPGA outputs the colour for that exact pixel, so the picture is **generated live**.

### The visible area is only part of the timing

Each line and frame includes blank time (the "porches" and sync pulse) that originally gave CRT beams time to retrace. Monitors still expect this timing.

**Horizontal (one line = 800 pixel clocks):**

```
|<------ 640 visible ------>|<-16->|<--96-->|<--48-->|
|   Active video            | Front| HSYNC  | Back   |
|                           | porch| (low)  | porch  |
0                          639    655      751      799
```

**Vertical (one frame = 525 lines):**

```
|<------ 480 visible ------>|<-10->|<-2->|<--33-->|
|   Active video            | Front|VSYNC| Back   |
|                           | porch|(low)| porch  |
0                          479    489   491      524
```

### Timing numbers (640×480 @ 60 Hz)

| Parameter | Horizontal | Vertical |
|-----------|-----------:|---------:|
| Visible area | 640 px | 480 lines |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| **Total** | **800** | **525** |
| Sync polarity | negative | negative |

- Pixel clock needed: 800 × 525 × 60 ≈ **25.175 MHz**
- This design uses 100 MHz ÷ 4 = **25 MHz**, about 0.7% low, which monitors accept
- Line rate: 25 MHz / 800 = **31.25 kHz**
- Frame rate: 31.25 kHz / 525 ≈ **59.5 Hz**

Outside the visible area the colour outputs **must be black (0)**. The monitor uses that time to calibrate its black level, and the `video_on` signal in the code handles this.

---

## How This Design Works

### 1. Pixel tick (`p_clk`)
A counter divides 100 MHz by 4 and produces a **one-cycle enable pulse** every 4 clocks (25 MHz rate). It is deliberately not a real divided clock. All the logic runs on `clk` and only advances when `p_clk` is high, which avoids clock-domain problems and gives cleaner timing closure.

### 2. Sync generator
On each `p_clk` tick:
- `h_c` counts 0 to 799, then wraps and increments `v_c`
- `v_c` counts 0 to 524, then wraps
- `hsync` goes low for `h_c` 655 to 750 (96 pixels)
- `vsync` goes low for `v_c` 489 to 490 (2 lines)

`video_on = (h_c < 640) && (v_c < 480)` marks the visible region.

### 3. Character generator (font ROM)
Each character is an **8×8 bitmap**, where each byte is one row of 8 pixels. For example, the letter `A`:

```
00111100   ..####..
01100110   .##..##.
01100110   .##..##.
01111110   .######.
01100110   .##..##.
01100110   .##..##.
01100110   .##..##.
01100110   .##..##.
```

The design scales it **4×**, so each glyph becomes a 32×32 pixel cell. That is done purely by choosing which counter bits to use:

| Signal | Bits | Meaning |
|--------|------|---------|
| `h = h_c[9:5]` | divide x by 32 | Character column (0 to 19) |
| `v = v_c[4:2]` | (y mod 32) / 4 | Row inside the glyph (0 to 7) |
| `h_c[4:2]` | (x mod 32) / 4 | Bit inside the row (0 to 7) |

The ROM address is `{v, h}`. The output byte is `font`, and the pixel is `font[7 - h_c[4:2]]`. That bit drives `green` while `video_on` is high.

> The `case` statement synthesizes into plain LUT logic, so no BRAM is used.

### 4. Current output
Characters sit in columns 0 to 3 and spell **`DhAY`**. The vertical position uses only `v_c[4:2]` and ignores `v_c[9:5]`, so the text **repeats down the left side every 32 lines** (15 rows). This is a known quirk, and the next section shows how to fix it.

## Usage

1. Open Vivado and create a project for the Arty S7 (XC7S50).
2. Add `top.v` and `constraints.xdc`.
3. Generate the bitstream and program the board.
4. Wire the VGA connector, with 270 Ω resistors on R, G and B.
5. Plug in a monitor. Press/release **reset** if needed.

## Ideas for Improvement

- Use `v_c[9:5]` in the address so text appears on only one row
- Replace the `case` ROM with a proper character ROM plus a text RAM, so you can type a full screen of text
- Add full colour using more bits per channel and a resistor-ladder DAC or a Pmod VGA
- Add a moving or blinking cursor, or animated colours
- Move to 800×600 or 1024×768, which needs a higher pixel clock from an MMCM/PLL
- Build a test pattern generator (colour bars) using the same counters

## Requirements

- Xilinx Vivado
- Arty S7 board (or any board with a 100 MHz clock and 3.3 V I/O)
- VGA monitor and connector breakout, plus 3 resistors of about 270 Ω

- 

## License

MIT
