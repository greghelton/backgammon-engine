# BackgammonEngine

A complete Swift backgammon game engine with a TD(λ) neural network AI, plus a self-play training harness.

## Projects

| Target | Description |
|---|---|
| **BackgammonEngine** | Legal move generation, all backgammon rules, neural network, AI player |
| **BackgammonTrainer** | Self-play training harness — runs 500,000 episodes in under 50 minutes on an M4 MacBook Pro |

## Setup

Set the default developer toolchain:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

## Training the AI Model

```bash
cd /Users/gregh/dev/src/xcode/Backgammon
swift run -c release BackgammonTrainer ~/downloads/models/backgammon_v2.json
```

The trained model file (`.json`) can then be loaded into the [BackgammonApp](https://github.com/greghelton/backgammon-app) SwiftUI iPhone game.
