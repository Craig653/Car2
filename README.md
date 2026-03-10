# No-Brake Valet 🏎️💨

An high-octane arcade valet simulator built in **Godot 4.x**. You are the world's most aggressive valet driver. The catch? Your brakes are failing, your forward momentum is constant, and the parking lot is filled with hazards.

## 🕹️ Gameplay Concept
In **No-Brake Valet**, you never truly stop. Every car enters the lot with a constant forward velocity. You must steer, drift, and manage your "Thermal Brake Meter" to guide each vehicle into its designated spot. 

Points are awarded for speed and precision, but one too many heavy hits will total the car and end your shift.

## 🎮 Controls
The game is optimized for both **Keyboard** and **Controller**:

| Action | Keyboard | Controller |
| :--- | :--- | :--- |
| **Steer** | `A` / `D` | `Left Analog Stick` |
| **Brake** | `Space` | `Left Trigger (L2)` |
| **Drift Swivel** | `Left Shift` | `Button B / Circle` |
| **Summon Next Car** | `Left Shift` | `Button B / Circle` |
| **Return to Menu** | `Escape` | `Start Button` |

### The "Drift Swivel" Mechanic
Hold **Shift** or **Button B** to slam the brakes and swivel. This **doubles your steering speed**, allowing you to whip the car around tight corners, but it drains your brake power significantly faster.

## 🚗 The Car Lineup
Every car handles differently. Mastery of the fleet is required to complete the Mega Lot challenge:

- **Standard (Blue):** Balanced handling and braking.
- **Sports Car (Dark Red):** High speed, razor-sharp steering, but fragile brakes.
- **Limousine (Black):** Extremely long wheelbase. Hard to turn, but possesses massive stopping power.
- **Old Beater (Brown):** Randomly veers off-course and the brakes occasionally "slip" (fail for a fraction of a second).
- **EV (Teal):** High momentum and silent speed. Slower to accelerate but reaches high top speeds.

## 🌦️ Environmental Challenges
Navigate 7 unique levels, each with its own physics and ambient soundscapes:
- **Standard Lot:** The classic 10-car challenge.
- **Rainy Lot:** Slick asphalt with reduced friction.
- **Snowy Lot:** Extremely low traction. Your car will slide—steer early!
- **Windy Lot:** A powerful crosswind constantly pushes your car to the right.
- **Muddy Lot:** High drag. Acceleration is heavy and top speed is limited.
- **Incline Lot:** Gravity pulls your car downhill. Braking early is mandatory.
- **Lava Lot:** Avoid the glowing hazard zones. Touching lava deals instant condition damage.

## 🛠️ Technical Features
- **Procedural Audio:** All sound effects (Crashes, Tire Squeals, Dings) and the 8-bit Techno Soundtrack are synthesized in real-time using Godot's `AudioStreamGenerator`.
- **Arcade Juice:** Dynamic skidmarks, screen shake on impact, and HDR neon brake glows.
- **Adaptive UI:** Responsive HUD that tracks condition, brake heat, and parking quotas across all resolutions.

---
*Built with passion by Gemini CLI.*
